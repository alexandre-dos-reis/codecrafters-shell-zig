const std = @import("std");

const KeyType = enum { character, enter, delete, tabulation, unimplemented };

fn byteToKeyAction(byte: u8) KeyType {
    return switch (byte) {
        10 => KeyType.enter,
        127 => KeyType.delete,
        9 => KeyType.tabulation,
        else => KeyType.character,
    };
}

fn setupTerminal() !void {
    // Manipulate terminal
    const fd_t: i32 = 0;
    var term = try std.posix.tcgetattr(fd_t);
    // Turn off canonical mode => Read char byte by byte instead of line by line
    term.lflag.ICANON = false;
    // Turn off echo mode => as we want to manipulate each render.
    term.lflag.ECHO = false;
    try std.posix.tcsetattr(fd_t, .NOW, term);
}

pub fn main() !void {
    try setupTerminal();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    try stdout.print("$ ", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var buffer = std.ArrayList(u8).init(gpa.allocator());
    defer buffer.deinit();

    while (true) {
        const byte = try stdin.readByte();

        const keyAction = blk: {
            if (byte == 27) {
                // Don't handle escape sequence
                _ = try stdin.readByte();
                _ = try stdin.readByte();
                break :blk KeyType.unimplemented;
            } else {
                break :blk byteToKeyAction(byte);
            }
        };

        // std.log.debug("{d},{c},{b}", .{ byte, byte, byte });
        // std.log.debug("{any}", .{firstByte});

        switch (keyAction) {
            .character => {
                try stdout.writeByte(byte);
                try buffer.append(byte);
            },
            .tabulation => try stdout.writeBytesNTimes("tab", 1),
            .delete => {
                // delete , space, delete
                if (buffer.items.len > 0) {
                    try stdout.writeBytesNTimes(&[_]u8{ 8, 32, 8 }, 1);
                    _ = buffer.pop();
                }
            },
            .enter => {
                try stdout.writeByte(byte);
                std.log.debug("{s}", .{buffer.items});
                try buffer.resize(0);
            },
            .unimplemented => {},
        }
    }
}
