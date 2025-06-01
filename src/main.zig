//command line flags
const Flags = struct {
    pub const description =
        \\Simple BytePusher VM created using zig 
        \\use --file command to choose the file
    ;
    file: []const u8,
};

// window config
const WIDTH = 256;
const HEIGHT = 256;
const VIDEO_BUFF_SIZE = WIDTH * HEIGHT;
const TITLE: []const u8 = "Hello BytePusher";
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

const CPU = struct {
    program_counter: u32,
    memory: [MEMORY_SIZE]u8,

    fn loadRom(location: []const u8) void {
        _ = location;
    }
    fn readByte(location: u32) void {
        _ = location;
    }

    fn readDisplayMemory(location: u32) void {
        _ = location;
    }

    fn resetProgramCounter() void {}

    fn step() void {}

    fn write(location: u32, data: u8) void {
        _ = location;
        _ = data;
    }
};

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

pub fn main() !u8 {
    const cwd = std.fs.cwd();

    const args = try std.process.argsAlloc(std.heap.smp_allocator);
    defer std.process.argsFree(std.heap.smp_allocator, args);

    const options = flags.parseOrExit(args, "zbytepusher", Flags, .{});
    const file = cwd.openFile(options.file, .{ .mode = .read_only }) catch |err| {
        std.debug.print("found error while opening file : {}", .{err});
        std.posix.exit(0);
    };
    std.debug.print("{any}", .{file});

    std.posix.exit(0);
    rl.initWindow(WIDTH, HEIGHT, TITLE);
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        update();
        draw();
    }
    return 0;
}

const std = @import("std");
const flags = @import("flags");
const rl = @import("raylib");
