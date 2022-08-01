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

const AmicableCache = struct {
    const Self = @This();

    allocator: Allocator,
    primes: Primes(u64),
    sum_cache: std.hash_map.AutoHashMap(u64, u64),

    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .primes = Primes(u64).init(allocator),
            .sum_cache = std.hash_map.AutoHashMap(u64, u64).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.primes.deinit();
        self.sum_cache.deinit();
        self.* = undefined;
    }

    pub fn getSumOfProperDivisors(self: *Self, n: u64) Allocator.Error!u64 {
        if (self.sum_cache.get(n)) |sum| return sum;

        var sum = try self.primes.sumOfProperDivisors(n);

        try self.sum_cache.put(n, sum);

        return sum;
    }

    pub fn isAmicable(self: *Self, n: u64) Allocator.Error!bool {
        const d_n = try self.getSumOfProperDivisors(n);
        return d_n != n and n == try self.getSumOfProperDivisors(d_n);
    }

    pub fn sumOfAmicables(self: *Self, limit: u64) Allocator.Error!u64 {
        var sum: u64 = 0;
        var i: usize = 0;
        while (i < limit) : (i += 1) {
            if (try self.isAmicable(i)) {
                sum += i;
            }
        }
        return sum;
    }
};

test "simple problem" {
    var ac = AmicableCache.init(std.testing.allocator);
    defer ac.deinit();

    try std.testing.expectEqual(ac.getSumOfProperDivisors(220), 284);
    try std.testing.expectEqual(ac.getSumOfProperDivisors(284), 220);
    try std.testing.expect(try ac.isAmicable(284));
}

fn answer(allocator: Allocator) u64 {
    var ac = AmicableCache.init(allocator);
    defer ac.deinit();
    return ac.sumOfAmicables(10_000) catch @panic("Allocation error");
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 31626);
}
