const std = @import("std");
const types = @import("./types.zig");
const render = @import("./render.zig").render;
const CSI = @import("./constant.zig").CSI;

pub fn clearCurrentLine() !void {
    try render(CSI ++ "2K");
}

pub fn clearFromCursorToLineBeginning() !void {
    try render(CSI ++ "1K");
}

pub fn moveCursorToBeginning() !void {
    try render(CSI ++ "1D");
}

pub fn clearFromCursorToLineEnd() !void {
    try render(CSI ++ "K");
}

pub fn clearScreen() !void {
    try render(CSI ++ "2J");
}

pub fn clearFromCursorToScreenBeginning() !void {
    try render(CSI ++ "1J");
}

pub fn clearFromCursorToScreenEnd() !void {
    try render(CSI ++ "J");
}
