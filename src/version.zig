const std = @import("std");
const Writer = std.io.Writer;
const zli = @import("zli");

pub fn register(writer: *Writer, allocator: std.mem.Allocator) !*zli.Command {
    return zli.Command.init(writer, allocator, .{
        .name = "version",
        .shortcut = "v",
        .description = "Show zimg version",
    }, show);
}

fn show(ctx: zli.CommandContext) !void {
    try ctx.writer.print("zimg version 0.1.0\n", .{});
}
