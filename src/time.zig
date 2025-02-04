const std = @import("std");

pub fn getcurrentReadableTime() [9]u8 {
    var buf: [9]u8 = undefined;
    const timestamp = @as(i64, @intCast(std.time.timestamp()));
    const secs = @rem(timestamp, 60);
    const mins = @rem((@divFloor(timestamp, 60)), 60);
    const hours = @rem((@divFloor(timestamp, 3600)), 24);
    _ = std.fmt.bufPrint(&buf, "{d}:{d}:{d}", .{ hours, mins, secs }) catch "00:00:00";
    return buf;
}

pub fn getTickTimestamp() i64 {
    return std.time.milliTimestamp();
}
