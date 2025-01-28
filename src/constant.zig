const std = @import("std");

// ANSI escape code standard
pub const ESC = "\x1B";
pub const CSI = ESC ++ "[";

// File descriptor for standard output
pub const FD_T: std.posix.fd_t = 0;

pub const LEFT_PROMPT = "$ ";
