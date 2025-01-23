const std = @import("std");

pub fn setup() !void {
    // Resources
    // https://linux.die.net/man/3/tcgetattr
    // https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html#a-timeout-for-read
    // https://github.com/ziglang/zig/issues/10181
    const termios = std.posix.tcgetattr(std.c.STDOUT_FILENO) catch {
        return error.TcGetAttrFailed;
    };
    var t = termios;
    // Manipulate terminal
    // Turn off canonical mode => Read char byte by byte instead of line by line term.lflag.ICANON = false;
    t.lflag.ICANON = false;
    // Turn off echo mode => as we want to manipulate each render.
    t.lflag.ECHO = false;
    // turn off blocking on input
    // TODO: Handle other platforms
    t.cc[@intFromEnum(std.os.linux.V.MIN)] = 0;
    t.cc[@intFromEnum(std.os.linux.V.TIME)] = 0;

    std.posix.tcsetattr(std.c.STDOUT_FILENO, std.c.TCSA.NOW, t) catch {
        return error.TcSetAttrFailed;
    };
}

pub fn printPrompt(stdout: anytype) !void {
    try stdout.print("$ ", .{});
}
