const std = @import("std");
const terminal = @import("./terminal.zig");
const reader = @import("./reader.zig");
const command = @import("./command.zig");
const cursor = @import("./cursor.zig");
const escapeSeq = @import("./escape-sequence.zig");
const types = @import("./types.zig");
const render = @import("./render.zig");
const constants = @import("constant.zig");
const ansi = @import("./ansi.zig");
const Renderer = @import("./Renderer.zig");

pub fn main() !void {
    terminal.setRawMode();

    // try terminal.printPrompt(&stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var bufferInput = std.ArrayList(u8).init(gpa.allocator());
    defer bufferInput.deinit();

    var renderer = Renderer{};
    try renderer.init();

    var b: [40]u8 = undefined;

    for (0..11) |i| {
        const remaining = 10 - i;

        const output = try std.fmt.bufPrint(&b, "\x1b[1;33mCountdown: {d} seconds\x1b[0m\r", .{remaining});
        // Print countdown number
        try renderer.print(output);

        // Sleep for 1 second
        std.time.sleep(1_000_000_000);
    }

    // const line1 = "line1";
    // const line2 = "line2";
    // const line3 = "line3";

    // while (true) {
    //     // Milliseconds <= Nanoseconds
    //     const timeInMs = Timer.read(&timer) / 1_000_000;
    //
    //     if (timeInMs >= 1000 / 120) {
    //         _ = timer.lap();
    //         // const fps = 1000 / timeInMs;
    //         // std.log.debug("fps: {any}\r", .{fps});
    //
    //     }
    //     // const key = try reader.readInput();
    //     // std.log.debug("{any}", .{key});
    //     // try render.renderCharacter(key.value.?);
    //     // switch (key.type) {
    //     //     else => {},
    //     //     .character, .space => {
    //     //         try render.renderCharacter(key.value.?);
    //     //         try bufferInput.insert(cursor.getRelativePosition(), key.value.?);
    //     //         cursor.incrementPosition();
    //     //         // try render.renderBufferRest(&bufferInput);
    //     //     },
    //     //     .escape => try render.render("esc"),
    //     //     .tabulation => try render.render("tab"),
    //     //     .backspace => {
    //     //         try render.renderCharacter(key.value.?);
    //     //         if (bufferInput.items.len > 0) {
    //     //             try render.renderBackspace();
    //     //             cursor.decrementPosition();
    //     //             _ = bufferInput.orderedRemove(cursor.getRelativePosition());
    //     //             // try render.renderBufferRest(&bufferInput);
    //     //         }
    //     //     },
    //     //     .up, .down => {
    //     //         try render.render("arrow");
    //     //     },
    //     //     .left => switch (key.mod) {
    //     //         .none => {
    //     //             if (bufferInput.items.len > 0) {
    //     //                 try cursor.moveBackward();
    //     //             }
    //     //         },
    //     //         .ctrl => try cursor.moveCursorToPrevious1stWordLetter(&bufferInput),
    //     //         .alt => {},
    //     //     },
    //     //     .right => switch (key.mod) {
    //     //         .none => {
    //     //             if (cursor.getRelativePosition() < bufferInput.items.len) {
    //     //                 try cursor.moveForward();
    //     //             }
    //     //         },
    //     //         .ctrl => try cursor.moveCursorToNextSpaceChar(&bufferInput),
    //     //         .alt => {},
    //     //     },
    //     //     .enter => {
    //     //         // display `enter` character
    //     //         try render.renderCharacter(key.value.?);
    //     //         try command.run(&bufferInput.items);
    //     //         try bufferInput.resize(0);
    //     //         cursor.resetToInitalPosition();
    //     //         try escapeSeq.moveCursorToBeginning();
    //     //     },
    //     // }
    // }
}
