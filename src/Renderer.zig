const std = @import("std");
const ansi = @import("./ansi.zig");
const Timer = std.time.Timer;
const render = @import("./render.zig");

const Renderer = @This();

timer: ?Timer = null,

pub fn init(self: *Renderer) !void {
    self.timer = try Timer.start();

    try ansi.hideCursor();
}

pub fn print(self: *Renderer, line: []const u8) !void {
    while (true) {
        // Milliseconds <= Nanoseconds
        const timeInMs = self.timer.?.read() / 1_000_000;

        if (timeInMs >= 1000 / 120) {
            _ = self.timer.?.lap();
            try render.render(line);
            // const fps = 1000 / timeInMs;
            // std.log.debug("fps: {any}\r", .{fps});
            break;
        }
    }
}
