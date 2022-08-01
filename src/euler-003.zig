const std = @import("std");
const Allocator = std.mem.Allocator;

const Primes = @import("./common/primes.zig").Primes;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn answer(allocator: Allocator) u64 {
    return largestPrimeFactor(allocator, 600851475143) catch @panic("Allocation Failed");
}

fn largestPrimeFactor(allocator: Allocator, input: u64) Allocator.Error!u64 {
    var largestFactor: u64 = 0;
    var x = input;

    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    var it = primes.iter();

    while (it.next()) |result| {
        // std.debug.print("{d}\n", .{p});
        const p = try result;

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
    try std.testing.expectEqual(largestPrimeFactor(std.testing.allocator, 13195), 29);
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 6857);
}
