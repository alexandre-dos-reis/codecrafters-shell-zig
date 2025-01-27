const std = @import("std");
const types = @import("./types.zig");

const KeyType = enum { character, enter, backspace, tabulation, space, left, right, up, down, escape, unimplemented };
const Key = struct { type: KeyType, value: ?u8, ctrlMod: bool = false, altMod: bool = false };

const ALT_MOD: []const u8 = "ALT_MOD";
const CTRL_MOD: []const u8 = "CTRL_MOD";

pub fn readInput(stdin: types.StdIn) Key {
    var key = Key{ .type = .unimplemented, .value = null, .altMod = false, .ctrlMod = false };

    constructKey(stdin, &key, "ANY");

    return key;
}

fn getByte(stdin: types.StdIn) ?u8 {
    return stdin.readByte() catch |err| switch (err) {
        else => null,
    };
}

fn constructKey(stdin: types.StdIn, key: *Key, mod: []const u8) void {
    const byte = getByte(stdin) orelse {
        return;
    };

    key.altMod = std.mem.eql(u8, (mod), ALT_MOD);
    key.ctrlMod = std.mem.eql(u8, (mod), CTRL_MOD);

    // std.log.debug("first {any}", .{byte});

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
            // std.log.debug("second {any}", .{secondByte});
            switch (secondByte) {
                else => return,
                91 => {
                    const thirdByte = getByte(stdin) orelse {
                        return;
                    };
                    // std.log.debug("third {any}", .{thirdByte});
                    switch (thirdByte) {
                        else => return,
                        // arrow keys
                        68 => {
                            key.type = .left;
                            return;
                        },
                        67 => {
                            key.type = .right;
                            return;
                        },
                        65 => {
                            key.type = .up;
                            return;
                        },
                        66 => {
                            key.type = .down;
                            return;
                        },
                        49 => {
                            const fourthByte = getByte(stdin) orelse {
                                return;
                            };
                            switch (fourthByte) {
                                else => return,
                                59 => {
                                    const fifthByte = getByte(stdin) orelse {
                                        return;
                                    };
                                    switch (fifthByte) {
                                        else => return,
                                        53 => {
                                            constructKey(stdin, key, CTRL_MOD);
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
