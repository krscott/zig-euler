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
                return 2;
            }

            var x = self.cache.items[self.cache.items.len - 1] + 1;

            while (true) : (x += 1) {
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

        pub fn prime_factors(self: *Self, n: T) Allocator.Error!PrimeFactors(T) {
            return PrimeFactors(T).init(self.cache.allocator, self, n);
        }

        pub fn count_prime_factors(self: *Self, n: T) Allocator.Error!usize {
            var pf = try self.prime_factors(n);
            defer pf.deinit();
            return pf.count();
        }
    };
}

pub fn PrimeFactors(comptime T: type) type {
    return struct {
        const Self = @This();
        const HashMap = std.AutoHashMap(T, usize);

        factors: HashMap,

        fn getPrimeFactorsHelper(primes: *Primes(T), factors: *HashMap, n: T) Allocator.Error!void {
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

            try factors.put(prime_factor, 1 + (factors.get(prime_factor) orelse 0));

            if (prime_factor == n) {
                return;
            }

            const cofactor = n / prime_factor;

            // std.debug.print("Factor: {d}, cofactor: {d}\n", .{ prime_factor, cofactor });

            try getPrimeFactorsHelper(primes, factors, cofactor);
        }

        pub fn init(allocator: Allocator, primes: *Primes(T), n: T) Allocator.Error!Self {
            var factors = HashMap.init(allocator);
            try Self.getPrimeFactorsHelper(primes, &factors, n);
            return Self{
                .factors = factors,
            };
        }

        pub fn deinit(self: *Self) void {
            self.factors.deinit();
            self.* = undefined;
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
}

test "PrimesIter and PrimeFactors" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    try std.testing.expectEqual(@as(u64, 8), try primes.count_prime_factors(24));
}
