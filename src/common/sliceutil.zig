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
