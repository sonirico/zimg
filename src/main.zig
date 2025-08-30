// src/main.zig
const std = @import("std");
const fs = std.fs;
const cli = @import("cli.zig");
const logger = @import("logger.zig");
// Forzar que se incluyan todos los tests
comptime {
    _ = @import("utils.zig");
}

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const stdout = fs.File.stdout();
    const stderr = fs.File.stderr();

    var outWriter = stdout.writerStreaming(&.{});
    var errWriter = stderr.writerStreaming(&.{});

    logger.init(.debug, &errWriter.interface);
    defer logger.deinit();

    const root = try cli.build(&outWriter.interface, allocator);
    defer root.deinit();

    try root.execute(.{});

    try outWriter.interface.flush();
    try errWriter.interface.flush();
}
