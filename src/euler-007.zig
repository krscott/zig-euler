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

fn nthPrime(allocator: Allocator, n: u64) Allocator.Error!u64 {
    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    // Translate from 1-index to 0-index
    if (n == 0) @panic("nthPrime() sequence starts at 1");
    return primes.get(n - 1);
}

test "simple problem" {
    try std.testing.expectEqual(try nthPrime(std.testing.allocator, 6), 13);
}

fn answer(allocator: Allocator) u64 {
    return nthPrime(allocator, 10001) catch @panic("Allocation Error");
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 104743);
}
