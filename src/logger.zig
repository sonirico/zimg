const std = @import("std");

const LogLevel = enum(u8) {
    debug = 0,
    info = 1,
    warn = 2,
    err = 3,
};

var log_level: LogLevel = .info;

pub fn init(level: LogLevel) void {
    log_level = level;
}

pub fn deinit() void {}

/// Print error to stderr and flush immediately
pub fn err(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) <= @intFromEnum(LogLevel.err)) {
        const stderr = std.fs.File.stderr();
        var stderr_writer = stderr.writerStreaming(&.{}).interface;
        stderr_writer.print("Error: " ++ fmt ++ "\n", args) catch return;
        stderr_writer.flush() catch return;
    }
}

/// Print warning to stderr and flush immediately
pub fn warn(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) <= @intFromEnum(LogLevel.warn)) {
        const stderr = std.fs.File.stderr();
        var stderr_writer = stderr.writerStreaming(&.{}).interface;
        stderr_writer.print("Warning: " ++ fmt ++ "\n", args) catch return;
        stderr_writer.flush() catch return;
    }
}

/// Print info to stdout and flush immediately
pub fn info(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) <= @intFromEnum(LogLevel.info)) {
        const stdout = std.fs.File.stdout();
        var stdout_writer = stdout.writerStreaming(&.{}).interface;
        stdout_writer.print(fmt ++ "\n", args) catch return;
        stdout_writer.flush() catch return;
    }
}

/// Print debug to stderr and flush immediately
pub fn debug(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) <= @intFromEnum(LogLevel.debug)) {
        const stderr = std.fs.File.stderr();
        var stderr_writer = stderr.writerStreaming(&.{}).interface;
        stderr_writer.print("Debug: " ++ fmt ++ "\n", args) catch return;
        stderr_writer.flush() catch return;
    }
}
