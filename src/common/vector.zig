const std = @import("std");
const sqrt = std.math.sqrt;

pub fn Vec2(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn init(x: T, y: T) Self {
            return Self{
                .x = x,
                .y = y,
            };
        }

        pub fn add(self: Self, other: Self) Self {
            return Self{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return Self{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub fn mag(self: Self) T {
            return sqrt(self.x * self.x + self.y * self.y);
        }

        pub fn det(self: Self, other: Self) T {
            return self.x * other.y - self.y * other.x;
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y;
        }

        pub fn cosAngleTo(self: Self, point: Self) T {
            return self.dot(point) / (self.mag() * point.mag());
        }

        pub fn innerAngle(self: Self, point: Self) T {
            return std.math.acos(self.cosAngleTo(point));
        }

        pub fn angle(self: Self, point: Self) T {
            return std.math.atan2(T, self.det(point), self.dot(point));
        }
    };
}

test "dot product" {
    const u = Vec2(f64).init(2, 2);
    const v = Vec2(f64).init(0, 3);

    try std.testing.expectApproxEqAbs(@as(f64, 6.0), u.dot(v), 0.001);
}

test "inner angle" {
    const u = Vec2(f64).init(2, 2);
    const v = Vec2(f64).init(0, 3);

    try std.testing.expectApproxEqAbs(@as(f64, sqrt(2.0) / 2.0), u.cosAngleTo(v), 0.001);
    try std.testing.expectApproxEqAbs(@as(f64, std.math.pi / 4.0), u.innerAngle(v), 0.001);
}
