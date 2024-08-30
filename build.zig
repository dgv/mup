const std = @import("std");

// const TARGETS = [_]std.zig.CrossTarget{
//     //.{ .cpu_arch = .x86_64, .os_tag = .macos },
//     .{ .cpu_arch = .x86_64, .os_tag = .linux },
//     .{ .cpu_arch = .x86, .os_tag = .linux },
//     .{ .cpu_arch = .mips, .os_tag = .linux },
//     .{ .cpu_arch = .mips64, .os_tag = .linux },
//     .{ .cpu_arch = .arm, .os_tag = .linux },
//     .{ .cpu_arch = .aarch64, .os_tag = .linux },
//     //.{ .cpu_arch = .aarch64, .os_tag = .macos },
//      .{ .cpu_arch = .x86, .os_tag = .windows },
//      .{ .cpu_arch = .x86_64, .os_tag = .windows },
//     .{ .cpu_arch = .aarch64, .os_tag = .windows },
// };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(
        .{ .preferred_optimize_mode = .ReleaseSafe },
    );
    // for (TARGETS) |TARGET| {
    //     const target = b.resolveTargetQuery(TARGET);

    //     const bin = b.addExecutable(.{
    //         .name = "mup-", // ++ @tagName(builtin.target.cpu.arch) ++ "-" ++ @tagName(TARGET.os_tag),
    //         .root_source_file = b.path("main.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     });
    //     b.installArtifact(bin);
    // }
    const exe = b.addExecutable(.{
        .name = "mup",
        .root_source_file = b.path("mup.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("httpz", b.dependency("httpz", .{ .target = target, .optimize = optimize }).module("httpz"));
    exe.root_module.addImport("clap", b.dependency("clap", .{ .target = target, .optimize = optimize }).module("clap"));
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
