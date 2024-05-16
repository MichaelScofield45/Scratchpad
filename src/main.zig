const std = @import("std");
const rl = @import("c.zig");
const ArrayListArena = @import("ds.zig").ArrayListArena;
const MemoryPoolArena = @import("ds.zig").MemoryPoolArena;

const Curve = struct {
    color: rl.Color,
    n_points: usize = 0,
    first: ?*Point = null,
    last: ?*Point = null,

    pub fn appendPoint(self: *Curve, p: *Point) void {
        if (self.last) |*last| {
            last.*.next = p;
            last.* = p;
        } else {
            self.first = p;
            self.last = p;
        }
        self.n_points += 1;
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

    var curves = try ArrayListArena(Curve).init(null);
    defer curves.deinit();

    var active_color: rl.Color = rl.BLACK;
    try curves.append(.{ .color = active_color });

    var mouse_left_held = false;
    var active_curve_idx: usize = 0;
    var curr_pos: ?rl.Vector2 = null;

    while (!rl.WindowShouldClose()) {
        const mouse_pos = rl.GetMousePosition();
        const mouse_delta = rl.GetMouseDelta();
        const mouse_delta_length = rl.Vector2Length(mouse_delta);

        if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
            if (!mouse_left_held) {
                try curves.append(.{ .color = active_color });
                active_curve_idx += 1;
            }
            mouse_left_held = true;
            curr_pos = mouse_pos;
        }

        if (rl.IsMouseButtonUp(rl.MOUSE_BUTTON_LEFT)) {
            mouse_left_held = false;
            curr_pos = null;
        }

        if (rl.IsKeyPressed(rl.KEY_C)) {
            curves.clear();
            _ = pool.reset(.retain_capacity);
            try curves.append(.{ .color = active_color });
            active_curve_idx = 0;
        }

        if (rl.IsKeyPressed(rl.KEY_ONE)) active_color = rl.BLACK;
        if (rl.IsKeyPressed(rl.KEY_TWO)) active_color = rl.RED;

        const curves_slice = curves.slice();

        if (mouse_left_held and mouse_delta_length > 0.0) {
            if (curves_slice[active_curve_idx].last) |last_point| {
                const offset_from_last_point = rl.Vector2Subtract(mouse_pos, last_point.vec2);
                const offset_length = rl.Vector2Length(offset_from_last_point);

                const lower_bound_distance = std.math.exp(mouse_delta_length * 0.2);

                if (offset_length >= lower_bound_distance) {
                    const new_point: *Point = blk: {
                        const mem = try pool.create();
                        mem.* = Point{ .vec2 = mouse_pos };
                        break :blk mem;
                    };
                    curves_slice[active_curve_idx].appendPoint(new_point);
                }
            } else {
                const new_point: *Point = blk: {
                    const mem = try pool.create();
                    mem.* = Point{ .vec2 = mouse_pos };
                    break :blk mem;
                };
                curves_slice[active_curve_idx].appendPoint(new_point);
            }

            std.debug.print(
                "{}\n",
                .{curves_slice[active_curve_idx].n_points},
            );
        }

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        for (curves_slice, 0..) |curve, idx| {
            if (!curve.isEmpty()) {
                if (idx == curves_slice.len -| 1)
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
