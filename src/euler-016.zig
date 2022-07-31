const std = @import("std");
const Allocator = std.mem.Allocator;
const max = std.math.max;
const assert = std.debug.assert;

const BigDecimal = @import("./common/bigdecimal.zig").BigDecimal;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn sumOfDigitsOfPowerOf2(p: usize) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var a = BigDecimal.initFromString(allocator, "1") catch unreachable;
    defer a.deinit();

    {
        var i: usize = 0;
        while (i < p) : (i += 1) {
            a.multiply("2") catch unreachable;
        }
    }

    // std.debug.print("{s}\n", .{a.slice});

    var total: u64 = 0;
    for (a.slice) |c| {
        total += c - '0';
    }

    return total;
}

test "simple problem" {
    try std.testing.expectEqual(sumOfDigitsOfPowerOf2(15), 26);
}

fn answer() u64 {
    return sumOfDigitsOfPowerOf2(1000);
}

test "solution" {
    try std.testing.expectEqual(answer(), 1366);
}
