
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
        const AAA = self.read(self.programCounter) << 0x10 | self.read(self.programCounter + 0x01) << 0x08 | self.read(self.programCounter + 0x02);
        const BBB = self.read(self.programCounter + 0x03 ) << 0x10 | self.read(self.programCounter + 0x04) << 0x08 | self.read(self.programCounter + 0x05);
        const CCC = self.read(self.programCounter + 0x06 ) << 0x10 | self.read(self.programCounter + 0x07) << 0x08 | self.read(self.programCounter + 0x08);
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

    fn copyDisplayMemory(self: *Self, location: u8) []u8 {
        return self.memory[location..];
    }

};

const keyboard = struct {

};

const Display = struct {
    
    const Self = @This();
    is_running: bool = true,
    palette: [256]rl.Color,
    pixel_array: []rl.Color,
    img: rl.Image,
    texture: rl.Texture2D,
    

    fn init() !Self {
        rl.initWindow(512, 512, "BytePusher build in Zig!");
        rl.setTargetFPS(60);
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

    fn renderFrame(self: *Self, data: []u8) void {
        for(0..256) |y| {
            for(0..256) |x| {
               self.pixel_array[x][y] = self.palette[data[(y * 256) + x]];
            }
        }
    }

    fn update(self: *Self) !void {
        while (!rl.windowShouldClose() and self.is_running) {

            rl.beginDrawing();

                self.texture = try rl.loadTextureFromImage(self.img);
                defer rl.unloadTexture(self.texture);
                rl.drawTexture(self.texture, 100, 100, .white);
            
            rl.endDrawing();

            if(rl.isKeyDown(.escape)) self.is_running = false;
        }
    }

    fn deinit(_ : *Self) void {
        rl.closeWindow();
    }


};

const keyData: [0x02]u8 = .{0} ** 0x02;


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

    var cpu = Cpu.init(allocator) catch |err| {
        std.debug.print("found error CPU initializing : {any}", .{err});
        return 1;
    };

    defer cpu.deinit();

    var display = Display.init() catch |err| {
        std.debug.print("found error while initializing display : {any}", .{err});
        return 1;
    };
    defer display.deinit();

    display.update() catch |err| {
        std.debug.print("find error while running {any}", .{err});
        return 1;
    };

    cpu.loadRom(options.file) catch |err| {
        std.debug.print("found error loading ROM : {any}", .{err});
        return 1;
    };

    return 0;
}

const std = @import("std");
const flags = @import("flags");
const rl = @import("raylib");
