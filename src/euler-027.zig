const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const primelib = @import("./common/primes.zig");
const PrimeLookup = primelib.PrimeLookup;
const Primes = primelib.Primes;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn getPrimeSeqLen(prime_lookup: *PrimeLookup(i64), a: i64, b: i64) Allocator.Error!i64 {
    var n: i64 = 0;

    while (true) : (n += 1) {
        const x = n * n + a * n + b;
        if (!try prime_lookup.isPrime(x)) break;
    }

    return n;
}

fn answer(allocator: Allocator) i64 {
    var primes = Primes(i64).init(allocator);
    defer primes.deinit();

    var prime_lookup = primes.lookup(allocator);
    defer prime_lookup.deinit();

    var max_n: i64 = 0;
    var max_n_a: i64 = 0;
    var max_n_b: i64 = 0;

    // "where |a| < 1000 and |b| <= 1000"
    var a: i64 = -999;
    while (a <= 999) : (a += 1) {
        var b: i64 = -1000;
        while (b <= 1000) : (b += 1) {
            const n = getPrimeSeqLen(&prime_lookup, a, b) catch @panic("alloc");
            if (n > max_n) {
                max_n = n;
                max_n_a = a;
                max_n_b = b;
            }
        }
    }

    // std.debug.print("a = {d}, b = {d}, n = {d}\n", .{ max_n_a, max_n_b, max_n });

    return max_n_a * max_n_b;
}

test "simple problem" {
    var primes = Primes(i64).init(std.testing.allocator);
    defer primes.deinit();

    var prime_lookup = primes.lookup(std.testing.allocator);
    defer prime_lookup.deinit();

    try std.testing.expectEqual(getPrimeSeqLen(&prime_lookup, 1, 41), 40);
    try std.testing.expectEqual(getPrimeSeqLen(&prime_lookup, -79, 1601), 80);
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), -59231);
}
