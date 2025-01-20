const std = @import("std");

const Command = enum { exit, echo, notFound, type };

fn parseCommand(input: []const u8) Command {
    inline for (@typeInfo(Command).Enum.fields) |field| {
        if (std.mem.eql(u8, input, field.name)) {
            return @enumFromInt(field.value);
        }
    }
    return Command.notFound;
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
                try stdout.print("{s}: command not found\n", .{command});
            },
            .type => {
                const typeArg = iter.next().?;
                const commandFound = parseCommand(typeArg);

                switch (commandFound) {
                    .notFound => try stdout.print("{s}: not found\n", .{typeArg}),
                    else => try stdout.print("{s} is a shell builtin\n", .{typeArg}),
                }
            },
        }
    }
}
