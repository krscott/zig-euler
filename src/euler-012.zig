const std = @import("std");
const Allocator = std.mem.Allocator;
const max = std.math.max;
const assert = std.debug.assert;

const Primes = @import("./common/primes.zig").Primes;

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

fn firstTriangleNumberWithOverNDivisors(n: usize) u64 {
    if (n == 0) return 1;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    var tris = TriangleNumbersIter(u64).init();

    while (tris.next()) |tri| {
        if (tri == 1) continue;

        const count = primes.count_prime_factors(tri) catch @panic("Allocation failed");

        // std.debug.print("{d} has {d} factors\n", .{ tri, count });

        if (count > n) {
            return tri;
        }
    }

    unreachable;
}

test "simple problem" {
    try std.testing.expectEqual(firstTriangleNumberWithOverNDivisors(5), 28);
}

fn answer() u64 {
    return firstTriangleNumberWithOverNDivisors(500);
}

test "solution" {
    try std.testing.expectEqual(answer(), 76576500);
}
