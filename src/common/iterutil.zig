const std = @import("std");

pub fn count(iter: anytype) usize {
    var x: usize = 0;
    while (iter.next() != null) {
        x += 1;
    }
    return x;
}

pub fn MapIter(comptime Iter: type, comptime f: anytype) type {
    const Output: type = @typeInfo(@TypeOf(f)).Fn.return_type.?;

    return struct {
        const Self = @This();

        base: Iter,

        pub fn next(self: *Self) ?Output {
            return f(self.base.next() orelse return null);
        }
    };
}

pub fn map(comptime f: anytype, iter: anytype) MapIter(@TypeOf(iter), f) {
    return MapIter(@TypeOf(iter), f){ .base = iter };
}
