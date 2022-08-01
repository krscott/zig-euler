const std = @import("std");
const Allocator = std.mem.Allocator;

const BigDecimal = @import("./common/bigdecimal.zig").BigDecimal;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn sumOfDigitsOfPowerOf2(allocator: Allocator, p: usize) Allocator.Error!u64 {
    var a = try BigDecimal.initFromStr(allocator, "1");
    defer a.deinit();

    {
        var i: usize = 0;
        while (i < p) : (i += 1) {
            try a.multiplyStr("2");
        }
    }

    // std.debug.print("{s}\n", .{a.slice});

    var total: u64 = 0;
    for (a.slice) |c| {
        total += c - '0';
    }

    return total;
}

test "simple problem" {
    try std.testing.expectEqual(sumOfDigitsOfPowerOf2(std.testing.allocator, 15), 26);
}

fn answer(allocator: Allocator) u64 {
    return sumOfDigitsOfPowerOf2(allocator, 1000) catch @panic("allocation error");
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 1366);
}
