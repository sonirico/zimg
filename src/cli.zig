const std = @import("std");
const zli = @import("zli");

const version = @import("version.zig");
const optimize = @import("cmd/optimize.zig");
const inspect = @import("cmd/inspect.zig");
const crop = @import("cmd/crop.zig");
const scale = @import("cmd/scale.zig");

pub fn build(allocator: std.mem.Allocator) !*zli.Command {
    const root = try zli.Command.init(allocator, .{
        .name = "zimg",
        .description = "High-performance image processing toolkit",
    }, showHelp);

    try root.addCommands(&.{
        try optimize.register(allocator),
        try inspect.register(allocator),
        try crop.register(allocator),
        try scale.register(allocator),
        try version.register(allocator),
    });

    return root;
}

fn showHelp(ctx: zli.CommandContext) !void {
    try ctx.command.printHelp();
}
