const std = @import("std");
const Writer = std.io.Writer;
const zli = @import("zli");

pub fn register(writer: *Writer, allocator: std.mem.Allocator) !*zli.Command {
    const cmd = try zli.Command.init(writer, allocator, .{
        .name = "optimize",
        .description = "Optimize image file for size and quality",
    }, run);

    try cmd.addFlag(.{
        .name = "palette",
        .description = "Use palette optimization",
        .type = .Bool,
        .default_value = .{ .Bool = false },
    });

    try cmd.addFlag(.{
        .name = "q",
        .shortcut = "q",
        .description = "Quality level (1-100)",
        .type = .String,
        .default_value = .{ .String = "85" },
    });

    try cmd.addFlag(.{
        .name = "strip",
        .description = "Strip metadata",
        .type = .Bool,
        .default_value = .{ .Bool = false },
    });

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

    return cmd;
}

fn run(ctx: zli.CommandContext) !void {
    const file = ctx.getArg("file") orelse {
        try ctx.command.printHelp();
        return;
    };

    const palette = ctx.flag("palette", bool);
    const quality_str = ctx.flag("q", []const u8);
    const strip = ctx.flag("strip", bool);
    const json_output = ctx.flag("json", bool);

    const quality = std.fmt.parseInt(u8, quality_str, 10) catch 85;

    if (json_output) {
        try ctx.writer.print("{{\"command\":\"optimize\",\"file\":\"{s}\",\"palette\":{},\"quality\":{},\"strip\":{}}}\n", .{ file, palette, quality, strip });
        try ctx.writer.flush();
    } else {
        try ctx.writer.print("Optimizing {s} with options:\n", .{file});
        try ctx.writer.print("  Palette: {}\n", .{palette});
        try ctx.writer.print("  Quality: {}\n", .{quality});
        try ctx.writer.print("  Strip metadata: {}\n", .{strip});
        try ctx.writer.flush();

        // IMPLEMENTATION PLACEHOLDER: Real libvips optimization logic
        // 1. Load image with vips_image_new_from_file()
        // 2. Apply palette optimization if enabled using vips_quantise()
        // 3. Set quality for JPEG/WebP compression
        // 4. Strip EXIF/metadata if requested using vips_image_remove()
        // 5. Save optimized image with appropriate format-specific parameters
        // 6. Report compression ratio and file size reduction
    }
}
