const std = @import("std");
const rl = @import("c.zig");
const ArrayListArena = @import("ArrayListArena.zig").ArrayListArena;

const Curve = struct {
    color: rl.Color,
    first: ?*Point = null,
    last: ?*Point = null,

    pub fn appendPointPtr(self: *Curve, p: *Point) void {
        if (self.last) |*last| {
            last.*.next = p;
            last.* = p;
        } else {
            self.first = p;
            self.last = p;
        }
    }

    pub fn isEmpty(self: Curve) bool {
        return self.first == null;
    }
};

const Point = struct {
    next: ?*Point = null,
    vec2: rl.Vector2,
};

pub fn main() !void {
    rl.InitWindow(800, 800, "Curve");

    var arena_instance_pool = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance_pool.deinit();
    const arena_pool = arena_instance_pool.allocator();

    var pool = try std.heap.MemoryPool(Point).initPreheated(arena_pool, 10_000);

    var curves = try ArrayListArena(Curve).init();

    try curves.append(.{ .color = rl.BLACK });
    var mouse_left_held = false;
    var curr_idx: usize = 0;
    var curr_pos: ?rl.Vector2 = null;

    while (!rl.WindowShouldClose()) {
        const mouse_pos = rl.GetMousePosition();
        // const frametime = rl.GetFrameTime();
        // const mouse_delta = rl.GetMouseDelta();
        // const mouse_delta_length = rl.Vector2Length(mouse_delta);

        if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
            mouse_left_held = true;
            curr_pos = mouse_pos;
        }

        if (rl.IsMouseButtonUp(rl.MOUSE_BUTTON_LEFT)) {
            if (mouse_left_held) {
                try curves.append(.{ .color = rl.BLACK });
                curr_idx += 1;
            }
            mouse_left_held = false;
            curr_pos = null;
        }

        if (rl.IsKeyPressed(rl.KEY_C)) {
            curves.clear();
            _ = pool.reset(.retain_capacity);
            curr_idx = 0;
            try curves.append(.{ .color = rl.BLACK });
        }

        if (mouse_left_held) {
            const new_point: *Point = blk: {
                const mem = try pool.create();
                mem.* = Point{ .vec2 = mouse_pos };
                break :blk mem;
            };

            curves.slice()[curr_idx].appendPointPtr(new_point);
        }

        std.debug.print(
            "{}\n",
            .{std.fmt.fmtIntSizeDec(arena_instance_pool.queryCapacity())},
        );

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        for (curves.slice(), 0..) |curve, idx| {
            if (!curve.isEmpty()) {
                if (idx == curves.slice().len -| 1)
                    drawActiveCurve(curve, curr_pos)
                else
                    drawCurve(curve);
            }
        }
    }
    rl.CloseWindow();
}

fn drawCurve(curve: Curve) void {
    drawLines(curve.first.?, curve.color);
}

fn drawActiveCurve(curve: Curve, curr_pos: ?rl.Vector2) void {
    drawLines(curve.first.?, curve.color);
    if (curr_pos) |pos|
        rl.DrawLineEx(curve.last.?.vec2, pos, 2, curve.color);
}

fn drawLines(first_point: *Point, color: rl.Color) void {
    if (first_point.next) |second_point| {
        rl.DrawLineEx(first_point.vec2, second_point.vec2, 2, color);
        drawLines(second_point, color);
    }
}
