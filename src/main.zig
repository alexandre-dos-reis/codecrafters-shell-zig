const std = @import("std");

pub fn main() !void {
    while (true) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("$ ", .{});

        const stdin = std.io.getStdIn().reader();
        var buffer: [1024]u8 = undefined;
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        var iter = std.mem.splitSequence(u8, user_input, " ");
        const command = iter.next().?;

        if (std.mem.eql(u8, command, "exit")) {
            const exitCode = std.fmt.parseInt(u8, iter.next().?, 10) catch 0;
            std.process.exit(exitCode);
        }

        stdout.print("{s}: command not found\n", .{command}) catch {};
    }
}
