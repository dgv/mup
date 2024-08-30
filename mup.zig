const std = @import("std");
const httpz = @import("httpz");
const clap = @import("clap");
const htmlAsset = @embedFile("index.html");

const MB = 1 << 20;
const string = []const u8;
const upload_dir = "./upload/";

fn filenameToSlug(filename: string) string {
    return filename;
}

fn getUploads(allocator: std.mem.Allocator, uploadFolder: string) ![]string {
    var files_list = std.ArrayList(string).init(allocator);
    defer files_list.deinit();
    var dir = try std.fs.cwd().openDir(uploadFolder, .{ .iterate = true });
    var it = dir.iterate();
    while (try it.next()) |file| {
        if (file.kind != .file) {
            continue;
        }
        try files_list.append(file.name);
    }
    return try allocator.dupe(string, files_list.items);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-s, --size <usize>   Maximum upload size in MB.
        \\-p, --port <u16>  Port to run the server on.
        \\-h, --host <str>  Host to run the server on.
        \\
    );
    var res = try clap.parse(clap.Help, &params, clap.parsers.default, .{
        .allocator = gpa.allocator(),
    });
    defer res.deinit();
    if (res.args.help != 0)
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});

    _ = std.fs.cwd().openDir(upload_dir, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            try std.fs.cwd().makeDir(upload_dir);
            _ = try std.fs.cwd().openDir(upload_dir, .{ .iterate = true });
        },
        else => fatal("unable to open directory '{s}': {s}", .{ upload_dir, @errorName(err) }),
    };
    const max_size = res.args.size orelse 100;
    const port = res.args.port orelse 5000;
    const host = res.args.host orelse "0.0.0.0";
    var server = try httpz.Server().init(gpa.allocator(), .{
        .address = host,
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

    std.log.info("listening at http://{s}:{d}/", .{ host, port });
    try server.listen();
}

fn index(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    //const allocator = std.heap.page_allocator;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const upload_list = try getUploads(allocator, upload_dir);
    var files_list = std.ArrayList(string).init(allocator);
    defer files_list.deinit();
    for (upload_list) |file| {
        const html = try std.fmt.allocPrint(
            allocator,
            "<li><a href=\"/uploads/{s}\">{s}</a></li>",
            .{ file, file },
        );
        try files_list.append(html);
    }
    //try std.mem.join(std.heap.page_allocator, "", files_list.items);
    const html_files_list = try std.mem.join(std.heap.page_allocator, "", files_list.items);
    const size = std.mem.replacementSize(u8, htmlAsset, ".Uploads", html_files_list);
    const output = try std.heap.page_allocator.alloc(u8, size);
    _ = std.mem.replace(u8, htmlAsset, ".Uploads", html_files_list, output);
    res.content_type = .HTML;
    res.body = output;
}

fn serve(req: *httpz.Request, res: *httpz.Response) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
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
    const file_buffer = try file.readToEndAlloc(allocator, 10 * MB);
    defer allocator.free(file_buffer);
    try res.writer().writeAll(file_buffer);
}

fn uploads(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    const upload_list = try getUploads(std.heap.page_allocator, upload_dir);
    try res.json(upload_list, .{});
}

fn upload(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    const fd = try req.multiFormData();
    for (fd.keys[0..fd.len], fd.values[0..fd.len]) |_, field| {
        const file_name = try std.mem.join(std.heap.page_allocator, "", &.{ upload_dir, field.filename orelse "" });
        const file = try std.fs.cwd().createFile(
            file_name,
            .{ .read = true },
        );

        defer file.close();
        const bytes_written = try file.write(field.value);
        std.log.info("{any} uploaded file:{s} written {any} bytes", .{ req.address, file_name, bytes_written });
    }
    res.status = 200;
    res.body = "";
}

fn metrics(req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("{any} {s} from {any} ", .{ req.method, req.url.raw, req.address });
    res.content_type = .TEXT;
    return httpz.writeMetrics(res.writer());
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format ++ "\n", args);
    std.process.exit(1);
}
