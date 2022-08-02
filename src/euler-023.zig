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

/// Because @sizeOf(?bool) is two bytes, but I only need one trit.
const MaybeBool = enum {
    True,
    False,
    FileNotFound,
};

const AbundantCache = struct {
    const limit = 28123;
    const Self = @This();

    allocator: Allocator,
    primes: Primes(usize),
    known_abundants: []MaybeBool,
    known_sum_of_abundants: []bool,

    pub fn init(allocator: Allocator) !Self {
        var self = Self{
            .allocator = allocator,
            .primes = Primes(usize).init(allocator),
            .known_abundants = try allocator.alloc(MaybeBool, limit),
            .known_sum_of_abundants = try allocator.alloc(bool, limit),
        };

        std.mem.set(MaybeBool, self.known_abundants, MaybeBool.FileNotFound);
        std.mem.set(bool, self.known_sum_of_abundants, false);

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.primes.deinit();
        self.allocator.free(self.known_abundants);
        self.allocator.free(self.known_sum_of_abundants);
        self.* = undefined;
    }

    pub fn isAbundant(self: *Self, n: usize) !bool {
        if (n >= limit) @panic("n too big");
        return switch (self.known_abundants[n]) {
            .FileNotFound => b: {
                if ((try self.primes.sumOfProperDivisors(n)) > n) {
                    self.known_abundants[n] = .True;
                    break :b true;
                } else {
                    self.known_abundants[n] = .False;
                    break :b false;
                }
            },
            .True => true,
            .False => false,
        };
    }

    pub fn checkAbundantSums(self: *Self, a: usize, b: usize) !void {
        if (a + b >= limit) return;
        if ((try self.isAbundant(a)) and (try self.isAbundant(b))) {
            self.known_sum_of_abundants[a + b] = true;
        }
    }

    pub fn isKnownSumOfAbundants(self: *Self, n: usize) bool {
        if (n > limit) return true;
        return self.known_sum_of_abundants[n];
    }
};

fn answer(allocator: Allocator) usize {
    // Upper limits for abundant numbers we need to actually check
    const upper = 28123;

    var abundants = AbundantCache.init(allocator) catch @panic("Allocation error");
    defer abundants.deinit();

    var a: usize = 1;
    while (a < upper) : (a += 1) {
        var b: usize = a;
        while (a + b < upper) : (b += 1) {
            abundants.checkAbundantSums(a, b) catch @panic("error");
        }
    }

    var sum_non_abundants: usize = 0;
    var i: usize = 1;
    while (i < upper) : (i += 1) {
        if (!abundants.isKnownSumOfAbundants(i)) {
            sum_non_abundants += i;
        }
    }

    return sum_non_abundants;
}

test "simple problem" {
    var abundants = try AbundantCache.init(std.testing.allocator);
    defer abundants.deinit();

    try std.testing.expectEqual(abundants.isAbundant(28), false);
    try std.testing.expectEqual(abundants.isAbundant(12), true);
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 4179871);
}
