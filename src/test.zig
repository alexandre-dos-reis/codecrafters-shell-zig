const std = @import("std");
const terminal = @import("./terminal.zig");
const reader = @import("./reader.zig");
const command = @import("./command.zig");

fn sigintHandler(sig: c_int) callconv(.C) void {
    _ = sig;
    std.debug.print("SIGINT received\n", .{});

    terminal.restoreTerminal();

    std.process.exit(130);
}

pub fn main() !void {
    terminal.setTerminal();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    try terminal.printPrompt(&stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var buffer = std.ArrayList(u8).init(gpa.allocator());
    defer buffer.deinit();

    // Manage the Ctrl + C
    const act = std.os.linux.Sigaction{
        .handler = .{ .handler = sigintHandler },
        .mask = std.os.linux.empty_sigset,
        .flags = 0,
    };

    if (std.os.linux.sigaction(std.os.linux.SIG.INT, &act, null) != 0) {
        return error.SignalHandlerError;
    }

    while (true) {
        const key = reader.readInput(&stdin);
        switch (key.type) {
            .unimplemented => {},
            .character, .space => {
                if (key.value) |value| {
                    try stdout.writeByte(value);
                    try buffer.append(value);
                }
            },
            .escape => try stdout.writeBytesNTimes("esc", 1),
            .tabulation => try stdout.writeBytesNTimes("tab", 1),
            .backspace => {
                // delete , space, delete
                if (buffer.items.len > 0) {
                    try stdout.writeBytesNTimes(&[_]u8{ 8, 32, 8 }, 1);
                    _ = buffer.pop();
                }
            },
            .up, .down, .left, .right => {
                try stdout.writeBytesNTimes("arrow", 1);
            },
            .enter => {
                // display `enter` character
                if (key.value) |value| {
                    try stdout.writeByte(value);
                    try command.run(&buffer.items, &stdout);
                    try buffer.resize(0);
                    try terminal.printPrompt(&stdout);
                }
            },
        }
    }
}
