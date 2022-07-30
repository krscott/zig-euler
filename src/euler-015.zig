const std = @import("std");
const Allocator = std.mem.Allocator;
const max = std.math.max;
const min = std.math.min;
const assert = std.debug.assert;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

// There exists a closed-form equation, but let's assume I don't know about
// Pascal's Triangle or binomial coefficients.

const GridSize = [2]u32;
const GridRoutesCache = std.hash_map.AutoHashMap(GridSize, u64);

fn countGridRoutesCached(cache: *GridRoutesCache, size: GridSize) Allocator.Error!u64 {
    if (size[0] == 0 or size[1] == 0) {
        return 1;
    }

    // Optimization: count will be symmetric along diagonal
    const ordered_size: GridSize = .{ max(size[0], size[1]), min(size[0], size[1]) };
    if (cache.get(ordered_size)) |c| {
        return c;
    }

    const right = try countGridRoutesCached(cache, .{ size[0] - 1, size[1] });
    const down = try countGridRoutesCached(cache, .{ size[0], size[1] - 1 });
    const count = right + down;

    try cache.put(ordered_size, count);

    return count;
}

fn countGridRoutes(size: GridSize) u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cache = GridRoutesCache.init(allocator);
    defer cache.deinit();

    const count = countGridRoutesCached(&cache, size) catch unreachable;

    // {
    //     var it = cache.iterator();
    //     while (it.next()) |entry| {
    //         const s: GridSize = entry.key_ptr.*;
    //         const x: u64 = entry.value_ptr.*;
    //         std.debug.print("({d}, {d}): {d}\n", .{ s[0], s[1], x });
    //     }
    // }

    return count;
}

test "simple problem" {
    try std.testing.expectEqual(countGridRoutes(.{ 2, 2 }), 6);
}

fn answer() u64 {
    return countGridRoutes(.{ 20, 20 });
}

test "solution" {
    try std.testing.expectEqual(answer(), 137846528820);
}
