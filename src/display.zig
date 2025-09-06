const std = @import("std");
const rl = @import("raylib");


pub const Display = struct {
    
    const Self = @This();
    palette: [256]rl.Color,
    pixel_array: []rl.Color,
    img: rl.Image,
    texture: rl.Texture2D,
    

    pub fn init() !Self {
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

    pub fn renderFrame(self: *Self, data: []u8) !void {
        for(0..256) |y| {
            for(0..256) |x| {
                const index: usize = y * @as(usize, @intCast(self.img.width)) + x;
                self.pixel_array[index] = self.palette[data[(y * 256) + x]];
            }
        }
        try self.update();
    }

    pub fn update(self: *Self) !void {
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
