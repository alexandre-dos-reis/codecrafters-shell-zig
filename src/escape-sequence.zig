const std = @import("std");
const types = @import("./types.zig");
const render = @import("./render.zig");
const CSI = @import("./constant.zig").CSI;

pub fn clearCurrentLine() !void {
    try render.render(CSI ++ "2K");
}

pub fn clearFromCursorToLineBeginning() !void {
    try render.render(CSI ++ "1K");
}

pub fn moveCursorToBeginning() !void {
    try render.render(CSI ++ "1D");
}

pub fn clearFromCursorToLineEnd() !void {
    try render.render(CSI ++ "K");
}

pub fn clearScreen() !void {
    try render.render(CSI ++ "2J");
}

pub fn clearFromCursorToScreenBeginning() !void {
    try render.render(CSI ++ "1J");
}

pub fn clearFromCursorToScreenEnd() !void {
    try render.render(CSI ++ "J");
}
