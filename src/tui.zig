const std = @import("std");
const reader = @import("./reader.zig");
const tty = @import("./terminal.zig");
const Chan = @import("./channel.zig").Chan;
const render = @import("./render.zig").render;
const printFormat = @import("./render.zig").printFormat;
const ansi = @import("./ansi.zig");
const KeyType = @import("./reader.zig").Key;
const time = @import("./time.zig");

const Msg = union(enum) { Key: KeyType, Quit, Tick };

const MsgChannel = Chan(Msg);

const BufferInput = std.ArrayListAligned(u8, null);

pub const Model = struct {
    const Self = @This();
    // Protection for concurrent access
    mutex: std.Thread.Mutex = .{},

    // counter
    count: i32 = 0,

    // last tick timestamp
    lastUpdateTimestamp: i64,

    // main input
    cursorLocation: u16,
    bufferInput: *BufferInput,
};

fn update(model: *Model, msg: Msg) !void {
    model.mutex.lock();
    defer model.mutex.unlock();

    switch (msg) {
        .Tick => model.lastUpdateTimestamp = time.getTickTimestamp(),
        .Key => |k| {
            switch (k.type) {
                else => {},
                .character, .space => {
                    if (k.value) |value| {
                        try model.bufferInput.insert(model.cursorLocation, value);
                        model.cursorLocation += 1;
                    }
                },
                .backspace => {
                    if (model.bufferInput.items.len > 0) {
                        model.cursorLocation -= 1;
                        _ = model.bufferInput.orderedRemove(model.cursorLocation);
                    }
                },
                .left => {
                    if (model.cursorLocation > 0) {
                        model.cursorLocation -= 1;
                    }
                },
                .right => {
                    if (model.cursorLocation < model.bufferInput.items.len) {
                        model.cursorLocation += 1;
                    }
                },
                .up => model.count += 1,
                .down => model.count -= 1,
            }
        },
        else => {},
    }
}

fn toggleCursor(msToggleBlink: u10) void {
    const now = std.time.milliTimestamp();

    if (@rem(@divFloor(now, msToggleBlink), 2) == 0) {
        render(ansi.showCursor);
    } else {
        render(ansi.hideCursor);
    }
}

fn renderView(model: *Model) void {
    // Don't modify model but only consumed it.

    render(ansi.clearScreen);
    render(ansi.moveCursorTo(0, 0));
    // toggleCursor(550);

    printFormat("Heure: {s}\n\r", .{time.getcurrentReadableTime()});
    printFormat("Compteur: {}\n\r", .{model.count});
    printFormat("[↑] +1 | [↓] -1 | [q] Quitter\n\r", .{});
    render(model.bufferInput.items);
}

fn inputListener(channel: *MsgChannel) !void {
    while (true) {
        const key = try reader.readKey();

        if (key.value) |value| {
            if (value == 'q' or (value == 'c' and key.mod == .ctrl)) {
                try channel.send(.Quit);
                return;
            }
        }

        try channel.send(.{ .Key = key });
    }
}

fn renderLoop(model: *Model, channel: *MsgChannel) !void {
    while (true) {
        std.time.sleep(16_000_000); // Rafraîchir toutes les 16ms | 60 fps

        // Rafraîchir l'affichage avec la barre de progression
        renderView(model);

        // Envoyer le message Tick pour la mise à jour de l'affichage
        try channel.send(.Tick);
    }
}

// --- 7. Boucle principale ---
fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var channel = MsgChannel.init(allocator);
    defer channel.deinit();

    var bufferInput = std.ArrayList(u8).init(allocator);
    defer bufferInput.deinit();

    var model = Model{
        .count = 0,
        .lastUpdateTimestamp = time.getTickTimestamp(),
        .bufferInput = &bufferInput,
        .cursorLocation = 0,
    };

    // Démarrer les threads d’entrée et de rendu
    var input_t = try std.Thread.spawn(.{}, inputListener, .{&channel});
    var render_loop_t = try std.Thread.spawn(.{}, renderLoop, .{ &model, &channel });

    defer input_t.detach();
    defer render_loop_t.detach();

    while (true) {
        const msg = try channel.recv();

        if (msg == .Quit) break;
        try update(&model, msg); // Mise à jour du modèle avec les messages reçus
    }
}

// --- 8. Exécution ---
pub fn main() !void {
    try tty.setRawMode();
    defer tty.restoreConfigToDefault() catch unreachable;
    errdefer tty.restoreConfigToDefault() catch unreachable;

    try run();
}
