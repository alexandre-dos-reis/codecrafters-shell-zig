const std = @import("std");
const types = @import("./types.zig");

const KeyType = enum { character, enter, backspace, tabulation, space, left, right, up, down, escape, unimplemented };
const Mod = enum { none, alt, ctrl };

const Key = struct { type: KeyType, value: ?u8, mod: Mod };

const enableDebug: bool = false;

pub fn readInput(stdin: types.StdIn) Key {
    var key = Key{ .type = .unimplemented, .value = null, .mod = .none };

    constructKey(stdin, &key);

    return key;
}

fn getByte(stdin: types.StdIn) ?u8 {
    return stdin.readByte() catch |err| switch (err) {
        else => null,
    };
}

/// TODO: rewrite to avoid nesting...
fn constructKey(stdin: types.StdIn, key: *Key) void {
    const byte = getByte(stdin) orelse {
        return;
    };

    if (enableDebug) {
        std.log.debug("1st:{}", .{byte});
    }

    switch (byte) {
        else => {
            key.type = .character;
            key.value = byte;
            return;
        },
        10 => {
            key.type = .enter;
            key.value = byte;
            return;
        },
        127 => {
            key.type = .backspace;
            key.value = byte;
            return;
        },
        9 => {
            key.type = .tabulation;
            key.value = byte;
            return;
        },
        32 => {
            key.type = .space;
            key.value = byte;
            return;
        },
        // `esc` but also escape sequence, we need further investigation...
        27 => {
            const secondByte = getByte(stdin) orelse {
                key.type = .escape;
                key.value = byte;
                return;
            };

            if (enableDebug) {
                std.log.debug("2nd:{}", .{secondByte});
            }

            // std.log.debug("second {any}", .{secondByte});
            switch (secondByte) {
                else => return,
                91 => {
                    const thirdByte = getByte(stdin) orelse {
                        return;
                    };

                    if (enableDebug) {
                        std.log.debug("3rd:{}", .{thirdByte});
                    }

                    if (handleArrowKeys(key, thirdByte)) {
                        return;
                    }

                    switch (thirdByte) {
                        else => return,
                        // arrow keys
                        49 => {
                            const fourthByte = getByte(stdin) orelse {
                                return;
                            };
                            if (enableDebug) {
                                std.log.debug("4th:{}", .{fourthByte});
                            }
                            switch (fourthByte) {
                                else => return,
                                59 => {
                                    const fifthByte = getByte(stdin) orelse {
                                        return;
                                    };
                                    if (enableDebug) {
                                        std.log.debug("5th:{}", .{fifthByte});
                                    }
                                    switch (fifthByte) {
                                        else => return,
                                        53 => {
                                            key.mod = .ctrl;
                                            const sixthByte = getByte(stdin) orelse {
                                                return;
                                            };
                                            if (enableDebug) {
                                                std.log.debug("6th:{}", .{sixthByte});
                                            }
                                            _ = handleArrowKeys(key, sixthByte);
                                            return;
                                        },
                                    }
                                },
                            }
                        },
                    }
                },
            }
        },
    }
}

fn handleArrowKeys(key: *Key, byte: u8) bool {
    return switch (byte) {
        else => false,
        68 => {
            key.type = .left;

            return true;
        },
        67 => {
            key.type = .right;
            return true;
        },
        65 => {
            key.type = .up;
            return true;
        },
        66 => {
            key.type = .down;
            return true;
        },
    };
}
