const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const iterutil = @import("./common/iterutil.zig");
const BigDecimal = @import("./common/bigdecimal.zig").BigDecimal;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

const BigFibIter = struct {
    const Self = @This();
    pub usingnamespace iterutil.IteratorMixin(Self);

    a: BigDecimal,
    b: BigDecimal,

    pub fn init(allocator: Allocator) !Self {
        return Self{
            .a = BigDecimal.init(allocator),
            .b = try BigDecimal.initFromInt(allocator, 1),
        };
    }

    pub fn deinit(self: *Self) void {
        self.a.deinit();
        self.b.deinit();
        self.* = undefined;
    }

    pub fn next(self: *Self) ?Allocator.Error![]const u8 {
        const tmp = self.b;
        try self.a.add(&self.b);
        self.b = self.a;
        self.a = tmp;

        return self.a.slice;
    }
};

fn hasNDigits(ctx: anytype) bool {
    return ctx.data.len == ctx.context;
}

fn panicOnError(x: Allocator.Error![]const u8) []const u8 {
    return x catch @panic("alloc");
}

fn indexOfFibWithNDigits(allocator: Allocator, n: usize) !usize {
    var fib = (try BigFibIter.init(allocator));
    defer fib.deinit();

    return fib
        .map(panicOnError)
        .withContext(n)
        .filter(hasNDigits)
        .next().?
        .index + 1;
}

fn answer(allocator: Allocator) u64 {
    return indexOfFibWithNDigits(allocator, 1000) catch @panic("alloc");
}

test "simple problem" {
    try std.testing.expectEqual(
        indexOfFibWithNDigits(std.testing.allocator, 3),
        12,
    );
}

// test "solution" {
//     try std.testing.expectEqual(answer(std.testing.allocator), 12345);
// }
