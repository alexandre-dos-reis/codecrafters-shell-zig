const std = @import("std");
const types = @import("./types.zig");

const KeyType = enum {
    unimplemented,
    character,
    enter,
    backspace,
    tabulation,
    space,
    left,
    right,
    up,
    down,
    escape,
};
const Mod = enum {
    none,
    ctrl,
    alt,
};

const Key = struct {
    type: KeyType,
    value: ?u8,
    mod: Mod,
};

const Buffer = [6]u8;

fn getBytes(stdin: types.StdIn) !Buffer {
    var bytes: Buffer = undefined;
    // 0 is the equivalent of null in ansi
    @memset(&bytes, 0);
    _ = try stdin.read(&bytes);
    return bytes;
}

pub fn readInput(stdin: types.StdIn) !Key {
    var key = Key{ .type = .unimplemented, .value = null, .mod = .none };

    const bytes = try getBytes(stdin);

    // std.log.debug("{any}", .{bytes});

    for (bytes, 0..) |byte, i| {
        if (byte == 0) {
            break;
        }
        // return true if we want to break the loop
        if (constructKey(&key, byte, &bytes, i)) break;
    }
    // std.log.debug("{any}", .{key});

    return key;
}

fn isCSI(bytes: *const Buffer) bool {
    if (bytes.*[0] == 27 and bytes.*[1] == 91) {
        return true;
    }
    return false;
}

fn isMod(bytes: *const Buffer) bool {
    if (isCSI(bytes) and bytes[2] == 49 and bytes[3] == 59) {
        return true;
    }
    return false;
}

fn constructKey(key: *Key, byte: u8, bytes: *const Buffer, index: usize) bool {
    key.value = byte;

    switch (byte) {
        else => key.type = .character,
        10 => key.type = .enter,
        127 => key.type = .backspace,
        9 => key.type = .tabulation,
        32 => key.type = .space,
        27 => {
            if (index == 0 and bytes[1] == 0) {
                // Esc only
                key.type = .escape;
                return true;
            }
        },
        91 => {
            if (index == 1 and bytes[0] == 27) {
                // CSI !
                key.type = .escape;
            }
        },
        51 => {
            if (isMod(bytes)) {
                key.mod = .alt;
            }
        },
        53 => {
            if (isMod(bytes)) {
                key.mod = .ctrl;
            }
        },
        68 => {
            if (isCSI(bytes)) {
                key.type = .left;
            }
        },
        67 => {
            if (isCSI(bytes)) {
                key.type = .right;
            }
        },
        65 => {
            if (isCSI(bytes)) {
                key.type = .up;
            }
        },
        66 => {
            if (isCSI(bytes)) {
                key.type = .down;
            }
        },
    }
    return false;
}
