const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

fn answer() u64 {
    return largestPrimeFactor(600851475143);
}

const PrimeIter = struct {
    const Self = @This();
    primes_list: std.ArrayList(u64),

    pub fn init(allocator: Allocator) Self {
        return Self{
            .primes_list = std.ArrayList(u64).init(allocator),
        };
    }

    pub fn next(self: *Self) !u64 {
        if (self.primes_list.items.len == 0) {
            try self.primes_list.append(2);
            return 2;
        }

        var x = self.primes_list.items[self.primes_list.items.len - 1] + 1;

        while (true) : (x += 1) {
            for (self.primes_list.items) |p| {
                if (x % p == 0) {
                    break;
                }
            } else {
                try self.primes_list.append(x);
                return x;
            }
        }
    }
};

fn largestPrimeFactor(input: u64) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var largestFactor: u64 = 0;
    var x = input;
    var primes = PrimeIter.init(allocator);
    while (true) {
        const p: u64 = primes.next() catch |err| std.debug.panic("{s}\n", .{err});

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
