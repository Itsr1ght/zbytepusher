pub fn main() !void {
    rl.initWindow(1080, 720, "Hello World");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.gray);
    }
    std.debug.print("Hello Raylib", .{});
}

const std = @import("std");
const rl = @import("raylib");
