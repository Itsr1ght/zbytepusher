
//command line flags
const Flags = struct {
    pub const description =
        \\Simple BytePusher VM created using zig 
        \\use --file command to choose the file
    ;
    file: []const u8,
};


fn update() void {}

fn draw() void {}

pub fn main() u8 {
    const cwd = std.fs.cwd();

    const args = std.process.argsAlloc(std.heap.smp_allocator) catch |err| {
        std.debug.print("ERROR : found error while allocating argument : {}", .{err});
        std.posix.exit(1);
    };
    defer std.process.argsFree(std.heap.smp_allocator, args);

    const options = flags.parseOrExit(args, "zbytepusher", Flags, .{});
    const file = cwd.openFile(options.file, .{ .mode = .read_only }) catch |err| {
        std.debug.print("ERROR : found error while opening file : {}", .{err});
        std.posix.exit(1);
    };
    std.debug.print("{any}", .{file});

    std.posix.exit(0);
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
