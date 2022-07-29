const std = @import("std");

const PrimeIter = @import("./common/prime_iter.zig").PrimeIter;
const map = @import("./common/iterutil.zig").map;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn answer() u64 {
    return largestPrimeFactor(600851475143);
}

fn assert_ok(x: PrimeIter.Result) u64 {
    return x catch unreachable;
}

fn largestPrimeFactor(input: u64) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var largestFactor: u64 = 0;
    var x = input;

    var primes = PrimeIter.init(allocator);
    defer primes.deinit();

    var primes_ok = map(assert_ok, primes);

    while (primes_ok.next()) |p| {
        // std.debug.print("{d}\n", .{p});

        if (x % p == 0) {
            largestFactor = p;
            x /= p;
        }

        if (p >= x) {
            break;
        }
    }

    return largestFactor;
}

test "simple problem" {
    try std.testing.expectEqual(largestPrimeFactor(13195), 29);
}

test "solution" {
    try std.testing.expectEqual(answer(), 6857);
}
