const std = @import("std");

const Command = enum { exit, echo, type };

fn findExecutablePathFor(externalCommand: []const u8) ?[]const u8 {
    const envPaths = std.posix.getenv("PATH");

    if (envPaths == null) {
        return null;
    }

    var pathIter = std.mem.splitSequence(u8, envPaths.?, ":");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    arena.deinit();

    while (pathIter.next()) |path| {
        const binaryPath = std.fs.path.join(allocator, &[_][]const u8{ path, externalCommand }) catch continue;

        std.fs.cwd().access(binaryPath, .{ .mode = .read_only }) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return null,
        };

        return binaryPath;
    }
    return null;
}

pub fn run(input: []u8, stdout: anytype) !void {
    var iter = std.mem.splitSequence(u8, input, " ");
    const rawCommand = iter.next().?;

    // Builtins commands
    if (std.meta.stringToEnum(Command, rawCommand)) |command| {
        switch (command) {
            .exit => {
                const exitCode = std.fmt.parseInt(u8, iter.next().?, 10) catch 0;
                std.process.exit(exitCode);
            },
            .echo => {
                try stdout.print("{s}\n", .{iter.rest()});
            },
            .type => {
                const typeArg = iter.next().?;

                if (std.meta.stringToEnum(Command, typeArg)) |_| {
                    try stdout.print("{s} is a shell builtin\n", .{typeArg});
                } else {
                    if (findExecutablePathFor(typeArg)) |path| {
                        try stdout.print("{s} is {s}\n", .{ typeArg, path });
                    } else {
                        try stdout.print("{s}: not found\n", .{typeArg});
                    }
                }
            },
        }
        // External commands
    } else {
        if (findExecutablePathFor(rawCommand)) |path| {
            var args = std.ArrayList([]const u8).init(std.heap.page_allocator);
            defer args.deinit();

            try args.append(path);

            while (iter.next()) |arg| {
                try args.append(arg);
            }
            var childProcess = std.process.Child.init(args.items, std.heap.page_allocator);
            _ = try childProcess.spawnAndWait();
        } else {
            try stdout.print("{s}: command not found\n", .{rawCommand});
        }
    }
}
