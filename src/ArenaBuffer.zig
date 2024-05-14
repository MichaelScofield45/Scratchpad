const std = @import("std");
const posix = std.posix;
const page_size = std.mem.page_size;

raw_mem: []align(page_size) u8,
commited: usize,
offset: usize,

const Self = @This();

pub fn init(size: usize) !Self {
    return .{
        .raw_mem = try posix.mmap(
            null,
            size,
            posix.PROT.NONE,
            .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
            -1,
            0,
        ),
        .commited = 0,
        .offset = 0,
    };
}

pub fn deinit(self: *Self) void {
    posix.munmap(self.raw_mem);
}

fn commitPages(self: *Self, n: ?usize) !void {
    if (n) |alloc_size| {
        _ = alloc_size;
    } else {
        const eight_megs = 8 * 1024 * 1024;
        try posix.mprotect(
            @alignCast(self.raw_mem[self.commited..][0..eight_megs]),
            posix.PROT.READ | posix.PROT.WRITE,
        );
        self.commited += eight_megs;
    }
}

pub fn push(self: *Self, comptime T: type) !*T {
    const size = comptime @sizeOf(T);
    if (self.offset + size > self.commited) try self.commitPages(null);
    const start = self.offset;
    self.offset += size;

    return @ptrCast(@alignCast(self.raw_mem[start..][0..size]));
}

pub fn pushN(self: *Self, comptime T: type, n: usize) ![]T {
    const type_size = comptime @sizeOf(T);
    const total_size = type_size * n;
    if (self.offset + total_size > self.commited) try self.commitPages(null);
    const start = self.offset;
    self.offset += total_size;

    const many_ptr: [*]T = @ptrCast(@alignCast(self.raw_mem[start..][0..total_size].ptr));
    return many_ptr[0..n];
}

pub fn clear(self: *Self) void {
    self.offset = 0;
}

pub fn pop(self: Self) usize {
    return self.offset;
}

pub fn popTo(self: *Self, pos: usize) void {
    std.debug.assert(pos <= self.offset);
    self.offset = pos;
}

pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.print("commited: {d:.3}\n", .{
        std.fmt.fmtIntSizeDec(self.commited),
    });
    try writer.print("offset: {}", .{std.fmt.fmtIntSizeDec(self.offset)});
}
