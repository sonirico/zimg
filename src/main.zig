// src/main.zig
const std = @import("std");
const fs = std.fs;
const cli = @import("cli.zig");

// Forzar que se incluyan todos los tests
comptime {
    _ = @import("utils.zig");
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const file = fs.File.stdout();
    var writer = file.writerStreaming(&.{}).interface;

    const root = try cli.build(&writer, allocator);
    defer root.deinit();

    try root.execute(.{});

    try writer.flush();
}
