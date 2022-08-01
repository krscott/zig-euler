const std = @import("std");
const assert = std.debug.assert;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn onesLength(n: usize) usize {
    return switch (n) {
        0 => "".len,
        1 => "one".len,
        2 => "two".len,
        3 => "three".len,
        4 => "four".len,
        5 => "five".len,
        6 => "six".len,
        7 => "seven".len,
        8 => "eight".len,
        9 => "nine".len,
        else => unreachable,
    };
}

fn tensLength(n: usize) usize {
    return switch (n) {
        0 => "".len,
        1 => "ten".len,
        2 => "twenty".len,
        3 => "thirty".len,
        4 => "forty".len,
        5 => "fifty".len,
        6 => "sixty".len,
        7 => "seventy".len,
        8 => "eighty".len,
        9 => "ninety".len,
        else => unreachable,
    };
}

fn tensOnesLength(n: usize) usize {
    return switch (n) {
        0...10, 20...99 => |m| tensLength(m / 10) + onesLength(m % 10),
        11 => "eleven".len,
        12 => "twelve".len,
        13 => "thirteen".len,
        14 => "fourteen".len,
        15 => "fifteen".len,
        16 => "sixteen".len,
        17 => "seventeen".len,
        18 => "eighteen".len,
        19 => "nineteen".len,
        else => unreachable,
    };
}

fn hundredsLength(n: usize) usize {
    if (n == 0) return "".len;
    assert(n < 10);
    return onesLength(n) + "hundred".len;
}

fn hundredsAndTensOnesLength(n: usize) usize {
    assert(n < 1000);
    const hundreds = n / 100;
    const tensOnes = n % 100;

    const andLength = if (hundreds > 0 and tensOnes > 0) "and".len else 0;

    return hundredsLength(hundreds) + andLength + tensOnesLength(tensOnes);
}

fn thousandsLength(n: usize) usize {
    if (n == 0) return "".len;
    assert(n < 10);
    return onesLength(n) + "thousand".len;
}

fn thousandsHundredsAndTensOnesLength(n: usize) usize {
    assert(n < 10_000);
    return thousandsLength(n / 1000) + hundredsAndTensOnesLength(n % 1000);
}

fn countLettersUpTo(n: usize) usize {
    var count: usize = 0;
    var i: usize = 1;
    while (i <= n) : (i += 1) {
        count += thousandsHundredsAndTensOnesLength(i);
    }
    return count;
}

test "simple problem" {
    try std.testing.expectEqual(thousandsHundredsAndTensOnesLength(342), 23);
    try std.testing.expectEqual(thousandsHundredsAndTensOnesLength(115), 20);
    try std.testing.expectEqual(countLettersUpTo(5), 19);
}

fn answer() u64 {
    return countLettersUpTo(1000);
}

test "solution" {
    try std.testing.expectEqual(answer(), 21124);
}
