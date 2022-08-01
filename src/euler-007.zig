const std = @import("std");
const assert = std.debug.assert;

const Primes = @import("./common/primes.zig").Primes;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn nthPrime(n: u64) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    // Translate from 1-index to 0-index
    if (n == 0) @panic("nthPrime() sequence starts at 1");
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
