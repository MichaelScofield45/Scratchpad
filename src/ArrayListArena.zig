const ArenaBuffer = @import("ArenaBuffer.zig");

pub fn ArrayListArena(comptime T: type) type {
    return struct {
        arena: ArenaBuffer,
        len: usize,

        const Self = @This();
        pub fn init() !Self {
            return .{
                .arena = try ArenaBuffer.init(1 * 1024 * 1024 * 1024),
                .len = 0,
            };
        }

        pub fn clear(self: *Self) void {
            self.arena.clear();
            self.len = 0;
        }

        pub fn append(self: *Self, new_item: T) !void {
            const mem = try self.arena.push(T);
            mem.* = new_item;
            self.len += 1;
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
        }

        pub fn slice(self: Self) []T {
            const mem_ptr: [*]T = @ptrCast(self.arena.raw_mem.ptr);
            return mem_ptr[0..self.len];
        }
    };
}
