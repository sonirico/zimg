const std = @import("std");
const Writer = std.io.Writer;
const zli = @import("zli");
const logger = @import("../logger.zig");

pub fn register(writer: *Writer, allocator: std.mem.Allocator) !*zli.Command {
    const cmd = try zli.Command.init(writer, allocator, .{
        .name = "crop",
        .description = "Crop image to specified dimensions and position",
    }, run);

    try cmd.addFlag(.{
        .name = "json",
        .description = "Output in JSON format",
        .type = .Bool,
        .default_value = .{ .Bool = false },
    });

    try cmd.addPositionalArg(.{
        .name = "file",
        .description = "Input image file",
        .required = true,
    });

    try cmd.addPositionalArg(.{
        .name = "x",
        .description = "X coordinate of crop area",
        .required = true,
    });

    try cmd.addPositionalArg(.{
        .name = "y",
        .description = "Y coordinate of crop area",
        .required = true,
    });

    try cmd.addPositionalArg(.{
        .name = "width",
        .description = "Width of crop area",
        .required = true,
    });

    try cmd.addPositionalArg(.{
        .name = "height",
        .description = "Height of crop area",
        .required = true,
    });

    return cmd;
}

fn run(ctx: zli.CommandContext) !void {
    const file = ctx.getArg("file") orelse {
        try ctx.command.printHelp();
        return;
    };

    const x_str = ctx.getArg("x") orelse {
        try ctx.command.printHelp();
        return;
    };

    const y_str = ctx.getArg("y") orelse {
        try ctx.command.printHelp();
        return;
    };

    const width_str = ctx.getArg("width") orelse {
        try ctx.command.printHelp();
        return;
    };

    const height_str = ctx.getArg("height") orelse {
        try ctx.command.printHelp();
        return;
    };

    const x = std.fmt.parseInt(i32, x_str, 10) catch {
        logger.err("Invalid x coordinate: {s}", .{x_str});
        return;
    };

    const y = std.fmt.parseInt(i32, y_str, 10) catch {
        logger.err("Invalid y coordinate: {s}", .{y_str});
        return;
    };

    const width = std.fmt.parseInt(u32, width_str, 10) catch {
        logger.err("Invalid width: {s}", .{width_str});
        return;
    };

    const height = std.fmt.parseInt(u32, height_str, 10) catch {
        logger.err("Invalid height: {s}", .{height_str});
        return;
    };

    const json_output = ctx.flag("json", bool);

    if (json_output) {
        try ctx.writer.print("{{\"command\":\"crop\",\"file\":\"{s}\",\"x\":{},\"y\":{},\"width\":{},\"height\":{}}}\n", .{ file, x, y, width, height });
        try ctx.writer.flush();
    } else {
        try ctx.writer.print("Cropping {s} to {}x{} from ({}, {})\n", .{ file, width, height, x, y });
        try ctx.writer.flush();

        // IMPLEMENTATION PLACEHOLDER: Real libvips cropping logic
        // 1. Load image with vips_image_new_from_file()
        // 2. Validate crop bounds against image dimensions
        // 3. Extract region with vips_extract_area()
        // 4. Save cropped image with vips_image_write_to_file()
        // 5. Report success and output file information
    }
}
