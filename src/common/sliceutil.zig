const std = @import("std");
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
