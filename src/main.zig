// src/main.zig
const std = @import("std");
const cli = @import("cli.zig");

// Forzar que se incluyan todos los tests
comptime {
    _ = @import("utils.zig");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var root = try cli.build(allocator);
    defer root.deinit();

    try root.execute(.{});
}
