const std = @import("std");
const terminal = @import("./terminal.zig");
const reader = @import("./reader.zig");
const command = @import("./command.zig");
const cursor = @import("./cursor.zig");
const escapeSeq = @import("./escape-sequence.zig");
const types = @import("./types.zig");

fn sigintHandler(sig: c_int) callconv(.C) void {
    _ = sig;
    std.debug.print("SIGINT received\n", .{});

    terminal.restoreConfigToDefault();

    std.process.exit(130);
}

pub fn renderInsert(stdout: types.StdOut, input: *std.ArrayList(u8)) !void {
    try escapeSeq.clearFromCursorToLineEnd(stdout);
    try escapeSeq.clearFromCursorToScreenEnd(stdout);

    const cursorPos = cursor.getRelativePosition();

    if (cursorPos < input.*.items.len) {
        var count: u16 = 0;
        for (input.*.items[cursorPos..input.*.items.len]) |value| {
            try stdout.writeByte(value);
            cursor.incrementPosition();
            count += 1;
        }
        for (0..count) |_| {
            try cursor.moveBackward(stdout);
        }
    }
}

pub fn main() !void {
    terminal.setConfig();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    // try terminal.printPrompt(&stdout);

    // Manage the Ctrl + C
    const act = std.os.linux.Sigaction{
        .handler = .{ .handler = sigintHandler },
        .mask = std.os.linux.empty_sigset,
        .flags = 0,
    };

    if (std.os.linux.sigaction(std.os.linux.SIG.INT, &act, null) != 0) {
        return error.SignalHandlerError;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var bufferInput = std.ArrayList(u8).init(gpa.allocator());
    defer bufferInput.deinit();

    while (true) {
        const key = reader.readInput(&stdin);

        switch (key.type) {
            .unimplemented => {},
            .character, .space => {
                try stdout.writeByte(key.value.?);
                try bufferInput.insert(cursor.getRelativePosition(), key.value.?);
                cursor.incrementPosition();
                try renderInsert(&stdout, &bufferInput);
            },
            .escape => try stdout.writeBytesNTimes("esc", 1),
            .tabulation => try stdout.writeBytesNTimes("tab", 1),
            .backspace => {
                if (bufferInput.items.len > 0) {
                    try stdout.writeBytesNTimes(&[_]u8{
                        8, // delete
                        32, // space
                        8, // delete
                    }, 1);
                    cursor.decrementPosition();
                    _ = bufferInput.orderedRemove(cursor.getRelativePosition());
                    try renderInsert(&stdout, &bufferInput);
                }
            },
            .up, .down => {
                try stdout.writeBytesNTimes("arrow", 1);
            },
            .left => switch (key.mod) {
                .none => {
                    if (bufferInput.items.len > 0) {
                        try cursor.moveBackward(&stdout);
                    }
                },
                .ctrl => {
                    // Move cursor to first letter of previous word
                    if (cursor.getRelativePosition() > 0) {
                        var cursorPos = cursor.getRelativePosition();
                        const spaceChar: u8 = 32;

                        // Handle case if are already on a first letter
                        if (bufferInput.items[cursorPos - 1] == spaceChar) {
                            try cursor.moveBackward(&stdout);
                            cursorPos -= 1;
                        }

                        while (cursorPos > 0) {
                            const character = bufferInput.items[cursorPos - 1];
                            if (character == spaceChar) {
                                break;
                            }
                            cursorPos -= 1;
                            try cursor.moveBackward(&stdout);
                        }
                    }
                },
                .alt => {},
            },
            .right => switch (key.mod) {
                .none => {
                    if (cursor.getRelativePosition() < bufferInput.items.len) {
                        try cursor.moveForward(&stdout);
                    }
                },
                .ctrl => {
                    // move cursor to space after next word
                    var cursorPos = cursor.getRelativePosition();
                    const limit = bufferInput.items.len;

                    if (cursorPos < limit) {
                        const spaceChar: u8 = 32;

                        // handle case where are already on a space after a word.
                        if (bufferInput.items[cursorPos + 1] == spaceChar) {
                            try cursor.moveForward(&stdout);
                            cursorPos += 1;
                        }

                        while (cursorPos + 1 < limit) {
                            const character = bufferInput.items[cursorPos + 1];
                            if (character == spaceChar) {
                                break;
                            }
                            cursorPos += 1;
                            try cursor.moveForward(&stdout);
                        }
                        try cursor.moveForward(&stdout);
                    }
                },
                .alt => {},
            },
            .enter => {
                // display `enter` character
                try stdout.writeByte(key.value.?);
                try command.run(&bufferInput.items);
                try bufferInput.resize(0);
                cursor.resetToInitalPosition();
            },
        }
    }
}
