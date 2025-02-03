const std = @import("std");
const reader = @import("./reader.zig");
const tty = @import("./terminal.zig");
const Chan = @import("./channel.zig").Chan;
const render = @import("./render.zig").render;
const printFormat = @import("./render.zig").printFormat;
const ansi = @import("./ansi.zig");

const Msg = union(enum) { Increment, Decrement, Quit, Tick, UpdateTime };

const MsgChannel = Chan(Msg);

pub const Model = struct {
    count: i32,
    time: [9]u8, // HH:MM:SS format
    lock: std.Thread.Mutex, // Protection pour accès concurrentiel
    lastUpdateTimestamp: i64, // last tick
};
// --- Fonction pour récupérer l'heure actuelle ---
fn getTime() [9]u8 {
    var buf: [9]u8 = undefined;
    const timestamp = @as(i64, @intCast(std.time.timestamp()));
    const secs = @rem(timestamp, 60);
    const mins = @rem((@divFloor(timestamp, 60)), 60);
    const hours = @rem((@divFloor(timestamp, 3600)), 24);
    _ = std.fmt.bufPrint(&buf, "{d}:{d}:{d}", .{ hours, mins, secs }) catch "00:00:00";
    return buf;
}

fn update(model: *Model, msg: Msg) void {
    model.lock.lock();
    defer model.lock.unlock();

    switch (msg) {
        .Increment => model.count += 1,
        .Decrement => model.count -= 1,
        .UpdateTime => model.time = getTime(),
        .Tick => model.lastUpdateTimestamp = std.time.milliTimestamp(),
        else => {},
    }
}

fn toggleCursor(msToggleBlink: u16) void {
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

    printFormat("Heure: {s}\n\r", .{getTime()});
    printFormat("Compteur: {}\n\r", .{model.count});
    printFormat("[↑] +1 | [↓] -1 | [q] Quitter\n\r", .{});

    toggleCursor(500);
}

fn inputListener(channel: *MsgChannel) !void {
    while (true) {
        const key = try reader.readKey();
        switch (key.type) {
            .character => {
                if (key.value) |value| {
                    if (value == 'q' or (value == 'c' and key.mod == .ctrl)) {
                        try channel.send(.Quit);
                        break;
                    }
                }
            },
            .up => try channel.send(.Increment),
            .down => try channel.send(.Decrement),
            else => {},
        }
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

    var model = Model{
        .count = 0,
        .time = getTime(),
        .lock = .{},
        .lastUpdateTimestamp = std.time.milliTimestamp(),
    };

    // Démarrer les threads d’entrée et de rendu
    var input_t = try std.Thread.spawn(.{}, inputListener, .{&channel});
    var render_loop_t = try std.Thread.spawn(.{}, renderLoop, .{ &model, &channel });

    defer input_t.detach();
    defer render_loop_t.detach();

    while (true) {
        const msg = try channel.recv();

        if (msg == .Quit) break;
        update(&model, msg); // Mise à jour du modèle avec les messages reçus
    }
}

// --- 8. Exécution ---
pub fn main() !void {
    try tty.setRawMode();
    try run();
    try tty.restoreConfigToDefault();
}
