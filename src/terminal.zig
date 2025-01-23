const std = @import("std");

pub fn setup() !void {
    // Manipulate terminal
    const fd_t: i32 = 0;
    var term = try std.posix.tcgetattr(fd_t);
    // Turn off canonical mode => Read char byte by byte instead of line by line
    term.lflag.ICANON = false;
    // Turn off echo mode => as we want to manipulate each render.
    term.lflag.ECHO = false;
    try std.posix.tcsetattr(fd_t, .NOW, term);
}
