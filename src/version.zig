const std = @import("std");
const zli = @import("zli");

pub fn register(allocator: std.mem.Allocator) !*zli.Command {
    return zli.Command.init(allocator, .{
        .name = "version",
        .shortcut = "v",
        .description = "Show zimg version",
    }, show);
}

fn show(ctx: zli.CommandContext) !void {
    _ = ctx;
    const stdout = std.io.getStdOut().writer();
    try stdout.print("zimg version 0.1.0\n", .{});
}
