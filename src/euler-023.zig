const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const Primes = @import("./common/primes.zig").Primes;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

const AbundantCache = struct {
    const Self = @This();

    primes: Primes(u64),
    is_abundant_cache: std.AutoHashMap(u64, bool),
    abundant_sums: std.AutoHashMap(u64, void),

    pub fn init(allocator: Allocator) Self {
        return Self{
            .primes = Primes(u64).init(allocator),
            .is_abundant_cache = std.AutoHashMap(u64, bool).init(allocator),
            .abundant_sums = std.AutoHashMap(u64, void).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.primes.deinit();
        self.is_abundant_cache.deinit();
        self.* = undefined;
    }

    pub fn isAbundant(self: *Self, n: u64) !bool {
        if (self.is_abundant_cache.get(n)) |a| return a;
        const a: bool = (try self.primes.sumOfProperDivisors(n)) > n;
        try self.is_abundant_cache.put(n, a);
        return a;
    }

    pub fn checkAbundantSums(self: *Self, a: u64, b: u64) !void {
        if ((try self.isAbundant(a)) and (try self.isAbundant(b))) {
            try self.abundant_sums.put(a + b, {});
        }
    }

    pub fn isAbundantSum(self: *Self, n: u64) bool {
        if (self.abundant_sums.get(n)) |_| return true;
        return false;
    }
};

fn answer(allocator: Allocator) u64 {
    // Upper limits for abundant numbers we need to actually check
    const upper = 28123;

    var abundants = AbundantCache.init(allocator);
    defer abundants.deinit();

    var a: u64 = 1;
    while (a < upper) : (a += 1) {
        var b: u64 = a;
        while (a + b < upper) : (b += 1) {
            abundants.checkAbundantSums(a, b) catch @panic("error");
        }
    }

    var sum_non_abundants: u64 = 0;
    var i: u64 = 1;
    while (i < upper) : (i += 1) {
        if (!abundants.isAbundantSum(i)) {
            sum_non_abundants += i;
        }
    }

    return sum_non_abundants;
}

test "simple problem" {
    var abundants = AbundantCache.init(std.testing.allocator);
    defer abundants.deinit();

    try std.testing.expectEqual(abundants.isAbundant(28), false);
    try std.testing.expectEqual(abundants.isAbundant(12), true);
}

// test "solution" {
//     try std.testing.expectEqual(answer(std.testing.allocator), 12345);
// }
