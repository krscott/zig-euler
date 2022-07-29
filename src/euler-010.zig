const std = @import("std");

const PrimeIter = @import("./common/prime_iter.zig").PrimeIter;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn sumOfPrimesBelow(x: u64) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var primes = PrimeIter.init(allocator);

    var sum: u64 = 0;

    while (true) {
        const p = primes.next() catch unreachable;

        if (p >= x) {
            break;
        }

        sum += p;
    }

    return sum;
}

test "simple problem" {
    try std.testing.expectEqual(sumOfPrimesBelow(10), 17);
}

fn answer() u64 {
    return sumOfPrimesBelow(2_000_000);
}

// This takes a long time
// test "solution" {
//     try std.testing.expectEqual(answer(), 142913828922);
// }
