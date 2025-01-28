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

/// Convert the x and y position to an integer, usefull to compare against the buffer input length
pub fn getCurrentLen() ?usize {
    if (getWinsize()) |ws| {
        const col: usize = @intCast(ws.ws_col);
        return cursorPositionY * col + cursorPositionX;
    }
    return null;
}

pub fn moveForward(stdout: types.StdOut, inputLen: usize) !void {
    if (getCurrentLen()) |limit| {
        if (limit < inputLen) {
            if (getWinsize().?.ws_col == cursorPositionX) {
                try stdout.writeAll(constants.CSI ++ "E");
            } else {
                try stdout.writeAll(constants.CSI ++ "1C");
            }
            increment();
        }
    }
}

pub fn moveBackward(stdout: types.StdOut, inputLen: usize) !void {
    if (inputLen > 0) {
        try stdout.writeByte(8);
        decrement();
    }
}

pub fn decrement() void {
    if (getWinsize()) |winsize| {
        // Start of line
        if (cursorPositionX == 0) {
            cursorPositionX = @intCast(winsize.ws_col);
            cursorPositionY -= 1;
        } else {
            cursorPositionX -= 1;
        }
    }
}

pub fn increment() void {
    if (getWinsize()) |winsize| {
        // End of line
        if (winsize.ws_col == cursorPositionX) {
            cursorPositionX = 0;
            cursorPositionY += 1;
        } else {
            cursorPositionX += 1;
        }
    }
}

pub fn resetToInitalPosition() void {
    cursorPositionX = 0;
    cursorPositionY = 0;
}

pub fn getPositionX() u8 {
    return cursorPositionX;
}

pub fn getPositionY() u8 {
    return cursorPositionY;
}

pub fn incrementX() void {
    cursorPositionX += 1;
}
