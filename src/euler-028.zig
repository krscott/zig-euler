const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn spiralDiagonalSum(size: u64) u64 {
    assert(@rem(size, 2) == 1);
    if (size <= 1) return size;

    const corners: [4]void = undefined;

    var sum: u64 = 1;
    var side: u64 = 3;
    var i: u64 = 1;

    while (side <= size) : (side += 2) {
        inline for (corners) |_| {
            i += side - 1;
            // std.debug.print("{d}\n", .{i});
            sum += i;
        }
    }

    return sum;
}

fn answer() u64 {
    return spiralDiagonalSum(1001);
}

test "simple problem" {
    try std.testing.expectEqual(spiralDiagonalSum(5), 101);
}

test "solution" {
    try std.testing.expectEqual(answer(), 669171001);
}
