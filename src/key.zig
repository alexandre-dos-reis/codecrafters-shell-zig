const std = @import("std");

const KeyType = enum { character, enter, delete, tabulation, space, left, right, up, down, escape, previousWord, nextWord };
const Key = struct { type: KeyType, byte: u8 };

fn getByte(stdin: anytype) ?u8 {
    return stdin.readByte() catch |err| switch (err) {
        else => null,
    };
}

pub fn get(stdin: anytype) !?Key {
    const byte = getByte(stdin) orelse {
        return null;
    };
    // std.log.debug("first {any}", .{byte});

    return switch (byte) {
        else => Key{ .type = KeyType.character, .byte = byte },
        10 => Key{ .type = KeyType.enter, .byte = byte },
        127 => Key{ .type = KeyType.delete, .byte = byte },
        9 => Key{ .type = KeyType.tabulation, .byte = byte },
        32 => Key{ .type = KeyType.space, .byte = byte },
        // `esc` but also escape sequence, we need further investigation...
        27 => {
            const secondByte = getByte(stdin) orelse {
                return Key{ .type = KeyType.escape, .byte = 0 };
            };
            // std.log.debug("second {any}", .{secondByte});
            return switch (secondByte) {
                else => null,
                91 => {
                    const thirdByte = getByte(stdin) orelse {
                        return Key{ .type = KeyType.character, .byte = secondByte };
                    };
                    // std.log.debug("third {any}", .{thirdByte});
                    return switch (thirdByte) {
                        else => null,
                        // arrow keys
                        68 => Key{ .type = KeyType.left, .byte = 0 },
                        67 => Key{ .type = KeyType.right, .byte = 0 },
                        65 => Key{ .type = KeyType.up, .byte = 0 },
                        66 => Key{ .type = KeyType.down, .byte = 0 },
                        49 => {
                            const fourthByte = getByte(stdin) orelse {
                                return null;
                            };
                            return switch (fourthByte) {
                                else => null,
                                59 => {
                                    const fifthByte = getByte(stdin) orelse {
                                        return null;
                                    };
                                    return switch (fifthByte) {
                                        else => null,
                                        53 => {
                                            const sixthByte = getByte(stdin) orelse {
                                                return null;
                                            };
                                            return switch (sixthByte) {
                                                else => null,
                                                68 => Key{ .type = .previousWord, .byte = 0 },
                                                67 => Key{ .type = .nextWord, .byte = 0 },
                                            };
                                        },
                                    };
                                },
                            };
                        },
                    };
                },
            };
        },
    };
}
