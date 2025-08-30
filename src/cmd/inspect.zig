const std = @import("std");
const Writer = std.io.Writer;
const zli = @import("zli");
const vips = @import("../vips.zig");
const utils = @import("../utils.zig");
const logger = @import("../logger.zig");

const ImageInfo = struct {
    file: []const u8,
    format: []const u8,
    width: u32,
    height: u32,
    channels: u32,
    bit_depth: u8,
    colorspace: []const u8,
    size_bytes: u64,
    has_alpha: bool,
    has_icc_profile: bool,
    total_pixels: u64,
    aspect_ratio: struct {
        width: u32,
        height: u32,
    },
    size_mb: f64,
};

pub fn register(writer: *Writer, allocator: std.mem.Allocator) !*zli.Command {
    const cmd = try zli.Command.init(writer, allocator, .{
        .name = "inspect",
        .description = "Inspect image file properties and metadata",
    }, run);

    try cmd.addFlag(.{
        .name = "json",
        .description = "Output in JSON format",
        .type = .Bool,
        .default_value = .{ .Bool = false },
    });

    try cmd.addPositionalArg(.{
        .name = "file",
        .description = "Input image file (optional if reading from stdin)",
        .required = false,
    });

    return cmd;
}

fn run(ctx: zli.CommandContext) !void {
    const json_output = ctx.flag("json", bool);

    // Initialize libvips
    vips.init() catch |err| {
        logger.err("Failed to initialize libvips: {}", .{err});
        return;
    };
    defer vips.shutdown();

    // Try to read from stdin first
    const stdin_buffer = utils.readStdinBuffer(ctx.allocator) catch null;
    defer if (stdin_buffer) |buf| ctx.allocator.free(buf);

    var image: vips.VipsImage = undefined;
    var filename: []const u8 = undefined;
    var size_bytes: u64 = 0;

    if (stdin_buffer) |buffer| {
        // Load from stdin buffer
        filename = "<stdin>";
        size_bytes = buffer.len;
        image = utils.loadImageFromBuffer(buffer) catch |err| {
            switch (err) {
                error.LoadFailed => logger.err("Cannot load image from stdin", .{}),
                error.OutOfMemory => logger.err("Out of memory", .{}),
                else => logger.err("Failed to load image: {}", .{err}),
            }
            return;
        };
    } else {
        // Load from file argument (now uses buffer internally)
        const file = ctx.getArg("file") orelse {
            logger.err("No input provided. Specify a file or pipe image data to stdin.", .{});
            try ctx.command.printHelp();
            return;
        };
        filename = file;

        // Get file size for metadata
        if (std.fs.cwd().statFile(filename)) |file_stat| {
            size_bytes = file_stat.size;
        } else |err| {
            logger.warn("Cannot get file size: {}", .{err});
            size_bytes = 0;
        }

        image = utils.loadImage(ctx.allocator, file) catch |err| {
            switch (err) {
                error.LoadFailed => logger.err("Cannot load image file '{s}'", .{file}),
                error.OutOfMemory => logger.err("Out of memory", .{}),
                else => logger.err("Failed to load image: {}", .{err}),
            }
            return;
        };
    }
    defer image.deinit();

    // Extract image properties
    const width = image.getWidth();
    const height = image.getHeight();
    const channels = image.getBands();
    const format = image.getFormat();

    // Map VIPS format to bit depth
    const bit_depth: u8 = switch (format) {
        vips.c.VIPS_FORMAT_UCHAR => 8,
        vips.c.VIPS_FORMAT_CHAR => 8,
        vips.c.VIPS_FORMAT_USHORT => 16,
        vips.c.VIPS_FORMAT_SHORT => 16,
        vips.c.VIPS_FORMAT_UINT => 32,
        vips.c.VIPS_FORMAT_INT => 32,
        vips.c.VIPS_FORMAT_FLOAT => 32,
        vips.c.VIPS_FORMAT_DOUBLE => 64,
        else => 8,
    };

    // Determine colorspace using VIPS interpretation
    const colorspace = image.getColorspace();

    // Check for alpha channel
    const has_alpha = channels == 2 or channels == 4;

    // Check for ICC profile using VIPS
    const has_icc_profile = image.hasIccProfile();

    // Detect image format using VIPS loader information
    const format_name = image.getFormatName();

    // Calculate additional info
    const total_pixels = @as(u64, width) * @as(u64, height);
    const gcd = std.math.gcd(width, height);
    const aspect_w = width / gcd;
    const aspect_h = height / gcd;
    const size_mb = @as(f64, @floatFromInt(size_bytes)) / (1024.0 * 1024.0);

    // Create structured data
    const image_info = ImageInfo{
        .file = filename,
        .format = format_name,
        .width = width,
        .height = height,
        .channels = channels,
        .bit_depth = bit_depth,
        .colorspace = colorspace,
        .size_bytes = size_bytes,
        .has_alpha = has_alpha,
        .has_icc_profile = has_icc_profile,
        .total_pixels = total_pixels,
        .aspect_ratio = .{ .width = aspect_w, .height = aspect_h },
        .size_mb = size_mb,
    };

    // Output results
    if (json_output) {
        const stdout = std.fs.File.stdout();
        var stdout_writer = stdout.writerStreaming(&.{}).interface;
        try std.json.Stringify.value(image_info, .{}, &stdout_writer); 
        try stdout_writer.flush();
    } else {
        const stdout = std.fs.File.stdout();
        var stdout_writer = stdout.writerStreaming(&.{}).interface;
        try stdout_writer.print("Image: {s}\n", .{image_info.file});
        try stdout_writer.print("  Format: {s}\n", .{image_info.format});
        try stdout_writer.print("  Dimensions: {}x{}\n", .{ image_info.width, image_info.height });
        try stdout_writer.print("  Channels: {}\n", .{image_info.channels});
        try stdout_writer.print("  Bit depth: {}\n", .{image_info.bit_depth});
        try stdout_writer.print("  Colorspace: {s}\n", .{image_info.colorspace});
        var size_buffer: [32]u8 = undefined;
        try stdout_writer.print("  Size: {} bytes ({s})\n", .{ image_info.size_bytes, utils.formatSize(&size_buffer, image_info.size_bytes) });
        try stdout_writer.print("  Has alpha: {}\n", .{image_info.has_alpha});
        try stdout_writer.print("  Has ICC profile: {}\n", .{image_info.has_icc_profile});
        try stdout_writer.print("  Total pixels: {}\n", .{image_info.total_pixels});
        try stdout_writer.print("  Aspect ratio: {}:{}\n", .{ image_info.aspect_ratio.width, image_info.aspect_ratio.height });
        try stdout_writer.flush();
    }
}
