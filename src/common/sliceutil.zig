const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub fn indexOf(comptime T: type, haystack: []const T, needle: T) ?usize {
    for (haystack) |x, i| {
        if (x == needle) return i;
    }
    return null;
}

pub fn contains(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |x| {
        if (x == needle) return true;
    }
    return false;
}

pub fn initArrayListLen(comptime T: type, allocator: Allocator, size: usize) Allocator.Error!std.ArrayList(T) {
    var list = try std.ArrayList(T).initCapacity(allocator, size);
    // Can't use `expandToCapacity` since `capacity` may be larger than `size`
    while (list.items.len < size) {
        try list.append(undefined);
    }
    return list;
}

/// Format elements of a slice with special formatting.
/// e.g. `formatSlice(print, "Array: [{d},]\n", arr);` -> `"Array: [1,2,3,]\n"`
pub fn formatSlice(format_func: anytype, comptime fmt: []const u8, arr: anytype) void {
    // Add " " at front and back to ensure there is at least one char before and after "[]"
    comptime var it = std.mem.tokenize(u8, " " ++ fmt ++ " ", "[]");
    const prefix = comptime it.next().?;
    const arr_fmt = comptime it.next().?;
    const suffix = comptime it.next().?;
    assert(it.next() == null);

    format_func(prefix[1..] ++ "[", .{});
    for (arr) |x| format_func(arr_fmt, .{x});
    format_func("]" ++ suffix[0 .. suffix.len - 1], .{});
}

pub fn printSlice(comptime fmt: []const u8, arr: anytype) void {
    formatSlice(std.debug.print, fmt, arr);
}
