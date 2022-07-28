const std = @import("std");
const Allocator = std.mem.Allocator;

pub const PrimeIter = struct {
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

    pub fn skipTo(self: *Self, limit: u64) void {
        while (self.primes_list.items[self.primes_list.items.len - 1] < limit) {
            self.next();
        }
    }
};
