const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn answer(allocator: Allocator) u64 {
    _ = allocator;

    return 12345;
}

test "simple problem" {
    try std.testing.expectEqual(12, 12);
}

// test "solution" {
//     try std.testing.expectEqual(answer(std.testing.allocator), 12345);
// }
