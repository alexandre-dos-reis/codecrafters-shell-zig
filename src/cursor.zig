const std = @import("std");
const types = @import("./types.zig");
const constants = @import("./constant.zig");
const render = @import("./render.zig").render;
const ansi = @import("ansi.zig");

pub const Cursor = struct {
    position: u16 = 0,
    charUnderCursor: []const u8 = " ",
    // cursorChar: []const u8 = "_",
    // yPos: u16 = 0,
    // windowColumns: u16 = 0,

    // pub fn getRelativePosition(self: *Self) u16 {
    //     return self.yPos * self.windowColumns + self.xPos;
    // }
    //
    // pub fn getAbsolutePosition(self: *Self) u16 {
    //     return self.yPos * self.windowColumns + self.xPos;
    // }
    //
    // pub fn incrementPositionBy(self: *Self, by: u16) void {
    //     const newPos = self.getRelativePosition() + by;
    //     const windowCols = self.windowColumns;
    //     self.yPos = (newPos / windowCols);
    //     self.xPos = (newPos % windowCols);
    // }
    //
    // pub fn decrementPositionBy(self: *Self, by: u16) void {
    //     const newPos = self.getRelativePosition() - by;
    //     const windowCols = self.windowColumns;
    //     self.yPos = (newPos / windowCols);
    //     self.xPos = (newPos % windowCols);
    // }
};

//
// pub fn moveForward() !void {
//     if (getWindowCols() == cursorPositionX) {
//         try render.render(constants.CSI ++ "E");
//     } else {
//         try render.render(constants.CSI ++ "1C");
//     }
//     incrementPosition();
// }
//
// pub fn moveBackward() !void {
//     if (getRelativePosition() > 0) {
//         try render.renderCharacter(8);
//         decrementPosition();
//     }
// }
//
// pub fn decrementPosition() void {
//     decrementPositionBy(1);
// }
//
// pub fn incrementPosition() void {
//     incrementPositionBy(1);
// }
//
// pub fn incrementPositionBy(by: u16) void {
//     const newPos = getRelativePosition() + by;
//     const windowCols = getWindowCols();
//     cursorPositionY = (newPos / windowCols);
//     cursorPositionX = (newPos % windowCols);
// }
//
// pub fn decrementPositionBy(by: u16) void {
//     const newPos = getRelativePosition() - by;
//     const windowCols = getWindowCols();
//     cursorPositionY = (newPos / windowCols);
//     cursorPositionX = (newPos % windowCols);
// }
//
// pub fn resetToInitalPosition() void {
//     cursorPositionX = 0;
//     cursorPositionY = 0;
// }
//
// pub fn moveCursorToNextSpaceChar(input: *std.ArrayList(u8)) !void {
//     var cursorPos = getRelativePosition();
//     const bufferInput = input.*;
//     const limit = bufferInput.items.len;
//
//     if (cursorPos < limit) {
//         const spaceCharSlice = " ";
//         const spaceChar = spaceCharSlice[0];
//
//         // handle case where are already on a space after a word.
//         if (bufferInput.items[cursorPos + 1] == spaceChar) {
//             try moveForward();
//             cursorPos += 1;
//         }
//
//         while (cursorPos + 1 < limit) {
//             const character = bufferInput.items[cursorPos + 1];
//             if (character == spaceChar) {
//                 break;
//             }
//             cursorPos += 1;
//             try moveForward();
//         }
//         try moveForward();
//     }
// }
//
// pub fn moveCursorToPrevious1stWordLetter(input: *std.ArrayList(u8)) !void {
//     const bufferInput = input.*;
//     // Move cursor to first letter of previous word
//     var cursorPos = getRelativePosition();
//     if (cursorPos > 0) {
//         const spaceCharSlice = " ";
//         const spaceChar = spaceCharSlice[0];
//
//         // Handle case if are already on a first letter
//         if (bufferInput.items[cursorPos - 1] == spaceChar) {
//             try moveBackward();
//             cursorPos -= 1;
//         }
//
//         while (cursorPos > 0) {
//             const character = bufferInput.items[cursorPos - 1];
//             if (character == spaceChar) {
//                 break;
//             }
//             cursorPos -= 1;
//             try moveBackward();
//         }
//     }
// }
