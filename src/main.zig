const std = @import("std");
const terminal = @import("./terminal.zig");
const reader = @import("./reader.zig");
const command = @import("./command.zig");
const cursor = @import("./cursor.zig");

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
                try bufferInput.append(key.value.?);
                cursor.increment();
            },
            .escape => try stdout.writeBytesNTimes("esc", 1),
            .tabulation => try stdout.writeBytesNTimes("tab", 1),
            .backspace => {
                // delete , space, delete
                if (bufferInput.items.len > 0) {
                    try stdout.writeBytesNTimes(&[_]u8{ 8, 32, 8 }, 1);
                    _ = bufferInput.pop();
                    cursor.decrement();
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
                try command.run(&bufferInput.items, &stdout);
                try bufferInput.resize(0);
                std.log.debug("x:{any} y:{any} limit:{any}", .{ cursor.getPositionX(), cursor.getPositionY(), cursor.getCurrentLen() });
                // std.log.debug("{s}", .{key.value.?});
                // try terminal.printPrompt(&stdout);
                cursor.resetToInitalPosition();
            },
        }
    }
}
