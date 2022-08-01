const std = @import("std");
const Allocator = std.mem.Allocator;

const Primes = @import("./common/primes.zig").Primes;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn panic_on_error(x: Allocator.Error!u64) u64 {
    return x catch @panic("Allocation Failed");
}

fn sumOfPrimesBelow(x: u64) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    var it = primes.iter().map(panic_on_error);

    var sum: u64 = 0;

    while (it.next()) |p| {
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
