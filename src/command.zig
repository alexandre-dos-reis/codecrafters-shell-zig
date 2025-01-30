const std = @import("std");
const terminal = @import("./terminal.zig");
const types = @import("./types.zig");
const render = @import("./render.zig");

const BuiltinCommand = enum { exit, echo, type };

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

pub fn run(input: *[]u8) !void {
    // avoid empty string or whitespaces string
    if (input.*.len == 0 or std.mem.trim(u8, input.*, " ").len == 0) {
        return;
    }

    // std.log.debug("input: \"{s}\"", .{input.*});
    // return;

    var iter = std.mem.splitSequence(u8, input.*, " ");

    const rawCommand = iter.next().?;

    // Builtins commands
    if (std.meta.stringToEnum(BuiltinCommand, rawCommand)) |command| {
        switch (command) {
            .exit => {
                const exitCode = std.fmt.parseInt(u8, iter.next() orelse "0", 10) catch 0;
                terminal.restoreConfigToDefault();
                std.process.exit(exitCode);
            },
            .echo => {
                try render.stdout.print("{s}\n", .{iter.rest()});
            },
            .type => {
                const typeArg = iter.next().?;

                if (std.meta.stringToEnum(BuiltinCommand, typeArg)) |_| {
                    try render.stdout.print("{s} is a shell builtin\n", .{typeArg});
                } else {
                    if (findExecutablePathFor(typeArg)) |path| {
                        try render.stdout.print("{s} is {s}\n", .{ typeArg, path });
                    } else {
                        try render.stdout.print("{s}: not found\n", .{typeArg});
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

            // Restore termios default config to avoid weird behaviors with other programs
            terminal.restoreConfigToDefault();
            // Run child process
            var childProcess = std.process.Child.init(args.items, std.heap.page_allocator);
            _ = try childProcess.spawnAndWait();
            // Reapply termios config
            terminal.setConfig();
        } else {
            try render.stdout.print("{s}: command not found\n", .{rawCommand});
        }
    }
}
