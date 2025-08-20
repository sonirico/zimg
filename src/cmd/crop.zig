const std = @import("std");
const zli = @import("zli");

pub fn register(allocator: std.mem.Allocator) !*zli.Command {
    const cmd = try zli.Command.init(allocator, .{
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
        const stderr = std.io.getStdErr().writer();
        try stderr.print("Error: Invalid x coordinate: {s}\n", .{x_str});
        return;
    };

    const y = std.fmt.parseInt(i32, y_str, 10) catch {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("Error: Invalid y coordinate: {s}\n", .{y_str});
        return;
    };

    const width = std.fmt.parseInt(u32, width_str, 10) catch {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("Error: Invalid width: {s}\n", .{width_str});
        return;
    };

    const height = std.fmt.parseInt(u32, height_str, 10) catch {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("Error: Invalid height: {s}\n", .{height_str});
        return;
    };

    const json_output = ctx.flag("json", bool);

    if (json_output) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("{{\"command\":\"crop\",\"file\":\"{s}\",\"x\":{},\"y\":{},\"width\":{},\"height\":{}}}\n", .{ file, x, y, width, height });
    } else {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("Cropping {s} to {}x{} from ({}, {})\n", .{ file, width, height, x, y });

        // IMPLEMENTATION PLACEHOLDER: Real libvips cropping logic
        // 1. Load image with vips_image_new_from_file()
        // 2. Validate crop bounds against image dimensions
        // 3. Extract region with vips_extract_area()
        // 4. Save cropped image with vips_image_write_to_file()
        // 5. Report success and output file information
    }
}
