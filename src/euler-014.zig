const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

const CollatzCache = std.hash_map.AutoHashMap(u64, u64);

fn collatzLength(cache: *CollatzCache, n: u64) Allocator.Error!u64 {
    if (n <= 1) {
        assert(n == 1);
        return 1;
    }

    if (cache.get(n)) |l| {
        return l;
    }

    const next_n = if (n % 2 == 0) (n / 2) else (3 * n + 1);
    const cl = 1 + try collatzLength(cache, next_n);
    try cache.put(n, cl);
    return cl;
}

/// Naive implementation of Collatz length.
/// Too slow for repeated callings.
fn naiveCollatzLength(n: u64) u64 {
    var x = n;
    var count: u64 = 1;
    while (x != 1) : (count += 1) {
        x = switch (x % 2) {
            0 => x / 2,
            1 => 3 * x + 1,
            else => unreachable,
        };
    }
    return count;
}

fn maxCollatzLength(allocator: Allocator, under: u64) u64 {
    var cache = CollatzCache.init(allocator);
    defer cache.deinit();

    var longest_len: u64 = 0;
    var longest_len_i: u64 = 1;
    var i: u64 = 1;
    while (i < under) : (i += 1) {
        const l = collatzLength(&cache, i) catch unreachable;
        if (l > longest_len) {
            longest_len = l;
            longest_len_i = i;
        }
    }
    return longest_len_i;
}

test "simple problem" {
    try std.testing.expectEqual(naiveCollatzLength(13), 10);

    // https://en.wikipedia.org/wiki/Collatz_conjecture
    try std.testing.expectEqual(maxCollatzLength(std.testing.allocator, 100), 97);
}

fn answer(allocator: Allocator) u64 {
    return maxCollatzLength(allocator, 1_000_000);
}

test "solution" {
    try std.testing.expectEqual(answer(
        std.testing.allocator,
    ), 837799);
}
