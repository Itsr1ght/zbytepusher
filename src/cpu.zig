
const std = @import("std");

pub const Cpu = struct {
    allocator: std.mem.Allocator,
    memory: []u8,
    programCounter: u32,

    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) !Self {
        const arr = try allocator.alloc(u8, 0x100000);
        @memset(arr, 0);
        return .{
            .allocator = allocator,
            .memory = arr,
            .programCounter = 0
        };
    }

    pub fn loadRom(self: *Self, location: []const u8) !void {
        var rom = try std.fs.cwd().openFile(location, .{});
        defer rom.close();

        const stat = try rom.stat();
        const buffer = try self.allocator.alloc(u8, @as(usize, @intCast(stat.size)));
        defer self.allocator.free(buffer);
        _ = try rom.readAll(buffer);
        for(buffer, 0..buffer.len) |buff, i| {
            self.memory[i] = buff;
        }
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.memory);
    }
    
    pub fn read(self: *Self, location: usize) u8 {
        return self.memory[location];
    }

    pub fn write(self: *Self, location: usize, data: u8) void {
        if (location < self.memory.len) {
            self.memory[location] = data;
        }
    }

    pub fn step(self: *Self) void {
        const AAA:u32 = 
            @as(u32, @intCast(self.read(self.programCounter)))         << 0x10 |
            @as(u32, @intCast(self.read(self.programCounter + 0x01)))  << 0x08 |
            @as(u32, @intCast(self.read(self.programCounter + 0x02)));
        const BBB: u32 = 
            @as(u32, @intCast(self.read(self.programCounter + 0x03 ))) << 0x10 |
            @as(u32, @intCast(self.read(self.programCounter + 0x04)))  << 0x08 |
            @as(u32, @intCast(self.read(self.programCounter + 0x05)));
        const CCC: u32 = 
            @as(u32, @intCast(self.read(self.programCounter + 0x06 ))) << 0x10 |
            @as(u32, @intCast(self.read(self.programCounter + 0x07)))  << 0x08 |
            @as(u32, @intCast(self.read(self.programCounter + 0x08)));
        self.write(BBB, self.read(AAA));
        self.programCounter = CCC;
    }

    pub fn resetProgramCounter(self: *Self) void {
        self.programCounter = @as(
            u32, 
            (@as(u32, self.read(2)) << 0x10) |
            (@as(u32, self.read(3)) << 0x08 ) |
            (@as(u32, self.read(4)))
        );
    }

    pub fn copyDisplayMemory(self: *Self, location: usize) []u8 {
        return self.memory[location..];
    }

};
