const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const fitting = @import("./common/fitting.zig");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

//
// This is a brute-force solution
//
// I noticed the first few solutions were increasing exponentially.
// So, this program starts by brute-forcing the first few integer solutions,
// then uses a least-squares exponential curve fit to approximate the first
// solution over 10^12, then brute-forces the percise solution from that point.
//
// It finishes in 0.159s--much faster than learning about diophantine equations.
//

const Compare = enum {
    Less,
    Equal,
    Greater,
};

const Tu: type = u128;
const Tf: type = f128;

const Discs = struct {
    blues: Tu,
    total: Tu,

    pub fn reds(self: *const @This()) Tu {
        return self.total - self.blues;
    }
};

fn probRelHalf(blues: Tu, total: Tu) Compare {
    const num = 2 * blues * (blues - 1);
    const den = total * (total - 1);

    if (num < den) return .Less;
    if (num > den) return .Greater;
    return .Equal;
}

fn closedFormBluesFromTotal(total: Tu) Tu {
    const t = @intToFloat(Tf, total);
    return @floatToInt(Tu, std.math.sqrt(0.5 * t * t - 0.5 * t - 1.0) + 0.5);
}

fn findNextHalfProb(blues: Tu, total: Tu) Discs {
    var t: Tu = total;
    var b: Tu = blues;

    while (true) {
        switch (probRelHalf(b, t)) {
            .Equal => return Discs{ .blues = b, .total = t },
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

const DiscsExpFit = struct {
    const Self = @This();

    blues: fitting.ExponentialLeastSquares(Tf),
    total: fitting.ExponentialLeastSquares(Tf),

    pub fn init(comptime n: usize) @This() {
        var indices: [n]Tf = undefined;
        var blues_data: [n]Tf = undefined;
        var total_data: [n]Tf = undefined;

        var i: usize = 0;
        var b: Tu = 21;
        var t: Tu = 15;
        while (i < n) : (i += 1) {
            const discs = findNextHalfProb(b, t);
            // print("{}: Blues: {}, Reds: {}, Total: {}\n", .{ i, discs.blues, discs.reds(), discs.total });

            indices[i] = @intToFloat(Tf, i);
            blues_data[i] = @intToFloat(Tf, discs.blues);
            total_data[i] = @intToFloat(Tf, discs.total);

            b = discs.blues + 1;
            t = discs.total + 1;
        }

        return Self{
            .blues = fitting.ExponentialLeastSquares(Tf).fit(&indices, &blues_data),
            .total = fitting.ExponentialLeastSquares(Tf).fit(&indices, &total_data),
        };
    }
};

fn answer(allocator: Allocator) Tu {
    _ = allocator;

    // Naive solution (Too slow)
    // {
    //     var t: Tu = 1_000_000_000_000.0;
    //     var b: Tu = closedFormBluesFromTotal(t);
    //     const discs = findNextHalfProb(b, t);
    //     print("Blues: {}, Reds: {}, Total: {}\n", .{ discs.blues, discs.reds(), discs.total });
    //     return discs.blues;
    // }

    // Exploration
    // {
    //     var b: Tu = 15;
    //     var t: Tu = 21;
    //     while (t < 1_000_000) : (t += 1) {
    //         const discs = findNextHalfProb(b, t);
    //         print("Blues: {}, Reds: {}, Total: {}\n", .{ discs.blues, discs.reds(), discs.total });
    //         t = discs.total;
    //     }
    // }

    // More-optimized solution

    //
    // Step 1: Find an exponential function approximating the n-th solution
    //

    // `n` input here is arbitrary. It just needs to be high enough to get a good fit.
    // The higher n is, the longer DiscsExpFit will take to run
    // The lower n is, the longer findNextHalfProb loop will take to run
    const discs_exp = DiscsExpFit.init(8);
    // print("Blues Ae^Bx A: {}, B: {}\n", .{ discs_exp.blues.a, discs_exp.blues.b });

    //
    // Step 2: Find first approximate solution for which total >= 10^12
    //

    const min_total: Tf = 1_000_000_000_000.0;
    var x: Tf = 0;
    var total: Tf = 0;
    while (true) : (x += 1.0) {
        total = discs_exp.total.eval(x);
        // print("{}: Total: {}\n", .{ x, total });

        if (total >= min_total) break;
    }
    // print("{}: Total: {}\n", .{ x, total });

    //
    // Step 3: Calculate actual solution given approximation as starting-point.
    //

    // (Assume discs_exp underestimates actual solution.)
    const result = findNextHalfProb(
        @floatToInt(Tu, discs_exp.blues.eval(x)),
        @floatToInt(Tu, total),
    );
    // print("Blues: {}, Total: {}\n", .{ result.blues, result.total });

    return result.blues;
}

test "simple problem" {
    try std.testing.expectEqual(findNextHalfProb(closedFormBluesFromTotal(21), 21), Discs{ .blues = 15, .total = 21 });
    try std.testing.expectEqual(findNextHalfProb(closedFormBluesFromTotal(22), 22), Discs{ .blues = 85, .total = 85 + 35 });
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 756872327473);
}
