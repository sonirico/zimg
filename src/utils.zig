const std = @import("std");
const vips = @import("vips.zig");

pub const LoadError = error{
    LoadFailed,
    OutOfMemory,
    InvalidInput,
};

/// Load image from file path by reading to buffer first
pub fn loadImage(allocator: std.mem.Allocator, path: []const u8) LoadError!vips.VipsImage {
    const file = std.fs.cwd().openFile(path, .{}) catch {
        return LoadError.LoadFailed;
    };
    defer file.close();

    const max_size = 500 * 1024 * 1024; // 500MB max for image files
    const buffer = file.readToEndAlloc(allocator, max_size) catch {
        return LoadError.LoadFailed;
    };
    defer allocator.free(buffer);

    return loadImageFromBuffer(buffer) catch LoadError.LoadFailed;
}

/// Load image from buffer using libvips
pub fn loadImageFromBuffer(buffer: []const u8) vips.VipsError!vips.VipsImage {
    return vips.loadImageFromBuffer(buffer, null);
}

/// Read stdin to buffer if data is available
pub fn readStdinBuffer(allocator: std.mem.Allocator) !?[]u8 {
    const stdin = std.io.getStdIn();

    // Check if stdin has data available (non-blocking check)
    // On Unix systems, we can use stat to check if stdin is a pipe/file
    const stat = std.posix.fstat(stdin.handle) catch return null;

    // If it's a regular file or pipe, read it; if it's a terminal, skip
    if (std.posix.S.ISREG(stat.mode) or std.posix.S.ISFIFO(stat.mode)) {
        // Read all stdin content
        const max_size = 100 * 1024 * 1024; // 100MB max
        return stdin.readToEndAlloc(allocator, max_size) catch return null;
    }

    return null;
}

pub fn formatSize(buffer: []u8, num_bytes: u64) []const u8 {
    if (num_bytes < 1024) {
        return std.fmt.bufPrint(buffer, "{d} B", .{num_bytes}) catch "0 B";
    } else if (num_bytes < 1024 * 1024) {
        const kb = @as(f64, @floatFromInt(num_bytes)) / 1024.0;
        return std.fmt.bufPrint(buffer, "{d:.1} KB", .{kb}) catch "0.0 KB";
    } else if (num_bytes < 1024 * 1024 * 1024) {
        const mb = @as(f64, @floatFromInt(num_bytes)) / (1024.0 * 1024.0);
        return std.fmt.bufPrint(buffer, "{d:.1} MB", .{mb}) catch "0.0 MB";
    } else {
        const gb = @as(f64, @floatFromInt(num_bytes)) / (1024.0 * 1024.0 * 1024.0);
        return std.fmt.bufPrint(buffer, "{d:.1} GB", .{gb}) catch "0.0 GB";
    }
}

// Tests inline - más idiomático en Zig
test "formatSize with various sizes" {
    var buffer: [64]u8 = undefined;

    const result_bytes = formatSize(&buffer, 512);
    try std.testing.expectEqualStrings("512 B", result_bytes);

    const result_kb = formatSize(&buffer, 2048);
    try std.testing.expectEqualStrings("2.0 KB", result_kb);

    const result_kb_decimal = formatSize(&buffer, 1536); // 1.5 KB
    try std.testing.expectEqualStrings("1.5 KB", result_kb_decimal);

    const result_kb_precise = formatSize(&buffer, 1331); // ~1.3 KB
    try std.testing.expectEqualStrings("1.3 KB", result_kb_precise);

    const result_mb = formatSize(&buffer, 5 * 1024 * 1024);
    try std.testing.expectEqualStrings("5.0 MB", result_mb);

    const result_mb_decimal = formatSize(&buffer, 1536 * 1024); // 1.5 MB
    try std.testing.expectEqualStrings("1.5 MB", result_mb_decimal);

    const result_gb = formatSize(&buffer, 3 * 1024 * 1024 * 1024);
    try std.testing.expectEqualStrings("3.0 GB", result_gb);

    const result_gb_decimal = formatSize(&buffer, 1536 * 1024 * 1024); // 1.5 GB
    try std.testing.expectEqualStrings("1.5 GB", result_gb_decimal);
}
