const std = @import("std");
const terminal = @import("./terminal.zig");
const key = @import("./key.zig");
const command = @import("./command.zig");

pub fn main() !void {
    try terminal.setup();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    try terminal.printPrompt(stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var buffer = std.ArrayList(u8).init(gpa.allocator());
    defer buffer.deinit();

    while (true) {
        if (try key.get(stdin)) |k| {
            switch (k.type) {
                .character, .space => {
                    try stdout.writeByte(k.byte);
                    try buffer.append(k.byte);
                },
                .escape => try stdout.writeBytesNTimes("esc", 1),
                .tabulation => try stdout.writeBytesNTimes("tab", 1),
                .delete => {
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
                    try stdout.writeByte(k.byte);
                    try command.run(buffer.items, stdout);
                    try buffer.resize(0);
                    try terminal.printPrompt(stdout);
                },
                .previousWord => {
                    try stdout.writeBytesNTimes("previous word", 1);
                },
                .nextWord => {
                    try stdout.writeBytesNTimes("next word", 1);
                },
                // else => {},
            }
        }
    }
}
