
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

const Cpu = struct {
    allocator: std.mem.Allocator,
    memory: []u8,
    programCounter: u32,

    const Self = @This();
    
    fn init(allocator: std.mem.Allocator) !Self {
        const arr = try allocator.alloc(u8, 0x100000);
        @memset(arr, 0);
        return .{
            .allocator = allocator,
            .memory = arr,
            .programCounter = 0
        };
    }

    fn loadRom(self: *Self, location: []const u8) !void {
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

    fn deinit(self: *Self) void {
        self.allocator.free(self.memory);
    }
    
    fn read(self: *Self, location: usize) u8 {
        return self.memory[location];
    }

    fn write(self: *Self, location: usize, data: u8) void {
        if (location < self.memory.len) {
            self.memory[location] = data;
        }
    }

    fn step(self: *Self) void {
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

    fn resetProgramCounter(self: *Self) void {
        self.programCounter = @as(
            u32, 
            (@as(u32, self.read(2)) << 0x10) |
            (@as(u32, self.read(3)) << 0x08 ) |
            (@as(u32, self.read(4)))
        );
    }

    fn copyDisplayMemory(self: *Self, location: usize) []u8 {
        return self.memory[location..];
    }

};


const KeyMap = struct {
    key: rl.KeyboardKey,
    val: u8
};

const Keyboard = struct {

    const keyMap = [_]KeyMap{
        .{ .key = .one ,   .val = 0x1 },
        .{ .key = .two,    .val = 0x2 },
        .{ .key = .three , .val = 0x3 },
        .{ .key = .four,   .val = 0xC },
        .{ .key = .q,      .val = 0x4 },
        .{ .key = .w,      .val = 0x5 },
        .{ .key = .e,      .val = 0x6 },
        .{ .key = .r,      .val = 0xD },
        .{ .key = .a,      .val = 0x7 },
        .{ .key = .s,      .val = 0x8 },
        .{ .key = .d,      .val = 0x9 },
        .{ .key = .f,      .val = 0xE },
        .{ .key = .z,      .val = 0xA },
        .{ .key = .x,      .val = 0x0 },
        .{ .key = .c,      .val = 0xB },
        .{ .key = .v,      .val = 0xF },
    };

    keys: [0x10]bool = .{false} ** 0x10,
    display: *Display,

    const Self = @This();

    fn init(display: *Display) Self {
        return Self{
            .display = display,
        };
    } 

    fn findKeyIndex(k: rl.KeyboardKey) ?usize {
        
        for (keyMap, 0..) |entry, i| {
            if (entry.key == k) return i;
        }

        return null;
    }

    fn getKeys(self: *Self) [0x10]bool {
    
        @memset(&self.keys, false);

        for (keyMap) |key| {
            if (rl.isKeyDown(key.key)){
                self.keys[findKeyIndex(key.key).?] = true;
            }
            if (rl.isKeyUp(key.key)) {
                self.keys[findKeyIndex(key.key).?] = false;
            }
        }

        return self.keys;
    }
};

const Spu = struct {
    allocator: std.mem.Allocator,
    audio_stream: rl.AudioStream,
    buffer: []i16,

    const Self = @This();

    fn init(allocator: std.mem.Allocator) !Self {

        rl.initAudioDevice();

        const audio_stream = try rl.loadAudioStream(15360, 16, 1);
        rl.playAudioStream(audio_stream);
        const buffer = try allocator.alloc(i16, 256);


        return .{
            .allocator = allocator,
            .audio_stream = audio_stream,
            .buffer = buffer,
        };
    }

    fn updateBuffer(self: *Self, cpu_memory: []u8) void {
        for(0..256) |i| {
            const sample_sound = cpu_memory[0xff00 + i];
            const sample_centered = @as(i16, @intCast(sample_sound)) - 128;
            self.buffer[i] = sample_centered << 8;
        }
    }

    fn play(self: *Self) void {
        if (rl.isAudioStreamProcessed(self.audio_stream)) {
            rl.updateAudioStream(self.audio_stream, @as(*const anyopaque, @ptrCast(self.buffer)), 256);
        }
    }

    fn deinit(self: *Self) void {
        rl.stopAudioStream(self.audio_stream);
        rl.unloadAudioStream(self.audio_stream);
        self.allocator.free(self.buffer);
        rl.closeAudioDevice();
    }
};

const Display = struct {
    
    const Self = @This();
    palette: [256]rl.Color,
    pixel_array: []rl.Color,
    img: rl.Image,
    texture: rl.Texture2D,
    

    fn init() !Self {
        rl.initWindow(512, 512, "BytePusher build in Zig!");
        rl.setTargetFPS(60);
        rl.setTraceLogLevel(.none);
        var index: u32 = 0;
        const step: u8 = 0x33;

        const image = rl.genImageColor(256, 256, .black);
        const pixel = @as([*]rl.Color, @ptrCast(image.data))[0..@as(usize, @intCast(image.width)) * @as(usize, @intCast(image.height))];

        var palette: [256]rl.Color = undefined;

        var red: u16 = 0;
        while (red < 256) : (red += step) {
            var green: u16 = 0;
            while (green < 256) : (green += step) {
                var blue: u16 = 0;
                while (blue < 256) : (blue += step) {
                    palette[index] = rl.Color{
                        .r = @as(u8, @intCast(red)),
                        .g = @as(u8, @intCast(green)) ,
                        .b = @as(u8, @intCast(blue)) ,
                        .a = 255};
                    index += 1;
                }
            }
        }

        return Self{
            .palette = palette,
            .img = image,
            .pixel_array = pixel,
            .texture = try rl.loadTextureFromImage(image),
        };
    }

    fn renderFrame(self: *Self, data: []u8) !void {
        for(0..256) |y| {
            for(0..256) |x| {
                const index: usize = y * @as(usize, @intCast(self.img.width)) + x;
                self.pixel_array[index] = self.palette[data[(y * 256) + x]];
            }
        }
        try self.update();
    }

    fn update(self: *Self) !void {
        rl.beginDrawing();

            self.texture = try rl.loadTextureFromImage(self.img);
            defer rl.unloadTexture(self.texture);
            const source: rl.Rectangle = .init(0, 0, 
                @as(f32, @floatFromInt(self.texture.width)),
                @as(f32, @floatFromInt(self.texture.height))
            );
            const dest: rl.Rectangle = .init(0, 0,
                @as(f32, @floatFromInt(rl.getScreenWidth())),
                @as(f32, @floatFromInt(rl.getScreenHeight()))
            );
            rl.drawTexturePro(self.texture, source, dest, .{ .x = 0.0, .y = 0.0 }, 0.0, .white);
        
        rl.endDrawing();
    }

    fn deinit(_ : *Self) void {
        rl.closeWindow();
    }


};

const keyData: [0x02]u8 = .{0} ** 0x02;


const BytePusher = struct {

    cpu: Cpu,
    keyboard: Keyboard,
    display: Display,
    spu: Spu,

    keyData: [0x02]u8 = .{0} ** 0x02,
    isRunning: bool = true,

    const Self = @This();

    fn init(allocator: std.mem.Allocator) !Self {
        const cpu = try Cpu.init(allocator);
        var display = try Display.init();
        const keyboard = Keyboard.init(&display);
        const spu = try Spu.init(allocator);

        return Self {
            .cpu = cpu,
            .keyboard = keyboard,
            .display = display,
            .spu = spu,
        };
    }

    fn deinit(self: *Self) void {
        self.cpu.deinit();
        self.spu.deinit();
        self.display.deinit();
    }

    fn loadRom(self: *Self, location: []const u8) !void {
        try self.cpu.loadRom(location);
    }

    fn run(self: *Self) !void {

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


            self.spu.updateBuffer(self.cpu.memory);
            self.spu.play();

            try self.display.renderFrame(
                self.cpu.copyDisplayMemory(@as(usize, self.cpu.read(0x05)) << 0x10)
            );
        }
    }
};


pub fn main() u8 {
    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    const allocator = debug_allocator.allocator();
    defer {
        if( debug_allocator.deinit() == .leak ){
            std.debug.print("dripping\n", .{});
        }
    }

    const args = std.process.argsAlloc(allocator) catch |err| {
        std.debug.print("ERROR : found error while allocating argument : {}", .{err});
        return 1;
    };
    defer std.process.argsFree(allocator, args);

    const options = handleArgs(args);

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
const rl = @import("raylib");
