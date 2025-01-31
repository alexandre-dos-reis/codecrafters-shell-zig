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
/// Configure Terminal to raw mode, see `man termios` and `cfmakeraw`.
pub fn setRawMode() void {
    // https://linux.die.net/man/3/tcgetattr
    // https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html#a-timeout-for-read
    // https://github.com/ziglang/zig/issues/10181
    _ = c.tcgetattr(constants.FD_T, &initialTermios);
    termios = initialTermios;

    termios.c_lflag &= ~@as(@TypeOf(termios.c_lflag),
    //
    (c.ICANON // Turn off canonical mode => Read char byte by byte instead of line by line
    | c.ECHO // Turn off echo mode => as we want to manipulate each render.
    | c.ECHONL // TODO: document
    | c.ISIG // TODO: document
    | c.IEXTEN // TODO document
    ));

    termios.c_oflag &= ~@as(@TypeOf(termios.c_oflag),
    // TODO: document
    c.OPOST);

    termios.c_iflag &= ~@as(@TypeOf(termios.c_iflag),
    // TODO document
    (c.IGNBRK | c.BRKINT | c.PARMRK | c.ISTRIP | c.INLCR | c.IGNCR | c.ICRNL | c.IXON));

    termios.c_cflag &= ~@as(@TypeOf(termios.c_cflag), (c.CSIZE | c.PARENB));

    termios.c_cflag |= ~@as(@TypeOf(termios.c_cflag), c.CS8);

    // turn off blocking on input
    termios.c_cc[c.VMIN] = 1;
    termios.c_cc[c.VTIME] = 0;

    if (c.tcsetattr(constants.FD_T, c.TCSANOW, &termios) != 0) {
        std.log.debug(
            "Error setting terminal state, this is mandatory for the shell to run properly !",
            .{},
        );
    }
}
