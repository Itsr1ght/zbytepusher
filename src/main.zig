
//command line flags
const Flags = struct {
    pub const description =
        \\Simple BytePusher VM created using zig 
        \\use --file command to choose the file
    ;
    file: []const u8,
};

fn handleArgs(args: [][:0]u8) Flags {
    const options = flags.parseOrExit(args, "zbytepusher", Flags, .{});
    return options;
}


fn update() void {}

fn draw() void {}

pub fn main() u8 {
    const cwd = std.fs.cwd();

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = std.process.argsAlloc(allocator) catch |err| {
        std.debug.print("ERROR : found error while allocating argument : {}", .{err});
        std.posix.exit(1);
    };
    defer std.process.argsFree(allocator, args);

    const options = handleArgs(args);
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
