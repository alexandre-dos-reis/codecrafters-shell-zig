const std = @import("std");
const types = @import("./types.zig");

pub const esc = "\x1B";
const csi = esc ++ "[";

pub fn clearCurrentLine(stdOut: types.StdOut) !void {
    try stdOut.writeAll(csi ++ "2K");
}

pub fn clearFromCursorToLineBeginning(stdOut: types.StdOut) !void {
    try stdOut.writeAll(csi ++ "1K");
}

pub fn moveCursorToBeginning(stdOut: types.StdOut) !void {
    try stdOut.writeAll(csi ++ "1D");
}

pub fn clearFromCursorToLineEnd(stdOut: types.StdOut) !void {
    try stdOut.writeAll(csi ++ "K");
}

pub fn clearScreen(stdOut: types.StdOut) !void {
    try stdOut.writeAll(csi ++ "2J");
}

pub fn clearFromCursorToScreenBeginning(stdOut: types.StdOut) !void {
    try stdOut.writeAll(csi ++ "1J");
}

pub fn clearFromCursorToScreenEnd(stdOut: types.StdOut) !void {
    try stdOut.writeAll(csi ++ "J");
}
