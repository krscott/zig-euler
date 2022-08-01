const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const BigDecimal = @import("./common/bigdecimal.zig").BigDecimal;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn sumOfDigits(d: *const BigDecimal) u64 {
    var sum: u64 = 0;
    for (d.slice) |ch| {
        sum += ch - '0';
    }
    return sum;
}

fn initFactorial(allocator: Allocator, n: u64) !BigDecimal {
    var acc = try BigDecimal.initFromInt(allocator, 1);
    errdefer acc.deinit();

    var multiplier = try BigDecimal.initFromInt(allocator, 1);
    defer multiplier.deinit();

    var i = n - 1;
    while (i > 0) : (i -= 1) {
        try multiplier.addStr("1");
        try acc.multiply(&multiplier);
    }

    return acc;
}

fn sumOfFactorialDigits(allocator: Allocator, n: u64) u64 {
    var d = initFactorial(allocator, n) catch unreachable;
    defer d.deinit();

    return sumOfDigits(&d);
}

test "simple problem" {
    try std.testing.expectEqual(sumOfFactorialDigits(std.testing.allocator, 10), 27);
}

fn answer(allocator: Allocator) u64 {
    return sumOfFactorialDigits(allocator, 100);
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 648);
}
