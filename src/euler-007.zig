const std = @import("std");
const assert = std.debug.assert;

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
    defer primes.deinit();

    // Translate from 1-index to 0-index
    assert(n > 0);
    return primes.get(n - 1) catch unreachable;
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
