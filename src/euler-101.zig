const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const max = std.math.max;

const printSlice = @import("./common/sliceutil.zig").printSlice;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

/// Use Newton's method to interpolate y-value at x=`t` from given points.
fn neville_interp(buf: []i64, x: []const i64, y: []const i64, t: i64) i64 {
    assert(x.len == y.len and buf.len == y.len);

    std.mem.copy(i64, buf, y);

    const n = x.len;

    var m: usize = 1;
    while (m < n) : (m += 1) {
        var i: usize = 0;
        while (i < n - m) : (i += 1) {
            buf[i] = @divExact((t - x[i + m]) * buf[i] + (x[i] - t) * buf[i + 1], x[i] - x[i + m]);
        }
    }

    return buf[0];
}

fn poly(coefficients: []const i64, x: i64) i64 {
    var y: i64 = 0;

    var i: usize = 0;
    while (i < coefficients.len) : (i += 1) {
        y += coefficients[i] * std.math.pow(i64, x, @intCast(i64, i));
    }

    return y;
}

fn firstIncorrectTerm(allocator: Allocator, coefficients: []const i64, k: usize) !?i64 {
    const len = max(coefficients.len + 1, k);

    var x = try allocator.alloc(i64, len);
    defer allocator.free(x);

    var y = try allocator.alloc(i64, len);
    defer allocator.free(y);

    var buf = try allocator.alloc(i64, len);
    defer allocator.free(buf);

    // Evaluate (x,y) points of polynomial defined by `coefficients`
    {
        var i: usize = 0;
        while (i < len) : (i += 1) {
            x[i] = @intCast(i64, i) + 1;
            y[i] = poly(coefficients, x[i]);
        }
    }

    // printSlice("coeff: [{d},]\n", coefficients);
    // printSlice("x: [{d},]\n", x);
    // printSlice("y: [{d},]\n", y);

    // print("OP({d},n) = ", .{k});
    // defer print("\n", .{});

    // i < k is guaranteed to be correct, so no need to check
    var i: usize = k;
    while (i < coefficients.len) : (i += 1) {
        const t = @intCast(i64, i) + 1;
        const op = neville_interp(buf[0..k], x[0..k], y[0..k], t);
        // print("{d}, ", .{op});
        if (op != y[i]) {
            return op;
        }
    }

    return null;
}

fn sumOfFITs(allocator: Allocator, coefficients: []const i64) !i64 {
    var sum: i64 = 0;

    var k: usize = 1;
    while (k < coefficients.len) : (k += 1) {
        if (try firstIncorrectTerm(allocator, coefficients, k)) |fit| {
            sum += fit;
        }
    }

    return sum;
}

fn answer(allocator: Allocator) i64 {
    return sumOfFITs(allocator, &.{ 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 1 }) catch @panic("alloc");
}

test "simple problem" {
    const n3_coeff: []const i64 = &.{ 0, 0, 0, 1 };

    try std.testing.expectEqual(firstIncorrectTerm(std.testing.allocator, n3_coeff, 1), 1);
    try std.testing.expectEqual(firstIncorrectTerm(std.testing.allocator, n3_coeff, 2), 15);
    try std.testing.expectEqual(firstIncorrectTerm(std.testing.allocator, n3_coeff, 3), 58);
    try std.testing.expectEqual(firstIncorrectTerm(std.testing.allocator, n3_coeff, 4), null);
    try std.testing.expectEqual(sumOfFITs(std.testing.allocator, n3_coeff), 74);
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 37076114526);
}
