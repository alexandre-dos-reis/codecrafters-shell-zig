const KeyType = enum { character, enter, delete, tabulation };
const Key = struct { type: KeyType, byte: u8 };

pub fn get(stdin: anytype) !?Key {
    const byte = try stdin.readByte();

    // std.log.debug("{d},{c},{b}", .{ byte, byte, byte });
    // std.log.debug("{any}", .{firstByte});

    return switch (byte) {
        10 => Key{ .type = KeyType.enter, .byte = byte },
        127 => Key{ .type = KeyType.delete, .byte = byte },
        9 => Key{ .type = KeyType.tabulation, .byte = byte },
        27 => {
            // Don't handle escape sequence
            _ = try stdin.readByte();
            _ = try stdin.readByte();
            return null;
        },
        else => Key{ .type = KeyType.character, .byte = byte },
    };
}
