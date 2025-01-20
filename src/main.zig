const std = @import("std");

const Command = enum { exit, echo, notFound };

fn parseCommand(input: []const u8) Command {
    if (std.mem.eql(u8, input, "exit")) {
        return Command.exit;
    } else if (std.mem.eql(u8, input, "echo")) {
        return Command.echo;
    } else {
        return Command.notFound;
    }
}

pub fn main() !void {
    while (true) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("$ ", .{});

        const stdin = std.io.getStdIn().reader();
        var buffer: [1024]u8 = undefined;
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        var iter = std.mem.splitSequence(u8, user_input, " ");
        const command = iter.next().?;

        switch (parseCommand(command)) {
            .exit => {
                const exitCode = std.fmt.parseInt(u8, iter.next().?, 10) catch 0;
                std.process.exit(exitCode);
            },
            .echo => {
                try stdout.print("{s}\n", .{iter.rest()});
            },
            .notFound => {
                stdout.print("{s}: command not found\n", .{command}) catch {};
            },
        }
    }
}
