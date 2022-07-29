const std = @import("std");
const assert = std.debug.assert;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

const SumTripletIter = struct {
    const Self = @This();

    total: u64,
    a: u64,
    b: u64,

    pub fn init(total: u64) Self {
        return Self{
            .total = total,
            .a = 1,
            .b = 0,
        };
    }

    pub fn next(self: *Self) ?[3]u64 {
        if (self.b < (self.total - self.a) / 2) {
            // Increment b until half-way to (total - a)
            self.b += 1;
        } else {
            // Reset b and increment a, until half-way to total
            self.b = 1;
            if (self.a < self.total / 2) {
                self.a += 1;
            } else {
                // Iterator is done
                return null;
            }
        }

        // Sanity check
        assert(self.a > 0);
        assert(self.b > 0);

        const out: [3]u64 = .{ self.a, self.b, self.total - self.a - self.b };

        return out;
    }
};

fn isPythagTriplet(t: [3]u64) bool {
    return t[0] * t[0] + t[1] * t[1] == t[2] * t[2];
}

fn findSpecialTriplet(sum: u64) ?[3]u64 {
    var trips = SumTripletIter.init(sum);

    while (true) {
        var t = trips.next() orelse return null;

        if (isPythagTriplet(t)) {
            return t;
        }
    }
}

fn sumOfSpecialTriplet(sum: u64) ?u64 {
    var t = findSpecialTriplet(sum) orelse return null;
    return t[0] * t[1] * t[2];
}

test "simple problem" {
    // 3^2 + 4^2 = 5^2
    // 3 + 4 + 5 = 12
    // 3 * 4 * 5 = 60
    try std.testing.expectEqual(sumOfSpecialTriplet(12), 60);
}

fn answer() u64 {
    return sumOfSpecialTriplet(1000).?;
}

test "solution" {
    try std.testing.expectEqual(answer(), 31875000);
}
