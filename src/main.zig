const std = @import("std");
const rl = @import("c.zig");
const ArenaBuffer = @import("ArenaBuffer.zig");

const raywhite = rl.RAYWHITE;
const green = rl.GREEN;

const Points = struct {
    first: *Point,
    last: *Point,
};

const Point = struct {
    next: ?*Point = null,
    vec2: rl.Vector2,
};

pub fn main() !void {
    rl.InitWindow(800, 800, "Curve");

    var arena = try ArenaBuffer.init(4 * 1024 * 1024 * 1024);
    defer arena.deinit();

    var point: ?*Point = null;
    var points = Points{
        .first = undefined,
        .last = undefined,
    };

    while (!rl.WindowShouldClose()) {
        const mouse_pos = rl.GetMousePosition();
        // const frametime = rl.GetFrameTime();
        const mouse_delta = rl.GetMouseDelta();
        const mouse_delta_length = rl.Vector2Length(mouse_delta);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(raywhite);

        if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
            if (point) |_| {
                const last_point = points.last;
                const offset = rl.Vector2Subtract(mouse_pos, last_point.vec2);
                // std.debug.print("offset: {:.3}\n", .{rl.Vector2LengthSqr(offset)});
                std.debug.print("{}", .{arena});

                if (rl.Vector2Length(offset) > std.math.exp(mouse_delta_length * 100) + 5.0) {
                    last_point.next = blk: {
                        const mem = try arena.push(Point);
                        mem.vec2 = mouse_pos;
                        break :blk mem;
                    };
                    points.last = last_point.next.?;
                }
            } else {
                point = blk: {
                    const mem = try arena.push(Point);
                    mem.vec2 = mouse_pos;
                    break :blk mem;
                };
                points.first = point.?;
                points.last = point.?;
            }
        }

        if (point) |p| drawLines(p);
    }
    rl.CloseWindow();
}

fn drawLines(first_curve_point: *Point) void {
    var prev_point = first_curve_point;
    var next_ptr = first_curve_point.next;
    while (next_ptr) |np| {
        rl.DrawLineEx(prev_point.vec2, np.vec2, 1, rl.BLACK);
        prev_point = np;
        next_ptr = np.next;
    }
}
