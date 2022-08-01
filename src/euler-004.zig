const std = @import("std");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn answer() u64 {
    return largestPalendromeProduct(999);
}

const DescendingProductsIter = struct {
    const Self = @This();
    initial_value: u64,
    a: u64,
    b: u64,

    pub fn init(value: u64) Self {
        return Self{
            .initial_value = value,
            .a = value,
            .b = value,
        };
    }

    pub fn next(self: *Self) ?u64 {
        const out = self.a * self.b;

        if (self.a < self.initial_value and self.b > 1) {
            self.a += 1;
            self.b -= 1;
        } else if (self.a > 1) {
            const x = (self.b + self.initial_value) / 2 - 1;
            const y = (self.b + self.initial_value) % 2;
            self.a = x + 1 - y;
            self.b = x;
        } else {
            return null;
        }

        return out;
    }
};

fn isPalendromicNumber(buf: []u8, n: u64) !bool {
    var s = try std.fmt.bufPrint(buf, "{d}", .{n});
    var i: usize = 0;
    while (i < (s.len + 1) / 2) : (i += 1) {
        if (s[i] != s[s.len - i - 1]) {
            return false;
        }
    }
    return true;
}

fn largestPalendromeProduct(max: u64) u64 {
    // Max u64 is 20 digits
    var buf: [21]u8 = undefined;

    var products = DescendingProductsIter.init(max);
    while (true) {
        // Single-digit numbers are palendromic, so end of iter will not be reached
        const prod: u64 = products.next() orelse unreachable;

        if (isPalendromicNumber(buf[0..], prod) catch unreachable) {
            return prod;
        }
    }
}

test "simple problem" {
    try std.testing.expectEqual(largestPalendromeProduct(99), 9009);
}

test "solution" {
    try std.testing.expectEqual(answer(), 906609);
}
