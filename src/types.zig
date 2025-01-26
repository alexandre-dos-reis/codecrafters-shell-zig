const std = @import("std");

pub const StdIn = @TypeOf(&std.io.getStdIn().reader());
pub const StdOut = @TypeOf(&std.io.getStdOut().writer());
