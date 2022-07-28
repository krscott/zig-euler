const std = @import("std");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn answer() u64 {
    return sumOfEvenValuedFibLTE(4_000_000);
}

const FibIter = struct {
    const Self = @This();
    a: u64,
    b: u64,

    pub fn init() Self {
        return Self{
            .a = 0,
            .b = 1,
        };
    }

    pub fn next(self: *Self) u64 {
        const next_a = self.b;
        self.b += self.a;
        self.a = next_a;
        return self.b;
    }
};

fn sumOfEvenValuedFibLTE(limit: u64) u64 {
    var sum: u64 = 0;
    var fib = FibIter.init();

    while (true) {
        var value = fib.next();

        if (value > limit) {
            break;
        }

        if (value % 2 == 0) {
            sum += value;
        }
    }

    return sum;
}

test "simple problem" {
    try std.testing.expectEqual(sumOfEvenValuedFibLTE(89), 2 + 8 + 34);
}

test "solution" {
    try std.testing.expectEqual(answer(), 4613732);
}
