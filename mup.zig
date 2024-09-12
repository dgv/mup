const std = @import("std");
const httpz = @import("httpz");
const clap = @import("clap");
const htmlAsset = @embedFile("index.html");

const MB = 1 << 20;
const string = []const u8;
var upload_dir: []const u8 = undefined;
var max_size: usize = undefined;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-s, --size <usize>   Maximum upload size in MB.
        \\-p, --port <u16>  Port to run the server on.
        \\-a, --addr <str>  Address to run the server on.
        \\-d, --dir <str>  Upload directory to serve files.
        \\
    );

    var res = try clap.parse(clap.Help, &params, clap.parsers.default, .{
        .allocator = gpa.allocator(),
    });
    defer res.deinit();
    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    max_size = res.args.size orelse 100;
    const port = res.args.port orelse 5000;
    const addr = res.args.addr orelse "0.0.0.0";
    upload_dir = try std.mem.join(gpa.allocator(), "", &.{ res.args.dir orelse "./uploads", "/" });

    _ = std.fs.cwd().statFile(upload_dir) catch |err| switch (err) {
        error.FileNotFound => {
            try std.fs.cwd().makeDir(upload_dir);
            _ = try std.fs.cwd().openDir(upload_dir, .{ .iterate = true });
        },
        else => {
            std.debug.print("unable to open directory '{s}': {s}", .{ upload_dir, @errorName(err) });
            std.process.exit(1);
        },
    };

    var server = try httpz.Server().init(gpa.allocator(), .{
        .address = addr,
        .port = port,
        .request = .{
            .max_body_size = max_size * MB,
            .max_multiform_count = 255,
        },
    });

    var router = server.router();
    router.get("/", index);
    router.get("/uploads", uploads);
    router.get("/uploads/:filename", serve);
    router.post("/upload", upload);
    router.get("/metrics", metrics);
    router.delete("/uploads/:filename", delete);

    std.log.info("listening at http://{s}:{d}/", .{ addr, port });
    try server.listen();
}

fn index(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    var files_list_html = std.ArrayList(string).init(allocator);
    defer files_list_html.deinit();
    const files_list = try getUploads();
    for (files_list) |file| {
        const html = try std.fmt.allocPrint(
            std.heap.page_allocator,
            "<li data-filename=\"{s}\"><a href=\"/uploads/{s}\">{s}</a><div class=\"buttons\"><button title=\"Delete file\" class=\"danger icon\"><span class=\"material-symbols-outlined\">delete</span></button></div></li>",
            .{ file, file, file },
        );
        try files_list_html.append(html);
    }
    const html_files_list = try std.mem.join(std.heap.page_allocator, "", files_list_html.items);
    const size = std.mem.replacementSize(u8, htmlAsset, ".Uploads", html_files_list);
    const output = try std.heap.page_allocator.alloc(u8, size);
    _ = std.mem.replace(u8, htmlAsset, ".Uploads", html_files_list, output);
    res.content_type = .HTML;
    res.body = output;
}

fn serve(req: *httpz.Request, res: *httpz.Response) !void {
    const filename = req.param("filename").?;
    std.log.info("{any} {s} from {any}", .{ req.method, req.url.raw, req.address });
    const filename_path = try std.mem.join(allocator, "", &.{ upload_dir, filename });
    const file = std.fs.cwd().openFile(filename_path, .{ .mode = .read_only }) catch |err| {
        std.log.err("serve err: {any}", .{err});
        res.status = 404;
        res.body = "Not found";
        return;
    };
    res.content_type = httpz.ContentType.forFile(filename);
    const file_buffer = try file.readToEndAlloc(allocator, max_size * MB);
    defer allocator.free(file_buffer);
    try res.writer().writeAll(file_buffer);
}

fn uploads(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    const files_list = try getUploads();
    try res.json(files_list, .{});
}

fn upload(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    const fd = try req.multiFormData();
    for (fd.keys[0..fd.len], fd.values[0..fd.len]) |_, field| {
        const file_name = try std.mem.join(std.heap.page_allocator, "", &.{ upload_dir, try filenameToSlug(field.filename orelse "") });
        const file = try std.fs.cwd().createFile(
            file_name,
            .{ .read = true },
        );

        defer file.close();
        const bytes_written = try file.write(field.value);
        std.log.info("{any} uploaded file:{s} written {any} bytes", .{ req.address, file_name, bytes_written });
    }
    res.status = 200;
}

fn metrics(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    res.content_type = .TEXT;
    return httpz.writeMetrics(res.writer());
}

fn delete(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    const filename = req.param("filename").?;
    const filename_path = try std.mem.join(allocator, "", &.{ upload_dir, filename });
    std.fs.cwd().deleteFile(filename_path) catch |err| {
        std.log.err("delete() err: {any}", .{err});
        res.status = 404;
        res.body = "Not found";
        return;
    };

    res.status = 204;
}

fn filenameToSlug(filename: string) !string {
    const ext = std.fs.path.extension(filename);
    var _filename = try std.ArrayList(u8).initCapacity(std.heap.page_allocator, filename.len);
    for (filename[0 .. filename.len - ext.len], 0..) |f, i| {
        if (std.ascii.isAlphanumeric(f)) {
            try _filename.append(std.ascii.toLower(filename[i]));
        } else {
            try _filename.append('-');
        }
    }
    try _filename.appendSlice(ext);
    return _filename.items;
}

fn getUploads() ![]string {
    var files_list = std.ArrayList(string).init(allocator);
    var dir = try std.fs.cwd().openDir(upload_dir, .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |file| {
        if (file.kind != .file) {
            continue;
        }
        try files_list.append(try allocator.dupe(u8, file.name));
    }
    return files_list.items;
}
