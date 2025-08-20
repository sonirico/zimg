const std = @import("std");

fn addPathIfExists(exe: *std.Build.Step.Compile, path: []const u8, is_include: bool) void {
    const stat = std.fs.cwd().statFile(path) catch return;
    if (stat.kind == .directory) {
        if (is_include) {
            exe.addIncludePath(.{ .cwd_relative = path });
        } else {
            exe.addLibraryPath(.{ .cwd_relative = path });
        }
    }
}

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

    // Add include and library paths conditionally
    addPathIfExists(exe, "/usr/local/include", true);
    addPathIfExists(exe, "/usr/local/lib", false);
    addPathIfExists(exe, "/usr/include", true);
    addPathIfExists(exe, "/usr/include/vips", true);
    addPathIfExists(exe, "/usr/include/glib-2.0", true);
    addPathIfExists(exe, "/usr/lib/x86_64-linux-gnu/glib-2.0/include", true);
    addPathIfExists(exe, "/usr/lib/x86_64-linux-gnu", false);
    addPathIfExists(exe, "/usr/lib", false);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
