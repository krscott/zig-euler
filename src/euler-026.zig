const std = @import("std");
const Allocator = std.mem.Allocator;
const max = std.math.max;
const assert = std.debug.assert;

const iterutil = @import("./common/iterutil.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

const LongDivIter = struct {
    const Self = @This();
    pub usingnamespace iterutil.IteratorMixin(Self);

    const Item = struct {
        dot_pos: isize,
        d: u64,
        r: u64,
        q_digit_char: u8,
    };

    div_shift: u64,
    divisor: u64,
    state: Item,

    pub fn init(dividend: u64, divisor: u64) Self {
        // Some shenannigans to shift output so we don't have to buffer chars
        var dot_pos: isize = 1;
        var div_shift: u64 = 10;
        {
            var x = dividend * 10 / divisor;
            while (x >= 10) : (x /= 10) {
                dot_pos += 1;
                div_shift *= 10;
            }
        }
        // {
        //     var x = dividend * 10 / divisor;
        //     while (x > 10) : (x /= 10) {
        //         div_shift *= 10;
        //     }
        // }

        return Self{
            .div_shift = max(1, div_shift),
            .divisor = divisor,
            .state = Item{
                .dot_pos = dot_pos,
                .q_digit_char = 0,
                .d = dividend,
                .r = 0,
            },
        };
    }

    pub fn next(self: *Self) ?Item {
        if (self.state.d == 0) return null;

        var x = self.state.d * 10 / self.div_shift;
        var y = self.state.d * 10 % self.div_shift;

        var r = x % self.divisor;
        var q = x / self.divisor;
        var d = x - q * self.divisor;

        // std.debug.print(" (d:{d} r:{d} q:{d}) ", .{ d, r, q });

        self.state = Item{
            .dot_pos = self.state.dot_pos - 1,
            .d = d * self.div_shift + y,
            .r = r,
            .q_digit_char = @intCast(u8, q) + '0',
        };

        return self.state;
    }
};

const enableDebugPrint = false;

fn divRepeatingLen(allocator: Allocator, dividend: u64, divisor: u64) !isize {
    var states = std.AutoHashMap([2]u64, isize).init(allocator);
    defer states.deinit();

    var it = LongDivIter.init(dividend, divisor);

    if (enableDebugPrint) std.debug.print("{d} / {d} = ", .{ dividend, divisor });

    while (it.next()) |state| {
        if (enableDebugPrint) {
            if (state.dot_pos == -1) std.debug.print(".", .{});
            std.debug.print("{c}", .{state.q_digit_char});
        }

        const key = .{ state.d, state.r };
        if (states.get(key)) |v| {
            const out = v - state.dot_pos;
            if (enableDebugPrint) std.debug.print(" (repeat last {d})\n", .{out});
            return out;
        }

        try states.put(key, state.dot_pos);
    }

    // No repeating pattern
    if (enableDebugPrint) std.debug.print("\n", .{});
    return 0;
}

fn answer(allocator: Allocator) u64 {
    var max_cycle: isize = 0;
    var max_i: u64 = 0;
    var i: u64 = 7;
    while (i < 1000) : (i += 1) {
        const cycle = divRepeatingLen(allocator, 1, i) catch @panic("alloc");
        if (cycle > max_cycle) {
            max_cycle = cycle;
            max_i = i;
        }
    }
    return max_i;
}

test "simple problem" {
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 2), 0);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 3), 1);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 4), 0);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 5), 0);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 6), 1);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 7), 6);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 8), 0);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 9), 1);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 10), 0);

    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1, 300), 1);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 10, 3000), 1);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 1000, 300000), 1);

    // TODO: Fix unnecessary leading zeroes with these cases:
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 100, 7), 6);
    try std.testing.expectEqual(divRepeatingLen(std.testing.allocator, 10000, 7), 6);
}

// test "solution" {
//     try std.testing.expectEqual(answer(std.testing.allocator), 12345);
// }
