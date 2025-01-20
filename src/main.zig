const std = @import("std");

const Command = enum { exit, echo, type };

fn parseCommand(input: []const u8) ?Command {
    inline for (@typeInfo(Command).Enum.fields) |field| {
        if (std.mem.eql(u8, input, field.name)) {
            return @enumFromInt(field.value);
        }
    }
    return null;
}

pub fn main() !void {
    while (true) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("$ ", .{});

        const stdin = std.io.getStdIn().reader();
        var buffer: [1024]u8 = undefined;
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        var iter = std.mem.splitSequence(u8, user_input, " ");
        const rawCommand = iter.next().?;
        const nullishCommand = parseCommand(rawCommand);

        if (nullishCommand == null) {
            try stdout.print("{s}: not found\n", .{rawCommand});
        } else {
            switch (nullishCommand.?) {
                .exit => {
                    const exitCode = std.fmt.parseInt(u8, iter.next().?, 10) catch 0;
                    std.process.exit(exitCode);
                },
                .echo => {
                    try stdout.print("{s}\n", .{iter.rest()});
                },
                .type => {
                    const typeArg = iter.next().?;
                    const optionalCommandFound = parseCommand(typeArg);

                    if (optionalCommandFound != null) {
                        try stdout.print("{s} is a shell builtin\n", .{typeArg});
                    } else {
                        const envPaths = std.posix.getenv("PATH") orelse "/foo:/bar";

                        var pathIter = std.mem.splitSequence(u8, envPaths, ":");

                        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
                        const allocator = arena.allocator();
                        arena.deinit();

                        var isFound = false;

                        path: while (pathIter.next()) |path| {
                            const binaryPath = try std.mem.concat(allocator, u8, &[_][]const u8{ path, "/", typeArg });

                            std.fs.cwd().access(binaryPath, .{ .mode = .read_only }) catch |err| {
                                if (err == error.FileNotFound) {
                                    continue :path;
                                }
                            };

                            try stdout.print("{s} is {s}\n", .{ typeArg, binaryPath });
                            isFound = true;
                            break :path;
                        }
                        if (!isFound) {
                            try stdout.print("{s}: not found\n", .{typeArg});
                        }
                    }
                },
            }
        }
    }
}
