const ArenaBuffer = @import("ArenaBuffer.zig");

pub fn ArrayListArena(comptime T: type) type {
    return struct {
        arena: ArenaBuffer,
        len: usize,

        const Self = @This();
        pub fn init(max_capacity: ?usize) !Self {
            return .{
                // Max virtual address space reserved, this can be massive,
                // i.e 64GB
                .arena = try ArenaBuffer.init(max_capacity orelse 64 * 1024 * 1024 * 1024),
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

pub fn MemoryPoolArena(comptime T: type) type {
    return struct {
        free_list: ?*T = null,

        const Self = @This();
        pub fn create(self: *Self) void {
            _ = self;
        }
        pub fn destroy(self: *Self) void {
            _ = self;
        }
        pub fn clear(self: *Self) void {
            _ = self;
        }
    };
}
