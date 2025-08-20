const std = @import("std");

// libvips C integration via @cImport
// This module provides Zig wrappers for libvips C API
pub const c = @cImport({
    @cDefine("_GNU_SOURCE", "1");
    @cDefine("_DEFAULT_SOURCE", "1");
    @cDefine("_POSIX_C_SOURCE", "200809L");
    @cDefine("_FILE_OFFSET_BITS", "64");
    @cDefine("_TIME_BITS", "64");
    @cInclude("vips/vips.h");
});

pub const VipsError = error{
    InitializationFailed,
    LoadFailed,
    SaveFailed,
    ProcessingFailed,
    InvalidFormat,
    OutOfMemory,
};

pub const ImageFormat = enum {
    jpeg,
    png,
    webp,
    tiff,
    avif,
    heif,
    gif,
    bmp,
    unknown,
};

pub const InterpolationMethod = enum {
    nearest,
    linear,
    cubic,
    lanczos,
};

pub const VipsImage = struct {
    handle: *c.VipsImage,

    pub fn deinit(self: *VipsImage) void {
        c.g_object_unref(self.handle);
    }

    pub fn getWidth(self: *const VipsImage) u32 {
        return @intCast(c.vips_image_get_width(self.handle));
    }

    pub fn getHeight(self: *const VipsImage) u32 {
        return @intCast(c.vips_image_get_height(self.handle));
    }

    pub fn getBands(self: *const VipsImage) u32 {
        return @intCast(c.vips_image_get_bands(self.handle));
    }

    pub fn getFormat(self: *const VipsImage) c.VipsBandFormat {
        return c.vips_image_get_format(self.handle);
    }

    pub fn getFormatName(self: *const VipsImage) []const u8 {
        // Get the loader used for this image
        var loader: [*c]const u8 = null;
        const result = c.vips_image_get_string(self.handle, "vips-loader", &loader);

        if (result != 0 or loader == null) {
            return "Unknown";
        }

        const loader_str = std.mem.span(loader); // Map VIPS loaders to human-readable format names
        if (std.mem.indexOf(u8, loader_str, "jpeg")) |_| return "JPEG";
        if (std.mem.indexOf(u8, loader_str, "png")) |_| return "PNG";
        if (std.mem.indexOf(u8, loader_str, "webp")) |_| return "WebP";
        if (std.mem.indexOf(u8, loader_str, "tiff")) |_| return "TIFF";
        if (std.mem.indexOf(u8, loader_str, "gif")) |_| return "GIF";
        if (std.mem.indexOf(u8, loader_str, "heif")) |_| return "HEIF";
        if (std.mem.indexOf(u8, loader_str, "avif")) |_| return "AVIF";
        if (std.mem.indexOf(u8, loader_str, "jp2k")) |_| return "JPEG2000";
        if (std.mem.indexOf(u8, loader_str, "jxl")) |_| return "JPEG XL";
        if (std.mem.indexOf(u8, loader_str, "magick")) |_| return "ImageMagick";
        if (std.mem.indexOf(u8, loader_str, "openslide")) |_| return "OpenSlide";
        if (std.mem.indexOf(u8, loader_str, "pdf")) |_| return "PDF";
        if (std.mem.indexOf(u8, loader_str, "svg")) |_| return "SVG";

        return "Unknown";
    }

    pub fn getColorspace(self: *const VipsImage) []const u8 {
        const interpretation = c.vips_image_get_interpretation(self.handle);

        return switch (interpretation) {
            c.VIPS_INTERPRETATION_ERROR => "Error",
            c.VIPS_INTERPRETATION_MULTIBAND => "Multiband",
            c.VIPS_INTERPRETATION_B_W => "Black & White",
            c.VIPS_INTERPRETATION_HISTOGRAM => "Histogram",
            c.VIPS_INTERPRETATION_XYZ => "XYZ",
            c.VIPS_INTERPRETATION_LAB => "LAB",
            c.VIPS_INTERPRETATION_CMYK => "CMYK",
            c.VIPS_INTERPRETATION_LABQ => "LABQ",
            c.VIPS_INTERPRETATION_RGB => "RGB",
            c.VIPS_INTERPRETATION_CMC => "CMC",
            c.VIPS_INTERPRETATION_LCH => "LCH",
            c.VIPS_INTERPRETATION_LABS => "LABS",
            c.VIPS_INTERPRETATION_sRGB => "sRGB",
            c.VIPS_INTERPRETATION_YXY => "YXY",
            c.VIPS_INTERPRETATION_FOURIER => "Fourier",
            c.VIPS_INTERPRETATION_RGB16 => "RGB16",
            c.VIPS_INTERPRETATION_GREY16 => "Grey16",
            c.VIPS_INTERPRETATION_MATRIX => "Matrix",
            c.VIPS_INTERPRETATION_scRGB => "scRGB",
            c.VIPS_INTERPRETATION_HSV => "HSV",
            else => "Unknown",
        };
    }

    pub fn hasIccProfile(self: *const VipsImage) bool {
        var icc_data: ?*const anyopaque = null;
        var icc_size: usize = 0;

        // Try to get ICC profile
        const result = c.vips_image_get_blob(self.handle, "icc-profile-data", &icc_data, &icc_size);
        return result == 0 and icc_data != null and icc_size > 0;
    }
};

pub fn init() VipsError!void {
    if (c.vips_init("zimg") != 0) {
        return VipsError.InitializationFailed;
    }
}

pub fn shutdown() void {
    c.vips_shutdown();
}

pub fn loadImageFromBuffer(buffer: []const u8, options: ?[]const u8) VipsError!VipsImage {
    const image = c.vips_image_new_from_buffer(buffer.ptr, buffer.len, if (options) |opts| opts.ptr else @as([*c]const u8, @ptrFromInt(0)), @as(?*anyopaque, null));

    if (image == null) {
        return VipsError.LoadFailed;
    }

    return VipsImage{ .handle = image.? };
}

pub fn saveImage(allocator: std.mem.Allocator, image: *const VipsImage, path: []const u8) VipsError!void {
    const c_path = allocator.dupeZ(u8, path) catch {
        return VipsError.OutOfMemory;
    };
    defer allocator.free(c_path);

    if (c.vips_image_write_to_file(image.handle, c_path.ptr, @as(?*anyopaque, null)) != 0) {
        return VipsError.SaveFailed;
    }
}

pub fn resizeImage(image: *const VipsImage, scale_x: f64, scale_y: f64) VipsError!VipsImage {
    var output: *c.VipsImage = undefined;

    if (c.vips_resize(image.handle, &output, scale_x, "vscale", scale_y, @as(?*anyopaque, null)) != 0) {
        return VipsError.ProcessingFailed;
    }

    return VipsImage{ .handle = output };
}

pub fn cropImage(image: *const VipsImage, x: i32, y: i32, width: u32, height: u32) VipsError!VipsImage {
    var output: *c.VipsImage = undefined;

    if (c.vips_extract_area(image.handle, &output, x, y, @intCast(width), @intCast(height), @as(?*anyopaque, null)) != 0) {
        return VipsError.ProcessingFailed;
    }

    return VipsImage{ .handle = output };
}
