const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

// Note: This method does not finish in time
// TODO: Faster solution!

const Compare = enum {
    Less,
    Equal,
    Greater,
};

const Tu: type = u128;

fn probRelHalf(blues: Tu, total: Tu) Compare {
    const num = 2 * blues * (blues - 1);
    const den = total * (total - 1);

    if (num < den) return .Less;
    if (num > den) return .Greater;
    return .Equal;
}

fn closedForm(total: Tu) Tu {
    const t = @intToFloat(f64, total);
    return @floatToInt(Tu, std.math.sqrt(0.5 * t * t - 0.5 * t - 1.0) + 0.5);
}

fn findNextBlues(total: Tu) [2]Tu {
    var t: Tu = total;
    var b: Tu = closedForm(total);

    while (true) {
        switch (probRelHalf(b, t)) {
            .Equal => return .{ b, t },
            .Greater => {
                t += 1;
                // print("t {}\n", .{t});
            },
            .Less => {
                b += 1;
                // print("b {}\n", .{b});
            },
        }
    }
}

fn answer(allocator: Allocator) Tu {
    _ = allocator;
    const bt = findNextBlues(1_000_000_000_000);
    print("Blues: {}, Total: {}", .{ bt[0], bt[1] });
    return bt[0];
}

test "simple problem" {
    try std.testing.expectEqual(findNextBlues(21), .{ 15, 21 });
    try std.testing.expectEqual(findNextBlues(22), .{ 85, 85 + 35 });
}

// test "solution" {
//     try std.testing.expectEqual(answer(std.testing.allocator), 12345);
// }
