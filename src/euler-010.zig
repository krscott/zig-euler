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

fn sumOfPrimesBelow(allocator: Allocator, x: u64) Allocator.Error!u64 {
    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    var sum: u64 = 0;

    var it = primes.iter();
    while (it.next()) |result| {
        // std.debug.print("{d}\n", .{p});
        const p = try result;

        if (p >= x) {
            break;
        }

        sum += p;
    }

    return sum;
}

test "simple problem" {
    try std.testing.expectEqual(sumOfPrimesBelow(std.testing.allocator, 10), 17);
}

fn answer(allocator: Allocator) u64 {
    return sumOfPrimesBelow(allocator, 2_000_000) catch @panic("Allocation Failed");
}

// This takes a long time
// test "solution" {
//     try std.testing.expectEqual(answer(), 142913828922);
// }
