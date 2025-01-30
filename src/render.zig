const std = @import("std");
const constants = @import("constant.zig");
const escapeSeq = @import("./escape-sequence.zig");
const cursor = @import("./cursor.zig");

pub const stdout = std.io.getStdOut().writer();

pub fn renderCharacter(byte: u8) !void {
    try stdout.writeByte(byte);
}

pub fn render(bytes: []const u8) !void {
    try stdout.writeAll(bytes);
}

pub fn renderCSI(bytes: []const u8) !void {
    stdout.writeAll(constants.CSI ++ bytes);
}

pub fn renderBackspace() !void {
    try stdout.writeAll(&[_]u8{
        8, // delete
        32, // space
        8, // delete
    });
}

pub fn renderBufferRest(input: *std.ArrayList(u8)) !void {
    try escapeSeq.clearFromCursorToLineEnd();
    try escapeSeq.clearFromCursorToScreenEnd();

    const cursorPos = cursor.getRelativePosition();

    if (cursorPos < input.*.items.len) {
        var count: u16 = 0;
        for (input.*.items[cursorPos..input.*.items.len]) |value| {
            try stdout.writeByte(value);
            cursor.incrementPosition();
            count += 1;
        }
        for (0..count) |_| {
            try cursor.moveBackward();
        }
    }
}
