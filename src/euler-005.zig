const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn smallestMultiple(allocator: Allocator, divisors_up_to: u64) Allocator.Error!u64 {
    // Generate minimal set of divisors from 1 to `divisors_up_to`
    var divisors_list = std.ArrayList(u64).init(allocator);
    defer divisors_list.deinit();

    {
        var x = divisors_up_to;
        while (x > 1) : (x -= 1) {
            for (divisors_list.items) |d| {
                if (d % x == 0) {
                    // This divisor is redundant
                    break;
                }
            } else {
                try divisors_list.append(x);
            }
        }
    }

    // Find smallest number evenly divisable by all divisors
    {
        var x: u64 = 1;
        outer: while (true) : (x += 1) {
            for (divisors_list.items) |d| {
                if (x % d != 0) {
                    continue :outer;
                }
            }

            return x;
        }
    }
}

test "simple problem" {
    try std.testing.expectEqual(smallestMultiple(std.testing.allocator, 10), 2520);
}

fn answer(allocator: Allocator) u64 {
    return smallestMultiple(allocator, 20) catch @panic("Allocation Error");
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 232792560);
}
