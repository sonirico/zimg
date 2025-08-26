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
    _ = ctx;
    const stdout = std.fs.File.stdout();
    var stdout_writer = stdout.writerStreaming(&.{}).interface;
    try stdout_writer.print("zimg version 0.1.0\n", .{});
    try stdout_writer.flush();
}
