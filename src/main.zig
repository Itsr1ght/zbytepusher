// window config
const WIDTH = 256;
const HEIGHT = 256;
const VIDEO_BUFF_SIZE = WIDTH * HEIGHT;
const TITLE: [:0]const u8 = "Hello BytePusher";
const FPS = 60;

// VM config
const MEMORY_SIZE = 0x1000008;
const KEY_MEM_SIZE = 16;
const COLOR_STEP = 0x33;
const COLOR_BLACK: rl.Color = .{ .r = 0, .b = 0, .g = 0, .a = 255 };

var memory: [MEMORY_SIZE]u8 = undefined;
var keyMem: [KEY_MEM_SIZE]u8 = undefined;
var videoBuff: [VIDEO_BUFF_SIZE]u8 = undefined;

const color_map = initColorMap();

fn initColorMap() [256]rl.Color {
    var c: [256]rl.Color = undefined;
    for (0..6) |r| for (0..6) |g| for (0..6) |b| {
        c[r * 36 + g * 6 + b] = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    };
    @memset(c[216..], COLOR_BLACK);
    return c;
}

fn init() void {}

fn update() void {
    for (0..65535) |_| {}
}

fn draw() void {
    rl.beginDrawing();
    defer rl.endDrawing();
}

pub fn main() !void {
    rl.initWindow(WIDTH, HEIGHT, TITLE);
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        update();
        draw();
    }
}

const std = @import("std");
const rl = @import("raylib");
