const std = @import("std");
const types = @import("./types.zig");
const constants = @import("./constant.zig");

/// TODO: listen to resize handler and to adjust the value
pub fn getWindowCols() u16 {
    var ws: std.posix.winsize = undefined;
    if (std.os.linux.ioctl(constants.FD_T, std.os.linux.T.IOCGWINSZ, @intFromPtr(&ws)) != 0) {
        return 0;
    }
    return ws.ws_col;
}

var cursorPositionX: u16 = 0;
var cursorPositionY: u16 = 0;

/// Convert the x and y position to an integer, usefull to compare against the buffer input length
pub fn getCursorPosition() usize {
    return cursorPositionY * getWindowCols() + cursorPositionX;
}

pub fn moveForward(stdout: types.StdOut, inputLen: usize) !void {
    if (getCursorPosition() < inputLen) {
        if (getWindowCols() == cursorPositionX) {
            try stdout.writeAll(constants.CSI ++ "E");
        } else {
            try stdout.writeAll(constants.CSI ++ "1C");
        }
        incrementPosition();
    }
}

pub fn moveBackward(stdout: types.StdOut, inputLen: usize) !void {
    if (inputLen > 0) {
        try stdout.writeByte(8);
        decrementPosition();
    }
}

pub fn decrementPosition() void {
    if (cursorPositionX == 0) {
        cursorPositionX = getWindowCols();
        cursorPositionY -= 1;
    } else {
        cursorPositionX -= 1;
    }
}

pub fn incrementPosition() void {
    // End of line
    if (getWindowCols() == cursorPositionX) {
        cursorPositionX = 0;
        cursorPositionY += 1;
    } else {
        cursorPositionX += 1;
    }
}

pub fn resetToInitalPosition() void {
    cursorPositionX = 0;
    cursorPositionY = 0;
}

pub fn getPositionX() u16 {
    return cursorPositionX;
}

pub fn getPositionY() u16 {
    return cursorPositionY;
}
