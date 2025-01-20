const std = @import("std");

pub fn main() !void {
    while (true) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("$ ", .{});

        const stdin = std.io.getStdIn().reader();
        var buffer: [1024]u8 = undefined;
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        var spansIterator = std.mem.splitSequence(u8, user_input, " ");
        const command = spansIterator.next().?;
        stdout.print("{s}: command not found\n", .{command}) catch {};
    }
}
