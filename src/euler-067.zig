const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const fsutil = @import("./common/fsutil.zig");
const findBestPath = @import("./euler-018.zig").findBestPath;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn answer(allocator: Allocator) u64 {
    const text = fsutil.readFileAllocPanicking(allocator, "./data/p067_triangle.txt");
    defer allocator.free(text);

    return findBestPath(usize, allocator, text) catch |e| @panic(@errorName(e));
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 7273);
}
