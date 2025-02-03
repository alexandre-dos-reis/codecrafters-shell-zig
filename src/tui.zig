const std = @import("std");
const reader = @import("./reader.zig");
const tty = @import("./terminal.zig");
const Chan = @import("./channel.zig").Chan;

const Msg = union(enum) { Increment, Decrement, Quit, Tick, UpdateTime };

const MsgChannel = Chan(Msg);

pub const Model = struct {
    count: i32,
    time: [9]u8, // HH:MM:SS format
    lock: std.Thread.Mutex, // Protection pour accès concurrentiel
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
        else => {},
    }
}

fn renderView(model: *Model) void {
    // model.lock.lock();
    // defer model.lock.unlock();

    std.debug.print("\x1b[2J\x1b[H", .{}); // Effacer l’écran
    std.debug.print("Heure: {s}\n\r", .{getTime()});
    std.debug.print("Compteur: {}\n\r", .{model.count});
    std.debug.print("[↑] +1 | [↓] -1 | [q] Quitter\n\r", .{});
}

fn inputListener(channel: *MsgChannel) !void {
    while (true) {
        const key = try reader.readInput();
        switch (key.type) {
            .character => {
                if (key.value) |value| {
                    switch (value) {
                        'q' => {
                            try channel.send(.Quit);
                            break;
                        },
                        else => {},
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

    var model = Model{ .count = 0, .time = getTime(), .lock = .{} };

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
