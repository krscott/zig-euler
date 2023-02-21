const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const iterutil = @import("./common/iterutil.zig");
const permutations = iterutil.permutations;
const initArrayListLen = @import("./common/sliceutil.zig").initArrayListLen;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn getNth(ctx: iterutil.Context(usize, []const u8)) bool {
    return ctx.context - 1 == ctx.index;
}

const LexPermError = error{
    SizeTooBig,
    NMustBeGreaterThan0,
    NoNthPerm,
};

fn getNthLex(allocator: Allocator, size: u8, n: usize) !usize {
    if (n == 0) return error.NMustBeGreaterThan0;
    if (size > 10) return error.SizeTooBig;

    var list = try initArrayListLen(u8, allocator, size);
    defer list.deinit();

    // Fill array with each element's index: .{0, 1, 2, 3, ...}
    {
        var i: u8 = 0;
        while (i < list.items.len) : (i += 1) {
            list.items[i] = i + '0';
        }
    }

    var perm = try permutations(u8, allocator, list.items);
    defer perm.deinit();

    const nth_perm = perm
        .withContext(n)
        .filter(getNth)
        .dropContext()
        .next() orelse return error.NoNthPerm;

    // std.debug.print("{s}\n", .{nth_perm});

    const out = try std.fmt.parseUnsigned(usize, nth_perm, 10);

    return out;
}

fn answer(allocator: Allocator) usize {
    return getNthLex(allocator, 10, 1_000_000) catch @panic("error");
}

test "simple problem" {
    try std.testing.expectEqual(getNthLex(std.testing.allocator, 3, 4), 120);
    try std.testing.expectEqual(getNthLex(std.testing.allocator, 4, 2), 132);
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 2783915460);
}
