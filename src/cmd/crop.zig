const std = @import("std");
const Writer = std.io.Writer;
const zli = @import("zli");
const logger = @import("../logger.zig");
const vips = @import("../vips.zig");
const utils = @import("../utils.zig");

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

    try cmd.addFlag(.{
        .name = "output",
        .shortcut = "o",
        .description = "Output filename (default: auto-generated)",
        .type = .String,
        .default_value = .{ .String = "" },
    });

    try cmd.addFlag(.{
        .name = "topX",
        .shortcut = "x",
        .description = "X coordinate of crop area (default: 0)",
        .type = .String,
        .default_value = .{ .String = "0" },
    });

    try cmd.addFlag(.{
        .name = "topY",
        .shortcut = "y",
        .description = "Y coordinate of crop area (default: 0)",
        .type = .String,
        .default_value = .{ .String = "0" },
    });

    try cmd.addPositionalArg(.{
        .name = "file",
        .description = "Input image file (optional if reading from stdin)",
        .required = false,
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
    // Initialize libvips
    vips.init() catch |err| {
        logger.err("Failed to initialize libvips: {}", .{err});
        return;
    };
    defer vips.shutdown();

    // Read input image (from file or stdin)
    const result = utils.readImageFromCmd(ctx) orelse return;
    var image = result.image;
    defer image.deinit();

    // Parse coordinates from flags (with defaults of 0)
    const x_str = ctx.flag("topX", []const u8);
    const y_str = ctx.flag("topY", []const u8);
    
    const width_str = ctx.getArg("width") orelse {
        logger.err("Width parameter is required");
        try ctx.command.printHelp();
        return;
    };

    const height_str = ctx.getArg("height") orelse {
        logger.err("Height parameter is required");
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

    // Validate crop boundaries
    const image_width = image.getWidth();
    const image_height = image.getHeight();
    
    if (x < 0 or y < 0) {
        logger.err("Crop coordinates cannot be negative: x={}, y={}", .{x, y});
        return;
    }
    
    if (@as(u32, @intCast(x)) + width > image_width or @as(u32, @intCast(y)) + height > image_height) {
        logger.err("Crop area exceeds image boundaries. Image: {}x{}, Crop: {}x{} at ({}, {})", 
            .{image_width, image_height, width, height, x, y});
        return;
    }

    const json_output = ctx.flag("json", bool);
    const custom_output = ctx.flag("output", []const u8);

    // Perform the crop operation
    var cropped_image = vips.cropImage(&image, x, y, width, height) catch |err| {
        logger.err("Failed to crop image: {}", .{err});
        return;
    };
    defer cropped_image.deinit();

    // Generate output filename  
    var output_buffer: [512]u8 = undefined;
    const output_filename = if (custom_output.len > 0)
        custom_output
    else if (std.mem.eql(u8, result.filename, "<stdin>")) 
        "cropped.jpg" 
    else blk: {
        const extension_start = std.mem.lastIndexOf(u8, result.filename, ".") orelse result.filename.len;
        const base_name = result.filename[0..extension_start];
        const extension = if (extension_start < result.filename.len) result.filename[extension_start..] else ".jpg";
        
        break :blk std.fmt.bufPrint(&output_buffer, "{s}_cropped{s}", .{base_name, extension}) catch "cropped.jpg";
    };

    // Save the cropped image
    vips.saveImage(ctx.allocator, &cropped_image, output_filename) catch |err| {
        logger.err("Failed to save cropped image: {}", .{err});
        return;
    };

    // Output results
    if (json_output) {
        try ctx.writer.print("{{\"command\":\"crop\",\"input\":\"{s}\",\"output\":\"{s}\",\"x\":{},\"y\":{},\"width\":{},\"height\":{}}}\n", 
            .{ result.filename, output_filename, x, y, width, height });
        try ctx.writer.flush();
    } else {
        try ctx.writer.print("Cropped {s} ({}x{}) to {}x{} from ({}, {}) -> {s}\n", 
            .{ result.filename, image_width, image_height, width, height, x, y, output_filename });
        try ctx.writer.flush();
    }
}
