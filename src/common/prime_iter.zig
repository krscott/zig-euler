const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub const PrimeIter = struct {
    const Self = @This();

    primes_list: std.ArrayList(u64),

    pub fn init(allocator: Allocator) Self {
        return Self{
            .primes_list = std.ArrayList(u64).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.primes_list.deinit();
    }

    pub fn next(self: *Self) !u64 {
        if (self.primes_list.items.len == 0) {
            try self.primes_list.append(2);
            return 2;
        }

        var x = self.primes_list.items[self.primes_list.items.len - 1] + 1;

        while (true) : (x += 1) {
            for (self.primes_list.items) |p| {
                if (x % p == 0) {
                    break;
                }
            } else {
                try self.primes_list.append(x);
                return x;
            }
        }
    }

    pub fn getNth(self: *Self, i: usize) !u64 {
        while (self.primes_list.items.len <= i) {
            _ = try self.next();
        }
        return self.primes_list.items[i];
    }
};

pub const PrimeFactors = struct {
    const Self = @This();
    const FactorsMap = std.AutoHashMap(u64, usize);

    factors: FactorsMap,

    fn getPrimeFactorsHelper(primes: *PrimeIter, h: *FactorsMap, n: u64) Allocator.Error!void {
        assert(n > 1);

        var i: usize = 0;

        var prime_factor: u64 = undefined;

        while (true) : (i += 1) {
            prime_factor = try primes.getNth(i);

            // std.debug.print("{d} % {d}\n", .{ n, prime_factor });

            if (n % prime_factor == 0) {
                break;
            }
        }

        try h.put(prime_factor, 1 + (h.get(prime_factor) orelse 0));

        if (prime_factor == n) {
            return;
        }

        const cofactor = n / prime_factor;

        // std.debug.print("Factor: {d}, cofactor: {d}\n", .{ prime_factor, cofactor });

        try getPrimeFactorsHelper(primes, h, cofactor);
    }

    pub fn init(allocator: Allocator, primes: *PrimeIter, number: u64) !Self {
        var factors = FactorsMap.init(allocator);
        try PrimeFactors.getPrimeFactorsHelper(primes, &factors, number);
        return Self{
            .factors = factors,
        };
    }

    pub fn deinit(self: *Self) void {
        self.factors.deinit();
    }

    pub fn count(self: *Self) usize {
        var out: usize = 1;
        var iter = self.factors.valueIterator();
        while (iter.next()) |v| {
            out *= v.* + 1;
        }
        return out;
    }
};

test "PrimeIter and PrimeFactors" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var primes = PrimeIter.init(allocator);
    defer primes.deinit();

    var factors_test = try PrimeFactors.init(allocator, &primes, 24);
    defer factors_test.deinit();

    try std.testing.expectEqual(@as(u64, 8), factors_test.count());
}
