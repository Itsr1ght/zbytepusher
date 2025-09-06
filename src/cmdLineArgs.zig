const std = @import("std");
const flags = @import("flags");

pub const Flags = struct {
    pub const description =
        \\Simple BytePusher VM created using zig 
        \\use --file command to choose the file
    ;
    file: []const u8,
};

pub const cmdLineArgs = struct {

    allocator: std.mem.Allocator,
    args: [][:0]u8,
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .args = std.mem.zeroes([][:0]u8),
        };
    }

    pub fn processArgs(self: *Self) !Flags {
        self.args = try std.process.argsAlloc(self.allocator);
        const options = try flags.parse(self.args, "zbytepusher", Flags, .{});
        return options;
    }

    pub fn deinit(self: *Self) void {
        std.process.argsFree(self.allocator, self.args);
    }

};
