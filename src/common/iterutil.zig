const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const sliceutil = @import("./sliceutil.zig");
const contains = sliceutil.contains;
const initArrayListLen = sliceutil.initArrayListLen;

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
            return ContextIter(Self, @TypeOf(context)).init(self, context);
        }

        pub usingnamespace if (@typeInfo(Item) == .Struct and @hasField(Item, "context")) struct {
            // TODO: Better way to do this in later Zig version?
            const ContextDataType = @typeInfo(Item).Struct.fields[1].field_type;

            fn getContextData(context: anytype) ContextDataType {
                return context.data;
            }

            pub fn dropContext(self: *Self) MapIter(Self, getContextData, ContextDataType) {
                comptime {
                    std.testing.expectEqualStrings("data", @typeInfo(Item).Struct.fields[1].name[0..]) //
                    catch @compileError("!! Unexpected Context layout");
                }

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
        index: usize,
    };
}

pub fn ContextIter(comptime BaseIter: type, comptime ContextType: type) type {
    const DataType: type = @typeInfo(@typeInfo(@TypeOf(BaseIter.next)).Fn.return_type.?).Optional.child;

    return struct {
        const Self = @This();

        context: ContextType,
        base: *BaseIter,
        index: usize,

        fn init(base: *BaseIter, context: ContextType) Self {
            return Self{
                .index = 0,
                .context = context,
                .base = base,
            };
        }

        pub fn next(self: *Self) ?Context(ContextType, DataType) {
            defer self.index += 1;
            return Context(ContextType, DataType){
                .context = self.context,
                .data = self.base.next() orelse return null,
                .index = self.index,
            };
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

pub fn ComboIter(comptime T: type) type {
    return struct {
        pub usingnamespace IteratorMixin(Self);
        const Self = @This();

        allocator: Allocator,
        input: []const T,
        next_index: usize,
        size: usize,
        child: ?*Self,
        output: std.ArrayList(T),

        fn init(allocator: Allocator, input: []const T, size: usize) Allocator.Error!Self {
            assert(size > 0 and size <= input.len);

            var output = try std.ArrayList(T).initCapacity(allocator, size);
            output.expandToCapacity();

            var child: ?*Self = if (size <= 1)
                null
            else blk: {
                var child = try allocator.create(ComboIter(T));
                child.* = try Self.init(allocator, input[1..], size - 1);
                break :blk child;
            };

            return Self{
                .allocator = allocator,
                .input = input,
                .next_index = 0,
                .size = size,
                .child = child,
                .output = output,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.child) |child| {
                child.deinit();
                self.allocator.destroy(child);
            }
            self.output.deinit();
            self.* = undefined;
        }

        fn reset(self: *Self, input: []const T, size: usize) void {
            assert(size > 0 and size <= input.len);

            self.next_index = 0;
            self.input = input;
            self.size = size;

            if (size > 1) {
                if (self.child) |child| {
                    child.reset(input[1..], size - 1);
                } else {
                    @panic("Cannot increase size above original allocation");
                }
            }
        }

        pub fn next(self: *Self) ?[]const T {
            if (self.next_index + self.size > self.input.len or self.size == 0) return null;

            self.output.items[0] = self.input[self.next_index];

            if (self.size > 1) {
                if (self.child) |child| {
                    if (child.next()) |child_list| {
                        for (child_list) |x, i| {
                            self.output.items[i + 1] = x;
                        }

                        return self.output.items[0..self.size];
                    }

                    self.next_index += 1;
                    if (self.next_index + self.size > self.input.len) return null;

                    child.reset(self.input[self.next_index + 1 ..], self.size - 1);

                    return self.next();
                }
            }

            self.next_index += 1;
            return self.output.items[0..self.size];
        }
    };
}

pub fn combinations(comptime T: type, allocator: Allocator, input: []const T, size: usize) Allocator.Error!ComboIter(T) {
    return ComboIter(T).init(allocator, input, size);
}

test "combinations singles" {
    const input: [4]usize = .{ 1, 2, 3, 4 };
    var it = try combinations(usize, std.testing.allocator, input[0..], 1);
    defer it.deinit();

    try std.testing.expectEqualSlices(usize, &.{1}, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{2}, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{3}, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{4}, it.next().?);
    try std.testing.expect(it.next() == null);
}

test "combinations single pair" {
    const input: [2]usize = .{ 1, 2 };
    var it = try combinations(usize, std.testing.allocator, input[0..], 2);
    defer it.deinit();

    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, it.next().?);
    try std.testing.expect(it.next() == null);
}

test "combinations pairs" {
    const input: [3]usize = .{ 1, 2, 3 };
    var it = try combinations(usize, std.testing.allocator, input[0..], 2);
    defer it.deinit();

    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 1, 3 }, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 2, 3 }, it.next().?);
    try std.testing.expect(it.next() == null);
}

test "combinations triplets" {
    const input: [4]usize = .{ 1, 2, 3, 4 };
    var it = try combinations(usize, std.testing.allocator, input[0..], 3);
    defer it.deinit();

    try std.testing.expectEqualSlices(usize, &.{ 1, 2, 3 }, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 1, 2, 4 }, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 1, 3, 4 }, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 2, 3, 4 }, it.next().?);
    try std.testing.expect(it.next() == null);
}

