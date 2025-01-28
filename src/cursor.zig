const std = @import("std");
const types = @import("./types.zig");
const constants = @import("./constant.zig");
const c = @cImport({
    @cInclude("sys/ioctl.h");
    @cInclude("unistd.h");
    @cInclude("termios.h");
});

pub fn getWinsize() ?c.winsize {
    var winsize: c.winsize = undefined;
    if (c.ioctl(constants.FD_T, c.TIOCGWINSZ, &winsize) != 0) {
        return null;
    }
    return winsize;
}

var cursorPositionX: u8 = 0;
var cursorPositionY: u8 = 0;

pub fn moveForward(stdout: types.StdOut, doPrint: bool) !void {
    if (getWinsize()) |winsize| {
        // TODO: add constraints here from inputBuffer
        // End of line
        if (winsize.ws_col == cursorPositionX) {
            if (doPrint) {
                try stdout.writeAll(constants.CSI ++ "E");
            }
            cursorPositionX = 0;
            cursorPositionY += 1;
        } else {
            if (doPrint) {
                try stdout.writeAll(constants.CSI ++ "1C");
            }
            cursorPositionX += 1;
        }
    }
}
//
pub fn moveBackward(stdout: types.StdOut, doPrint: bool) !void {
    if (getWinsize()) |winsize| {
        // Start of line
        if (cursorPositionX == 0) {
            cursorPositionX = @intCast(winsize.ws_col);
            cursorPositionY -= 1;
        } else {
            cursorPositionX -= 1;
        }
    }
    if (doPrint) {
        try stdout.writeByte(8);
    }
}
//
pub fn resetToInitalPosition() void {
    cursorPositionX = 0;
    cursorPositionY = 0;
}

pub fn getPositionX() u8 {
    return cursorPositionX;
}

pub fn getPositionY() u8 {
    return cursorPositionX;
}
