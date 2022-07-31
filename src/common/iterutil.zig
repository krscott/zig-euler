const std = @import("std");
const sliceutil = @import("./sliceutil.zig");
const contains = sliceutil.contains;

fn FnReturnType(comptime f: anytype) type {
    return @typeInfo(@TypeOf(f)).Fn.return_type.?;
}

pub fn IteratorMixin(comptime Self: type) type {
    if (!@hasDecl(Self, "next")) {
        @compileError("Expected method `next(*" ++ @typeName(Self) ++ ") ?Item` in " ++ @typeName(Self));
    }

    const Item = @typeInfo(@typeInfo(@TypeOf(Self.next)).Fn.return_type.?).Optional.child;

    return struct {
        pub fn withContext(self: *Self, context: anytype) ContextIter(Self, @TypeOf(context)) {
            return ContextIter(Self, @TypeOf(context)){ .context = context, .base = self };
        }

        pub usingnamespace if (@typeInfo(Item) == .Struct and @hasField(Item, "context")) struct {
            const ContextDataType = @typeInfo(Item).Struct.fields[1].field_type;

            fn getContextData(context: anytype) ContextDataType {
                return context.data;
            }

            pub fn dropContext(self: *Self) MapIter(Self, getContextData, ContextDataType) {
                return MapIter(Self, getContextData, ContextDataType){ .base = self };
            }
        } else struct {};

        pub fn map(self: *Self, comptime f: anytype) MapIter(Self, f, FnReturnType(f)) {
            return MapIter(Self, f, FnReturnType(f)){ .base = self };
        }

        pub fn filter(self: *Self, comptime f: anytype) FilterIter(Self, f) {
            return FilterIter(Self, f){ .base = self };
        }

        pub fn until(self: *Self, comptime f: anytype) UntilIter(Self, f) {
            return UntilIter(Self, f){ .base = self };
        }

        pub fn count(self: *Self) usize {
            var x: usize = 0;
            while (self.next()) |_| {
                x += 1;
            }
            return x;
        }
    };
}

pub fn Context(comptime ContextType: type, comptime DataType: type) type {
    return struct {
        context: ContextType,
        data: DataType,
    };
}

pub fn ContextIter(comptime BaseIter: type, comptime ContextType: type) type {
    const DataType: type = @typeInfo(@typeInfo(@TypeOf(BaseIter.next)).Fn.return_type.?).Optional.child;

    return struct {
        const Self = @This();

        context: ContextType,
        base: *BaseIter,

        pub fn next(self: *Self) ?Context(ContextType, DataType) {
            return Context(ContextType, DataType){ .context = self.context, .data = self.base.next() orelse return null };
        }

        pub usingnamespace IteratorMixin(Self);
    };
}

pub fn MapIter(comptime BaseIter: type, comptime f: anytype, comptime Item: type) type {
    // const Item: type = @typeInfo(@TypeOf(f)).Fn.return_type.?;

    return struct {
        const Self = @This();

        base: *BaseIter,

        pub fn next(self: *Self) ?Item {
            return f(self.base.next() orelse return null);
        }

        pub usingnamespace IteratorMixin(Self);
    };
}

pub fn FilterIter(comptime BaseIter: type, comptime f: anytype) type {
    const Item: type = @typeInfo(@typeInfo(@TypeOf(BaseIter.next)).Fn.return_type.?).Optional.child;

    return struct {
        const Self = @This();

        base: *BaseIter,

        pub fn next(self: *Self) ?Item {
            while (self.base.next()) |x| {
                if (f(x) == true) {
                    return x;
                }
            }
            return null;
        }

        pub usingnamespace IteratorMixin(Self);
    };
}

pub fn UntilIter(comptime BaseIter: type, comptime f: anytype) type {
    const Item: type = @typeInfo(@typeInfo(@TypeOf(BaseIter.next)).Fn.return_type.?).Optional.child;

    return struct {
        const Self = @This();

        base: *BaseIter,

        pub fn next(self: *Self) ?Item {
            const x = self.base.next() orelse return null;
            return if (f(x)) null else x;
        }

        pub usingnamespace IteratorMixin(Self);
    };
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

        pub usingnamespace IteratorMixin(Self);
    };
}

pub fn splitStringDelims(input: []const u8, delims: []const u8) SplitDelimIter(u8) {
    return SplitDelimIter(u8).init(input, delims);
}

pub fn splitStringWhitespace(input: []const u8) SplitDelimIter(u8) {
    return SplitDelimIter(u8).init(input, " \n\r\t");
}
