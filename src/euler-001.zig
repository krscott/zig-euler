const std = @import("std");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn answer() u64 {
    return sumOfMultiples(1000);
}

fn sumOfMultiples(below: u64) u64 {
    var sum: u64 = 0;
    var i: u64 = 0;
    while (i < below) : (i += 1) {
        if (i % 3 == 0 or i % 5 == 0) {
            sum += i;
        }
    }
    return sum;
}

test "simple problem" {
    try std.testing.expectEqual(sumOfMultiples(10), 23);
}

test "solution" {
    try std.testing.expectEqual(answer(), 233168);
}
