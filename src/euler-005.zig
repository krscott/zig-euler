const std = @import("std");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn smallestMultiple(divisors_up_to: u64) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Generate minimal set of divisors from 1 to `divisors_up_to`
    var divisors_list = std.ArrayList(u64).init(allocator);
    {
        var x = divisors_up_to;
        while (x > 1) : (x -= 1) {
            for (divisors_list.items) |d| {
                if (d % x == 0) {
                    // This divisor is redundant
                    break;
                }
            } else {
                divisors_list.append(x) catch |e| std.debug.panic("{s}\n", .{e});
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
    try std.testing.expectEqual(smallestMultiple(10), 2520);
}

fn answer() u64 {
    return smallestMultiple(20);
}

test "solution" {
    try std.testing.expectEqual(answer(), 232792560);
}
