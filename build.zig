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

    // Add strip option
    const strip = b.option(bool, "strip", "Strip debug symbols") orelse false;

    // Add zli dependency
    const zli = b.dependency("zli", .{
        .target = target,
        .optimize = optimize,
    });

    // Main executable
    const exe = b.addExecutable(.{
        .name = "zimg",
        .root_module= b.addModule("zimg", .{
            .root_source_file = b.path("./src/main.zig"),
            .target = target,
            .optimize = optimize,
            .strip = strip,
        }),
    });

    // Add zli module
    exe.root_module.addImport("zli", zli.module("zli"));

    // Add C defines for cross-compilation compatibility
    exe.root_module.addCMacro("_GNU_SOURCE", "1");
    exe.root_module.addCMacro("_DEFAULT_SOURCE", "1");
    exe.root_module.addCMacro("_POSIX_C_SOURCE", "200809L");
    exe.root_module.addCMacro("_FILE_OFFSET_BITS", "64");
    exe.root_module.addCMacro("_TIME_BITS", "64");

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

    // Add test step that tests all files
    const unit_tests = b.addTest(.{
        .root_module = b.addModule("test", .{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
