const std = @import("std");

const PrimeIter = @import("./common/prime_iter.zig").PrimeIter;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn nthPrime(n: u64) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var primes = PrimeIter.init(allocator);

    var i: u64 = 1;
    while (true) : (i += 1) {
        const p = primes.next() catch unreachable;
        if (i == n) {
            return p;
        }
    }
}

test "simple problem" {
    try std.testing.expectEqual(nthPrime(6), 13);
}

fn answer() u64 {
    return nthPrime(10001);
}

test "solution" {
    try std.testing.expectEqual(answer(), 104743);
}
