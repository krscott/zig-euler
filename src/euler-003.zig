const std = @import("std");
const Allocator = std.mem.Allocator;

const Primes = @import("./common/primes.zig").Primes;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn answer() u64 {
    return largestPrimeFactor(600851475143);
}

fn panic_on_error(x: Allocator.Error!u64) u64 {
    return x catch @panic("Allocation Failed");
}

fn largestPrimeFactor(input: u64) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var largestFactor: u64 = 0;
    var x = input;

    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    var it = primes.iter().map(panic_on_error);

    while (it.next()) |p| {
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
