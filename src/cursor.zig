const std = @import("std");
const types = @import("./types.zig");
const constants = @import("./constant.zig");
const render = @import("./render.zig");

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
pub fn getRelativePosition() usize {
    return cursorPositionY * getWindowCols() + cursorPositionX;
}

pub fn moveForward() !void {
    if (getWindowCols() == cursorPositionX) {
        try render.render(constants.CSI ++ "E");
    } else {
        try render.render(constants.CSI ++ "1C");
    }
    incrementPosition();
}

pub fn moveBackward() !void {
    if (getRelativePosition() > 0) {
        try render.stdout.writeByte(8);
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

pub fn moveCursorToNextSpaceChar(input: *std.ArrayList(u8)) !void {
    var cursorPos = getRelativePosition();
    const bufferInput = input.*;
    const limit = bufferInput.items.len;

    if (cursorPos < limit) {
        const spaceCharSlice = " ";
        const spaceChar = spaceCharSlice[0];

        // handle case where are already on a space after a word.
        if (bufferInput.items[cursorPos + 1] == spaceChar) {
            try moveForward();
            cursorPos += 1;
        }

        while (cursorPos + 1 < limit) {
            const character = bufferInput.items[cursorPos + 1];
            if (character == spaceChar) {
                break;
            }
            cursorPos += 1;
            try moveForward();
        }
        try moveForward();
    }
}

pub fn moveCursorToPrevious1stWordLetter(input: *std.ArrayList(u8)) !void {
    const bufferInput = input.*;
    // Move cursor to first letter of previous word
    var cursorPos = getRelativePosition();
    if (cursorPos > 0) {
        const spaceCharSlice = " ";
        const spaceChar = spaceCharSlice[0];

        // Handle case if are already on a first letter
        if (bufferInput.items[cursorPos - 1] == spaceChar) {
            try moveBackward();
            cursorPos -= 1;
        }

        while (cursorPos > 0) {
            const character = bufferInput.items[cursorPos - 1];
            if (character == spaceChar) {
                break;
            }
            cursorPos -= 1;
            try moveBackward();
        }
    }
}
