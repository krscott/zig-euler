const std = @import("std");
const assert = std.debug.assert;

const printSlice = @import("./sliceutil.zig").printSlice;

/// A*e^(Bx)
pub fn ExponentialLeastSquares(comptime T: type) type {
    return struct {
        const Self = @This();

        a: T,
        b: T,

        pub fn fit(x: []const T, y: []const T) Self {
            assert(x.len > 0);
            assert(x.len == y.len);

            // https://mathworld.wolfram.com/LeastSquaresFittingExponential.html (9), (10)

            // Component Sums
            var s_x2y: T = 0;
            var s_ylny: T = 0;
            var s_xy: T = 0;
            var s_xylny: T = 0;
            var s_y: T = 0;

            var i: usize = 0;
            while (i < x.len) : (i += 1) {
                const xi = x[i];
                const yi = y[i];
                const lnyi = std.math.ln(yi);
                s_x2y += xi * xi * yi;
                s_ylny += yi * lnyi;
                s_xy += xi * yi;
                s_xylny += xi * yi * lnyi;
                s_y += yi;
            }

            const div = (s_y * s_x2y - s_xy * s_xy);
            const ln_a = (s_x2y * s_ylny - s_xy * s_xylny) / div;
            const b = (s_y * s_xylny - s_xy * s_ylny) / div;

            return Self{
                .a = std.math.exp(ln_a),
                .b = b,
            };
        }

        pub fn eval(self: *const Self, x: T) T {
            return self.a * std.math.exp(self.b * x);
        }
    };
}

test "exp fitting" {
    const a: f128 = 0.456;
    const b: f128 = 1.23;

    const x: [6]f128 = .{ 1.0, 2.0, 5.0, 10.0, 20.0, 50.0 };
    var y: [6]f128 = undefined;
    for (x) |xi, i| {
        y[i] = a * std.math.exp(b * xi);
    }

    // printSlice("y: [{}, ]\n", y);

    const fit = ExponentialLeastSquares(f128).fit(x[0..], y[0..]);

    try std.testing.expectApproxEqAbs(a, fit.a, 0.001);
    try std.testing.expectApproxEqAbs(b, fit.b, 0.001);
}
