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
