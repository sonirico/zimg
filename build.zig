const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add zli dependency
    const zli = b.dependency("zli", .{
        .target = target,
        .optimize = optimize,
    });

    // Main executable
    const exe = b.addExecutable(.{
        .name = "zimg",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add zli module
    exe.root_module.addImport("zli", zli.module("zli"));

    // Link libvips for image processing
    exe.linkSystemLibrary("vips");
    exe.linkSystemLibrary("glib-2.0");
    exe.linkSystemLibrary("gobject-2.0");
    exe.linkSystemLibrary("gio-2.0");
    exe.linkSystemLibrary("gmodule-2.0");
    exe.linkLibC();

    exe.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    exe.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
