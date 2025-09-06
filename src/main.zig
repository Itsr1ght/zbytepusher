const keyData: [0x02]u8 = .{0} ** 0x02;


pub fn main() u8 {
    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    const allocator = debug_allocator.allocator();
    defer {
        if( debug_allocator.deinit() == .leak ){
            std.debug.print("dripping\n", .{});
        }
    }

    var argsHandler = cmdLineArgs.init(allocator);
    const options = argsHandler.processArgs() catch |err| {
        std.debug.print("found error while processing arguments : {}", .{err});
        return 1;
    };
    defer argsHandler.deinit();

    var bytepusher = BytePusher.init(allocator) catch |err| {
        std.debug.print("cannot initialize the bytepusher : {any}", .{err});
        return 1;
    };
    defer bytepusher.deinit();

    bytepusher.loadRom(options.file) catch |err| {
        std.debug.print("cannot load the load to the memory : {any}", .{err});
    };
    bytepusher.run() catch |err| {
        std.debug.print("found error while running : {any}", .{err});
        return 1;
    };

    return 0;
}

const std = @import("std");
const flags = @import("flags");
const BytePusher = @import("bytepusher.zig").BytePusher;
const cmdLineArgs = @import("cmdLineArgs.zig").cmdLineArgs;
