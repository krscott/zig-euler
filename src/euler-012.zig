const std = @import("std");
const Allocator = std.mem.Allocator;
const max = std.math.max;
const assert = std.debug.assert;

const iterutil = @import("./common/iterutil.zig");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

/// Iterate over all the triangle numbers.
/// Let's do generics, because why not.
fn TriangleNumbersIter(comptime T: type) type {
    return struct {
        const Self = @This();

        index: T,
        last: T,
        done: bool,

        pub fn init() Self {
            return Self{
                .index = 0,
                .last = 0,
                .done = false,
            };
        }

        pub fn next(self: *Self) ?T {
            if (self.done) return null;

            self.index += 1;
            const n = self.last +% self.index;
            if (n < self.last) {
                self.done = true;
                return null;
            }
            self.last = n;

            return n;
        }
    };
}

/// Iterate over a number's factors.
/// Let's do generics, because why not.
fn FactorsIter(comptime T: type) type {
    return struct {
        const Self = @This();

        base: T,
        lowest_prime: ?T,
        last: T,

        pub fn init(n: T) Self {
            return Self{
                .base = n,
                .lowest_prime = null,
                .last = 0,
            };
        }

        pub fn next(self: *Self) ?T {
            if (self.last == self.base) return null;

            assert(self.last < self.base);

            while (true) {
                self.last = self.last + 1;

                if (self.base % self.last == 0) {
                    break;
                }

                // Short circuit optimization
                if (self.lowest_prime != null and self.last > self.base / self.lowest_prime.?) {
                    self.last = self.base;
                    break;
                }
            }

            if (self.lowest_prime == null and self.last > 1) {
                self.lowest_prime = self.last;
            }

            return self.last;
        }
    };
}

fn countDivisors(input: u64) usize {
    var divs = FactorsIter(u64).init(input);
    const out = iterutil.count(&divs);
    // std.debug.print("{d} has {d} divs\n", .{ input, out });
    return out;
}

fn firstTriangleNumberWithOverNDivisors(n: usize) u64 {
    var tris = TriangleNumbersIter(u64).init();
    var triDivCounts = iterutil.map(countDivisors, &tris);

    while (triDivCounts.next().? <= n) {}

    return tris.last;
}

test "simple problem" {
    try std.testing.expectEqual(firstTriangleNumberWithOverNDivisors(5), 28);
}

fn answer() u64 {
    return firstTriangleNumberWithOverNDivisors(500);
}

// test "solution" {
//     try std.testing.expectEqual(answer(), 12345);
// }
