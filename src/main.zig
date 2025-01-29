const std = @import("std");
const terminal = @import("./terminal.zig");
const reader = @import("./reader.zig");
const command = @import("./command.zig");
const cursor = @import("./cursor.zig");
const escapeSeq = @import("./escape-sequence.zig");

fn sigintHandler(sig: c_int) callconv(.C) void {
    _ = sig;
    std.debug.print("SIGINT received\n", .{});

    terminal.restoreConfigToDefault();

    std.process.exit(130);
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
                try bufferInput.insert(cursor.getCursorPosition(), key.value.?);
                cursor.incrementPosition();
                try escapeSeq.clearFromCursorToLineEnd(&stdout);
                try escapeSeq.clearFromCursorToScreenEnd(&stdout);

                const cursorPos = cursor.getCursorPosition();
                const input = bufferInput.items;

                if (cursorPos < input.len) {
                    var count: u16 = 0;
                    for (input[cursorPos..input.len]) |value| {
                        try stdout.writeByte(value);
                        cursor.incrementPosition();
                        count += 1;
                    }
                    for (0..count) |_| {
                        try cursor.moveBackward(&stdout, bufferInput.items.len);
                    }
                }
            },
            .escape => try stdout.writeBytesNTimes("esc", 1),
            .tabulation => try stdout.writeBytesNTimes("tab", 1),
            .backspace => {
                // delete , space, delete
                if (bufferInput.items.len > 0) {
                    try stdout.writeBytesNTimes(&[_]u8{ 8, 32, 8 }, 1);
                    cursor.decrementPosition();
                    _ = bufferInput.orderedRemove(cursor.getCursorPosition());

                    try escapeSeq.clearFromCursorToLineEnd(&stdout);
                    try escapeSeq.clearFromCursorToScreenEnd(&stdout);

                    const cursorPos = cursor.getCursorPosition();
                    const input = bufferInput.items;

                    if (cursorPos < input.len) {
                        var count: u16 = 0;
                        for (input[cursorPos..input.len]) |value| {
                            try stdout.writeByte(value);
                            cursor.incrementPosition();
                            count += 1;
                        }
                        for (0..count) |_| {
                            try cursor.moveBackward(&stdout, bufferInput.items.len);
                        }
                    }
                }
            },
            .up, .down => {
                try stdout.writeBytesNTimes("arrow", 1);
            },
            .left => {
                try cursor.moveBackward(&stdout, bufferInput.items.len);
            },
            .right => {
                try cursor.moveForward(&stdout, bufferInput.items.len);
            },
            .enter => {
                // display `enter` character
                try stdout.writeByte(key.value.?);
                try command.run(&bufferInput.items);
                try bufferInput.resize(0);
                std.log.debug("x:{any} y:{any} pos:{any}", .{ cursor.getPositionX(), cursor.getPositionY(), cursor.getCursorPosition() });
                // std.log.debug("{s}", .{key.value.?});
                // try terminal.printPrompt(&stdout);
                cursor.resetToInitalPosition();
            },
        }
    }
}
