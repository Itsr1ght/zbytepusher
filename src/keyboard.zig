const std = @import("std");
const rl = @import("raylib");

const Display = @import("display.zig").Display;


pub const KeyMap = struct {
    key: rl.KeyboardKey,
    val: u8
};

pub const Keyboard = struct {

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

    pub fn init(display: *Display) Self {
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

    pub fn getKeys(self: *Self) [0x10]bool {
    
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
