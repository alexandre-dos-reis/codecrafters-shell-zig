const std = @import("std");
const reader = @import("./reader.zig");
const tty = @import("./terminal.zig");
const Chan = @import("./channel.zig").Chan;

const Msg = union(enum) { Increment, Decrement, Quit, Tick };

const MsgChannel = Chan(Msg);

pub const Model = struct {
    count: i32,
    lock: std.Thread.Mutex, // Protection pour accès concurrentiel
};

fn updateModel(model: *Model, msg: Msg) void {
    model.lock.lock();
    defer model.lock.unlock();

    switch (msg) {
        .Increment => model.count += 1,
        .Decrement => model.count -= 1,
        else => {},
    }
}

fn renderView(model: *Model) void {
    // model.lock.lock();
    // defer model.lock.unlock();

    std.debug.print("\x1b[2J\x1b[H", .{}); // Effacer l’écran
    std.debug.print("Compteur: {}\n", .{model.count});
    std.debug.print("[↑] +1 | [↓] -1 | [q] Quitter\n", .{});
}

fn inputListener(channel: *MsgChannel) !void {
    while (true) {
        const key = try reader.readInput();
        switch (key.type) {
            .quit => try channel.send(.Quit),
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

    var model = Model{ .count = 0, .lock = .{} };

    // Démarrer les threads d’entrée et de rendu
    var input_t = try std.Thread.spawn(.{}, inputListener, .{&channel});
    var render_loop_t = try std.Thread.spawn(.{}, renderLoop, .{ &model, &channel });

    defer input_t.join();
    defer render_loop_t.join();

    while (true) {
        const msg = try channel.recv();

        if (msg == .Quit) break;
        updateModel(&model, msg); // Mise à jour du modèle avec les messages reçus
    }
}

// --- 8. Exécution ---
pub fn main() !void {
    try tty.setRawMode();
    try run();
    try tty.restoreConfigToDefault();
}
