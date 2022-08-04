const std = @import("std");
const Allocator = std.mem.Allocator;
const max = std.math.max;

const iterutil = @import("./common/iterutil.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

const TriGridError = error{
    UncompletedTriangle,
};

fn TriGrid(comptime T: type) type {
    return struct {
        const Self = @This();

        list: std.ArrayList(T),
        height: usize,

        pub fn init(allocator: Allocator, text: []const u8) !Self {
            var list = std.ArrayList(T).init(allocator);
            errdefer list.deinit();

            var iter = iterutil.splitStringWhitespace(text);
            while (iter.next()) |s| {
                const n = try std.fmt.parseUnsigned(T, s, 10);
                try list.append(n);
            }

            var height: usize = 0;
            var i: usize = 0;
            while (i < list.items.len) {
                height += 1;
                i += height;
            }

            if (i != list.items.len) {
                return error.UncompletedTriangle;
            }

            return Self{
                .list = list,
                .height = height,
            };
        }

        pub fn deinit(self: *Self) void {
            self.list.deinit();
        }

        pub fn index(self: *const Self, row: usize, col: usize) ?usize {
            if (col > row) return null;
            const i = (row + 1) * row / 2 + col;
            return if (i < self.list.items.len) i else null;
        }

        pub fn get(self: *const Self, idx: usize) T {
            return self.list.items[idx];
        }

        pub fn set(self: *const Self, idx: usize, value: T) void {
            self.list.items[idx] = value;
        }
    };
}

pub fn findBestPath(comptime T: type, allocator: Allocator, input: []const u8) !T {
    var grid = try TriGrid(T).init(allocator, input);
    defer grid.deinit();

    {
        var r: usize = 1;
        while (r < grid.height) : (r += 1) {
            var c: usize = 0;
            while (c <= r) : (c += 1) {
                var i = grid.index(r, c).?;
                const score = grid.get(i);

                // std.debug.print("{d} ({d}, {d}) {d}\n", .{ i, r, c, score });

                const scoreRight = if (grid.index(r - 1, c)) |j|
                    grid.get(j)
                else
                    0;

                const scoreLeft = if (grid.index(r - 1, c -% 1)) |j|
                    grid.get(j)
                else
                    0;

                // Updating scores in-place, because why not.
                grid.set(i, score + max(scoreLeft, scoreRight));
            }
        }
    }

    var maxScore: T = 0;
    {
        var c: usize = 0;
        while (grid.index(grid.height - 1, c)) |i| : (c += 1) {
            const score = grid.get(i);
            // std.debug.print("{d} {d}\n", .{ i, score });
            if (score > maxScore) maxScore = score;
        }
    }

    return maxScore;
}

test "simple problem" {
    const text =
        \\   3
        \\  7 4
        \\ 2 4 6
        \\8 5 9 3
    ;

    try std.testing.expectEqual(findBestPath(usize, std.testing.allocator, text), 23);
}

fn answer(allocator: Allocator) u64 {
    const text =
        \\75
        \\95 64
        \\17 47 82
        \\18 35 87 10
        \\20 04 82 47 65
        \\19 01 23 75 03 34
        \\88 02 77 73 07 63 67
        \\99 65 04 28 06 16 70 92
        \\41 41 26 56 83 40 80 70 33
        \\41 48 72 33 47 32 37 16 94 29
        \\53 71 44 65 25 43 91 52 97 51 14
        \\70 11 33 28 77 73 17 78 39 68 17 57
        \\91 71 52 38 17 14 91 43 58 50 27 29 48
        \\63 66 04 68 89 53 67 30 73 16 69 87 40 31
        \\04 62 98 27 23 09 70 98 73 93 38 53 60 04 23
    ;

    return findBestPath(usize, allocator, text) catch @panic("error");
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 1074);
}
