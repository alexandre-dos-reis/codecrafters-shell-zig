const std = @import("std");
const c = @cImport({
    @cInclude("sys/ioctl.h");
    @cInclude("pty.h");
});
const types = @import("./types.zig");
const constants = @import("./constant.zig");

var initialTermios: c.termios = undefined;
var termios: c.termios = undefined;

/// Restore terminal to default settings.
pub fn restoreConfigToDefault() void {
    if (c.tcsetattr(constants.FD_T, c.TCSANOW, &initialTermios) != 0) {
        std.log.debug(
            "Error restoring terminal to it's default state, terminal might be broken !, Please exit the current session.",
            .{},
        );
    }
}

// TODO: Handle other platforms
/// Restore terminal to default settings.
pub fn setConfig() void {
    // https://linux.die.net/man/3/tcgetattr
    // https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html#a-timeout-for-read
    // https://github.com/ziglang/zig/issues/10181
    _ = c.tcgetattr(constants.FD_T, &initialTermios);
    termios = initialTermios;
    // Manipulate terminal
    // Turn off canonical mode => Read char byte by byte instead of line by line
    termios.c_lflag &= ~@as(@TypeOf(termios.c_lflag), c.ICANON);
    // Turn off echo mode => as we want to manipulate each render.
    termios.c_lflag &= ~@as(@TypeOf(termios.c_lflag), c.ECHO);
    // turn off blocking on input
    termios.c_cc[c.VMIN] = 0;
    termios.c_cc[c.VTIME] = 0;

    if (c.tcsetattr(constants.FD_T, c.TCSANOW, &termios) != 0) {
        std.log.debug(
            "Error setting terminal state, this is mandatory for the shell to run properly !",
            .{},
        );
    }
}

// pub fn printPrompt(stdout: types.StdOut) !void {
//     try stdout.print(constants.LEFT_PROMPT, .{});
// }
