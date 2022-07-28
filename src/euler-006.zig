const std = @import("std");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn sumOfSquares(input: u64) u64 {
    var sum: u64 = 0;
    var i: u64 = 0;
    while (i <= input) : (i += 1) {
        sum += i * i;
    }
    return sum;
}

fn squareOfSums(input: u64) u64 {
    const sum = input * (input + 1) / 2;
    return sum * sum;
}

fn sumSqDiff(input: u64) u64 {
    return squareOfSums(input) - sumOfSquares(input);
}

test "simple problem" {
    try std.testing.expectEqual(sumSqDiff(10), 2640);
}

fn answer() u64 {
    return sumSqDiff(100);
}

test "solution" {
    try std.testing.expectEqual(answer(), 25164150);
}