pub fn AllCombosIter(comptime T: type) type {
    return struct {
        pub usingnamespace IteratorMixin(Self);
        const Self = @This();

        allocator: Allocator,
        input: []const T,
        child: ComboIter(T),

        fn init(allocator: Allocator, input: []const T) Allocator.Error!Self {
            // Init with largest size so that no more allocations are needed later
            var child = try ComboIter(T).init(allocator, input, input.len);
            child.reset(input, 1);

            return Self{
                .allocator = allocator,
                .input = input,
                .child = child,
            };
        }

        pub fn deinit(self: *Self) void {
            self.child.deinit();
            self.* = undefined;
        }

        pub fn next(self: *Self) ?[]const T {
            if (self.child.next()) |combo| {
                return combo;
            }

            const next_size = self.child.size + 1;

            if (next_size > self.input.len) return null;

            self.child.reset(self.input, next_size);

            return self.next();
        }
    };
}

pub fn allCombinations(comptime T: type, allocator: Allocator, input: []const T) Allocator.Error!AllCombosIter(T) {
    return AllCombosIter(T).init(allocator, input);
}

test "allCombinations()" {
    const input: [3]usize = .{ 1, 2, 3 };
    var it = try allCombinations(usize, std.testing.allocator, input[0..]);
    defer it.deinit();

    try std.testing.expectEqualSlices(usize, &.{1}, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{2}, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{3}, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 1, 2 }, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 1, 3 }, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 2, 3 }, it.next().?);
    try std.testing.expectEqualSlices(usize, &.{ 1, 2, 3 }, it.next().?);
    try std.testing.expect(it.next() == null);
}

pub fn PermIter(comptime T: type) type {
    return struct {
        pub usingnamespace IteratorMixin(Self);
        const Self = @This();

        allocator: Allocator,
        input: []const T,
        next_state: std.ArrayList(usize),
        output: std.ArrayList(T),
        is_done: bool,

        fn init(allocator: Allocator, input: []const T, pick: usize) Allocator.Error!Self {
            var next_state = try initArrayListLen(usize, allocator, pick);

            // Fill array with each element's index: .{0, 1, 2, 3, ...}
            {
                var i: usize = 0;
                while (i < next_state.items.len) : (i += 1) {
                    next_state.items[i] = i;
                }
            }

            return Self{
                .allocator = allocator,
                .input = input,
                .next_state = next_state,
                .output = try initArrayListLen(T, allocator, pick),
                .is_done = input.len == 0 or pick == 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.next_state.deinit();
            self.output.deinit();
            self.* = undefined;
        }

        /// Check if `state` is in final state.
        /// e.g. In 4-pick-3, state == .{3, 2, 1}
        fn isDone(state: []const usize, last_value: usize) bool {
            for (state) |x, i| {
                if (x != last_value - i) return false;
            }
            return true;
        }

        /// Check if all values are unique
        fn isValidState(state: []usize) bool {
            for (state) |x, i| {
                for (state[0..i]) |y| {
                    if (x == y) return false;
                }
            }
            return true;
        }

        fn incrementState(state: []usize, last_value: usize) void {
            var i = state.len - 1;
            while (true) : (i -= 1) {
                if (state[i] == last_value) {
                    state[i] = 0;
                } else {
                    state[i] += 1;
                    return;
                }

                if (i == 0) return;
            }
        }

        pub fn next(self: *Self) ?[]const T {
            if (self.is_done) return null;

            // for (self.next_state.items) |i| {
            //     std.debug.print("{d}", .{i});
            // }
            // std.debug.print("\n", .{});

            for (self.next_state.items) |x, i| {
                self.output.items[i] = self.input[x];
            }

            if (isDone(self.next_state.items, self.input.len - 1)) {
                self.is_done = true;
            } else {
                while (true) {
                    incrementState(self.next_state.items, self.input.len - 1);
                    if (isValidState(self.next_state.items)) break;
                }
            }

            return self.output.items;
        }
    };
}

pub fn permutations(comptime T: type, allocator: Allocator, input: []const T, pick: usize) Allocator.Error!PermIter(T) {
    return PermIter(T).init(allocator, input, pick);
}

test "permutations 3 pick 3" {
    var it = try permutations(u8, std.testing.allocator, "abc", 3);
    defer it.deinit();

    try std.testing.expectEqualStrings("abc", it.next().?);
    try std.testing.expectEqualStrings("acb", it.next().?);
    try std.testing.expectEqualStrings("bac", it.next().?);
    try std.testing.expectEqualStrings("bca", it.next().?);
    try std.testing.expectEqualStrings("cab", it.next().?);
    try std.testing.expectEqualStrings("cba", it.next().?);
    try std.testing.expect(it.next() == null);
}

test "permutations 3 pick 2" {
    var it = try permutations(u8, std.testing.allocator, "abc", 2);
    defer it.deinit();

    try std.testing.expectEqualStrings("ab", it.next().?);
    try std.testing.expectEqualStrings("ac", it.next().?);
    try std.testing.expectEqualStrings("ba", it.next().?);
    try std.testing.expectEqualStrings("bc", it.next().?);
    try std.testing.expectEqualStrings("ca", it.next().?);
    try std.testing.expectEqualStrings("cb", it.next().?);
    try std.testing.expect(it.next() == null);
}

test "permutations 3 pick 1" {
    var it = try permutations(u8, std.testing.allocator, "abc", 1);
    defer it.deinit();

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("b", it.next().?);
    try std.testing.expectEqualStrings("c", it.next().?);
    try std.testing.expect(it.next() == null);
}
