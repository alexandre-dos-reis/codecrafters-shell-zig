const std = @import("std");
const types = @import("./types.zig");

const Mod = enum {
    none,
    ctrl,
    alt,
};

const KeyType = enum {
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

pub const Key = struct {
    type: KeyType,
    value: ?u8,
    mod: Mod,

    fn construct(key: *@This(), byte: u8, bytes: *const Buffer, index: usize) bool {
        key.value = byte;

        switch (byte) {
            // https://www.gaijin.at/en/infos/ascii-ansi-character-table
            else => {},
            // 1, 2, 4...31 => key.mod = .ctrl,
            3 => {
                key.mod = .ctrl;
                const c = "c";
                key.value = c[0];
            },
            13 => key.type = .enter,
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
};

const Buffer = [6]u8;

const stdin = &std.io.getStdIn().reader();

fn getBytes() !Buffer {
    var bytes: Buffer = undefined;
    // 0 is the equivalent of null in ansi
    @memset(&bytes, 0);
    _ = try stdin.read(&bytes);
    return bytes;
}

pub fn readKey() !Key {
    var key = Key{ .type = .character, .value = null, .mod = .none };

    const bytes = try getBytes();

    for (bytes, 0..) |byte, i| {
        if (byte == 0 or key.construct(byte, &bytes, i)) break;
    }
    // std.log.debug("{any} {any}\n", .{ bytes, key });
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
