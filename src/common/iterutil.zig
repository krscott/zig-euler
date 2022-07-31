const std = @import("std");
const sliceutil = @import("./sliceutil.zig");
const contains = sliceutil.contains;

pub fn count(iter: anytype) usize {
    var it = iter;
    var x: usize = 0;
    while (it.next()) |_| {
        x += 1;
    }
    return x;
}

pub fn Context(comptime ContextType: type, comptime DataType: type) type {
    return struct {
        context: ContextType,
        data: DataType,
    };
}

pub fn ContextIter(comptime ContextType: type, comptime Iter: type) type {
    const DataType: type = @typeInfo(@typeInfo(@TypeOf(Iter.next)).Fn.return_type.?).Optional.child;

    return struct {
        const Self = @This();

        context: ContextType,
        base: Iter,

        pub fn next(self: *Self) ?Context(ContextType, DataType) {
            return Context(ContextType, DataType){ .context = self.context, .data = self.base.next() orelse return null };
        }
    };
}

pub fn with_context(context: anytype, iter: anytype) ContextIter(@TypeOf(context), @TypeOf(iter)) {
    return ContextIter(@TypeOf(context), @TypeOf(iter)){ .context = context, .base = iter };
}

pub fn MapIter(comptime f: anytype, comptime Iter: type) type {
    const Output: type = @typeInfo(@TypeOf(f)).Fn.return_type.?;

    return struct {
        const Self = @This();

        base: Iter,

        pub fn next(self: *Self) ?Output {
            return f(self.base.next() orelse return null);
        }
    };
}

pub fn map(comptime f: anytype, iter: anytype) MapIter(f, @TypeOf(iter)) {
    return MapIter(f, @TypeOf(iter)){ .base = iter };
}

pub fn FilterIter(comptime f: anytype, comptime Iter: type) type {
    const Output: type = @typeInfo(@typeInfo(@TypeOf(Iter.next)).Fn.return_type.?).Optional.child;

    return struct {
        const Self = @This();

        base: Iter,

        pub fn next(self: *Self) ?Output {
            while (self.base.next()) |x| {
                if (f(x) == true) {
                    return x;
                }
            }
            return null;
        }
    };
}

pub fn filter(comptime f: anytype, iter: anytype) FilterIter(f, @TypeOf(iter)) {
    return FilterIter(f, @TypeOf(iter)){ .base = iter };
}

pub fn UntilIter(comptime f: anytype, comptime Iter: type) type {
    const Output: type = @typeInfo(@typeInfo(@TypeOf(Iter.next)).Fn.return_type.?).Optional.child;

    return struct {
        const Self = @This();

        base: Iter,

        pub fn next(self: *Self) ?Output {
            const x = self.base.next() orelse return null;
            return if (f(x)) null else x;
        }
    };
}

pub fn until(comptime f: anytype, iter: anytype) UntilIter(f, @TypeOf(iter)) {
    return UntilIter(f, @TypeOf(iter)){ .base = iter };
}

pub fn SplitDelimIter(comptime T: type) type {
    return struct {
        const Self = @This();

        input: []const T,
        delims: []const T,

        pub fn init(input: []const T, delims: []const T) Self {
            return Self{
                .input = input,
                .delims = delims,
            };
        }

        pub fn next(self: *Self) ?[]const T {
            if (self.input.len == 0) return null;

            {
                var i: usize = 0;

                // Advance over leading delimiter chars
                while (i < self.input.len and contains(T, self.delims, self.input[i])) : (i += 1) {}

                // Check if end of the string was reached
                if (i == self.input.len) {
                    self.input = &.{};
                    return null;
                }

                // Trim leading delimeters
                self.input = self.input[i..];
            }

            {
                var i: usize = 0;

                // Advance until reaching a delimeter char
                while (i < self.input.len and !contains(T, self.delims, self.input[i])) : (i += 1) {}

                // Create slice from match
                const out = self.input[0..i];

                // Remove returned slice
                if (i == self.input.len) {
                    self.input = &.{};
                } else {
                    self.input = self.input[i..];
                }

                return out;
            }
        }
    };
}

pub fn splitStringDelims(input: []const u8, delims: []const u8) SplitDelimIter(u8) {
    return SplitDelimIter(u8).init(input, delims);
}

pub fn splitStringWhitespace(input: []const u8) SplitDelimIter(u8) {
    return SplitDelimIter(u8).init(input, " \n\r\t");
}
