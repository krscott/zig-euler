const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const iterutil = @import("./iterutil.zig");

pub fn PrimesIter(comptime T: type) type {
    return struct {
        const Self = @This();

        next_index: usize,
        cache: *std.ArrayList(T),

        fn init(cache: *std.ArrayList(T)) Self {
            return Self{
                .next_index = 0,
                .cache = cache,
            };
        }

        pub fn next(self: *Self) ?Allocator.Error!T {
            defer self.next_index += 1;

            if (self.next_index < self.cache.items.len) {
                return self.cache.items[self.next_index];
            }

            if (self.cache.items.len == 0) {
                assert(self.next_index == 0);
                try self.cache.append(2);

                // It is required to add 3 now so we can skip evens
                try self.cache.append(3);

                return 2;
            }

            // `+2` because even numbers greater than 2 are never prime
            var x = self.cache.items[self.cache.items.len - 1] + 2;
            while (true) : (x += 2) {
                for (self.cache.items) |p| {
                    if (x % p == 0) {
                        break;
                    }
                } else {
                    try self.cache.append(x);
                    return x;
                }
            }
        }

        pub usingnamespace iterutil.IteratorMixin(Self);
    };
}

pub fn Primes(comptime T: type) type {
    return struct {
        const Self = @This();

        cache: std.ArrayList(T),

        pub fn init(allocator: Allocator) Self {
            return Self{
                .cache = std.ArrayList(T).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.cache.deinit();
            self.* = undefined;
        }

        /// Create an iterator over all primes
        pub fn iter(self: *Self) PrimesIter(T) {
            return PrimesIter(T).init(&self.cache);
        }

        /// Get n-th prime in the sequence of primes.
        /// Starts at zero. i.e. `get(0) == 2`
        pub fn get(self: *Self, i: usize) Allocator.Error!T {
            if (i >= self.cache.items.len) {
                var it = self.iter();

                while (i >= self.cache.items.len) {
                    // PrimesIter.next() will never return null
                    _ = try (it.next() orelse unreachable);
                }
            }

            return self.cache.items[i];
        }

        pub fn prime_factors(self: *Self, allocator: Allocator, n: T) Allocator.Error!PrimeFactors(T) {
            return PrimeFactors(T).init(allocator, self, n);
        }

        pub fn count_factors(self: *Self, n: T) Allocator.Error!usize {
            var pf = try self.prime_factors(self.cache.allocator, n);
            defer pf.deinit();
            return pf.count();
        }

        pub fn all_factors(self: *Self, allocator: Allocator, n: T) Allocator.Error!std.ArrayList(T) {
            var pf = try self.prime_factors(self.cache.allocator, n);
            defer pf.deinit();

            return pf.factors(allocator);
        }
    };
}

pub fn PrimeFactors(comptime T: type) type {
    return struct {
        const Self = @This();
        const HashMap = std.AutoHashMap(T, usize);

        prime_factor_counts: HashMap,

        fn getPrimeFactorsHelper(primes: *Primes(T), prime_factor_counts: *HashMap, n: T) Allocator.Error!void {
            assert(n > 1);

            var i: usize = 0;

            var prime_factor: T = undefined;

            while (true) : (i += 1) {
                prime_factor = try primes.get(i);

                // std.debug.print("{d} % {d}\n", .{ n, prime_factor });

                if (n % prime_factor == 0) {
                    break;
                }
            }

            try prime_factor_counts.put(prime_factor, 1 + (prime_factor_counts.get(prime_factor) orelse 0));

            if (prime_factor == n) {
                return;
            }

            const cofactor = n / prime_factor;

            // std.debug.print("Factor: {d}, cofactor: {d}\n", .{ prime_factor, cofactor });

            try getPrimeFactorsHelper(primes, prime_factor_counts, cofactor);
        }

        pub fn init(allocator: Allocator, primes: *Primes(T), n: T) Allocator.Error!Self {
            var prime_factor_counts = HashMap.init(allocator);
            try Self.getPrimeFactorsHelper(primes, &prime_factor_counts, n);
            return Self{
                .prime_factor_counts = prime_factor_counts,
            };
        }

        pub fn deinit(self: *Self) void {
            self.prime_factor_counts.deinit();
            self.* = undefined;
        }

        pub fn count(self: *Self) usize {
            var out: usize = 1;
            var iter = self.prime_factor_counts.valueIterator();
            while (iter.next()) |v| {
                out *= v.* + 1;
            }
            return out;
        }

        /// Generate a list of all factors
        pub fn factors(self: *Self, allocator: Allocator) Allocator.Error!std.ArrayList(T) {
            // Create a list of all prime factors, then multiply together every combination.

            var prime_factor_list = std.ArrayList(T).init(allocator);
            defer prime_factor_list.deinit();

            {
                var prime_factor_iter = self.prime_factor_counts.iterator();
                while (prime_factor_iter.next()) |entry| {
                    var i: usize = entry.value_ptr.*;
                    while (i > 0) : (i -= 1) {
                        try prime_factor_list.append(entry.key_ptr.*);
                    }
                }
            }

            var factor_list = std.ArrayList(T).init(allocator);
            try factor_list.append(1);

            var factor_combo_iter = try iterutil.all_combinations(T, allocator, prime_factor_list.items[0..]);
            defer factor_combo_iter.deinit();

            while (factor_combo_iter.next()) |combo| {
                var product: T = 1;
                for (combo) |x| {
                    product *= x;
                }
                if (product != factor_list.items[factor_list.items.len - 1]) {
                    try factor_list.append(product);
                }
            }

            return factor_list;
        }
    };
}

test "PrimesIter and PrimeFactors" {
    var primes = Primes(u64).init(std.testing.allocator);
    defer primes.deinit();

    try std.testing.expectEqual(@as(u64, 8), try primes.count_factors(24));

    var factors = try primes.all_factors(std.testing.allocator, 324);
    defer factors.deinit();

    try std.testing.expectEqualSlices(u64, &.{ 1, 2, 3, 4, 6, 9, 12, 18, 27, 36, 54, 81, 108, 162, 324 }, factors.items);
}
