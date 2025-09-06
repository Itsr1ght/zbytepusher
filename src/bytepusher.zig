const std = @import("std");
const rl = @import("raylib");

const Cpu = @import("cpu.zig").Cpu;
const Keyboard = @import("keyboard.zig").Keyboard;
const Display = @import("display.zig").Display;


pub const BytePusher = struct {

    cpu: Cpu,
    keyboard: Keyboard,
    display: Display,

    keyData: [0x02]u8 = .{0} ** 0x02,
    isRunning: bool = true,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        const cpu = try Cpu.init(allocator);
        var display = try Display.init();
        const keyboard = Keyboard.init(&display);

        return Self {
            .cpu = cpu,
            .keyboard = keyboard,
            .display = display,
        };
    }

    pub fn deinit(self: *Self) void {
        self.cpu.deinit();
        self.display.deinit();
    }

    pub fn loadRom(self: *Self, location: []const u8) !void {
        try self.cpu.loadRom(location);
    }

    pub fn run(self: *Self) !void {

        while (self.isRunning) {

            if (rl.windowShouldClose()) self.isRunning = false;
        
            const keys = self.keyboard.getKeys();
            self.keyData[0] = 0;
            self.keyData[1] = 0;

            for (0..2) |dataIndex| {
                for (0..8) |keyIndex| {
                    if (keys[keyIndex + (0x8 * dataIndex)] == true) {
                        self.keyData[dataIndex] |= @as(u8, 1) << @as(u3, @intCast(keyIndex));
                    }
                }
            }

            self.cpu.write(0x00, self.keyData[0x1]);
            self.cpu.write(0x01, self.keyData[0x0]);
            self.cpu.resetProgramCounter();

            for(0..0x10000) |_| {
                self.cpu.step();
            }

            try self.display.renderFrame(
                self.cpu.copyDisplayMemory(@as(usize, self.cpu.read(0x05)) << 0x10)
            );
        }
    }
};
