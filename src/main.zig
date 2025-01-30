const std = @import("std");
const terminal = @import("./terminal.zig");
const reader = @import("./reader.zig");
const command = @import("./command.zig");
const cursor = @import("./cursor.zig");
const escapeSeq = @import("./escape-sequence.zig");
const types = @import("./types.zig");
const render = @import("./render.zig");

fn sigintHandler(sig: c_int) callconv(.C) void {
    _ = sig;
    std.debug.print("SIGINT received\n", .{});

    terminal.restoreConfigToDefault();

    std.process.exit(130);
}

pub fn main() !void {
    terminal.setConfig();

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
        const key = try reader.readInput();
        switch (key.type) {
            else => {},
            .character, .space => {
                try render.renderCharacter(key.value.?);
                try bufferInput.insert(cursor.getRelativePosition(), key.value.?);
                cursor.incrementPosition();
                try render.renderBufferRest(&bufferInput);
            },
            .escape => try render.render("esc"),
            .tabulation => try render.render("tab"),
            .backspace => {
                if (bufferInput.items.len > 0) {
                    try render.renderBackspace();
                    cursor.decrementPosition();
                    _ = bufferInput.orderedRemove(cursor.getRelativePosition());
                    try render.renderBufferRest(&bufferInput);
                }
            },
            .up, .down => {
                try render.render("arrow");
            },
            .left => switch (key.mod) {
                .none => {
                    if (bufferInput.items.len > 0) {
                        try cursor.moveBackward();
                    }
                },
                .ctrl => try cursor.moveCursorToPrevious1stWordLetter(&bufferInput),
                .alt => {},
            },
            .right => switch (key.mod) {
                .none => {
                    if (cursor.getRelativePosition() < bufferInput.items.len) {
                        try cursor.moveForward();
                    }
                },
                .ctrl => try cursor.moveCursorToNextSpaceChar(&bufferInput),
                .alt => {},
            },
            .enter => {
                // display `enter` character
                try render.renderCharacter(key.value.?);
                try command.run(&bufferInput.items);
                try bufferInput.resize(0);
                cursor.resetToInitalPosition();
            },
        }
    }
}
