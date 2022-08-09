const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const panic = std.debug.panic;

const fsutil = @import("./common/fsutil.zig");
const iterutil = @import("./common/iterutil.zig");
const Vec2 = @import("./common/vector.zig").Vec2(f64);
const pi = std.math.pi;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn isTriangleContainOrigin(points: [3]Vec2) bool {
    const a = &points[0];
    const b = &points[1];
    const c = &points[2];

    if (a.angle(b.*) > 0) {
        // A -> B -> C
        return b.angle(c.*) > 0 and c.angle(a.*) > 0;
    } else {
        // A -> C -> B
        return c.angle(b.*) > 0 and a.angle(c.*) > 0;
    }
}

fn parseScalar(buf: []const u8) f64 {
    return std.fmt.parseFloat(f64, buf) catch |e| panic("Parse error: {s}", .{@errorName(e)});
}

fn parseLine(buf: []const u8) [3]Vec2 {
    var out: [3]Vec2 = undefined;
    var it = iterutil.splitStringDelims(buf, ",")
        .map(parseScalar);
    for (out) |_, i| {
        out[i] = Vec2.init(
            it.next() orelse panic("Parse error: Too few points", .{}),
            it.next() orelse panic("Parse error: Too few points", .{}),
        );
    }
    return out;
}

fn answer(allocator: Allocator) u64 {
    const text = fsutil.readFileAllocPanicking(allocator, "./data/p102_triangles.txt");
    defer allocator.free(text);

    return iterutil.splitLines(text)
        .map(parseLine)
        .filter(isTriangleContainOrigin)
        .count();
}

test "simple problem" {
    const a = Vec2.init(-340.0, 495.0);
    const b = Vec2.init(-153.0, -910.0);
    const c = Vec2.init(835.0, -947.0);

    const x = Vec2.init(-175.0, 41.0);
    const y = Vec2.init(-421.0, -714.0);
    const z = Vec2.init(574.0, -645.0);

    try std.testing.expect(isTriangleContainOrigin(.{ a, b, c }));
    try std.testing.expect(!isTriangleContainOrigin(.{ x, y, z }));
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 228);
}
