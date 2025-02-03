const std = @import("std");
const types = @import("./types.zig");
const render = @import("./render.zig").render;

const ESC = "\x1B";
const CSI = ESC ++ "[";

// TERMINAL
// Focus is an escape sequence to notify the terminal that it has focus.
const focus = CSI ++ "I";
// Blur is an escape sequence to notify the terminal that it has lost focus.
const blur = CSI ++ "O";

// CLEAR
pub const clearCurrentLine = CSI ++ "2K";
pub const clearFromCursorToLineBeginning = CSI ++ "1K";
pub const clearFromCursorToLineEnd = CSI ++ "K";
pub const clearScreen = CSI ++ "2J";
pub const clearFromCursorToScreenBeginning = CSI ++ "1J";
pub const clearFromCursorToScreenEnd = CSI ++ "J";

// CURSOR
pub const hideCursor = CSI ++ "?25l";
pub const showCursor = CSI ++ "?25h";
pub const moveCursorToBeginning = CSI ++ "0G";
pub const moveCursorToHomePosition = CSI ++ "H";
pub fn moveCursorTo(line: u16, column: u16) []u8 {
    var buffer: [10]u8 = undefined;
    return std.fmt.bufPrint(&buffer, CSI ++ "{d};{d}H", .{ line, column }) catch unreachable;
}
