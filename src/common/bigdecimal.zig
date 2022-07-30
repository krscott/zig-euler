const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const BigDecimalError = error{
    NonDigitCharacter,
};

/// String-based decimal type.
/// Leading zeroes are excluded. Zero value (0) is represented as empty string ("").
pub const BigDecimal = struct {
    const Self = @This();

    digits: std.ArrayList(u8),
    slice: []u8,

    pub fn init(allocator: Allocator) Self {
        const digits = std.ArrayList(u8).init(allocator);

        const self = Self{
            .digits = digits,
            .slice = digits.items[0..],
        };

        // Check our assumptions about how `ArrayList` works.
        assert(self.slice.len == 0);

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.digits.deinit();
    }

    /// Expand inner ArrayList and move data to end of inner array.
    fn ensureCapacity(self: *Self, new_capacity: usize) Allocator.Error!void {

        // Example (value "1234", '.' = undefined)
        //
        // 0. Initial state:
        // [....1234] <- self.digits.items
        //     [^^^^] <- self.slice
        //
        // 1. Expand Capacity:
        // [....1234........] <- self.digits.items
        //     [^^^^] <- self.slice
        //
        // 2. Move data and slice
        // [....1234....1234] <- self.digits.items
        //             [^^^^] <- self.slice

        if (new_capacity <= self.digits.items.len) return;

        // Length of the original items array
        const old_cap: usize = self.digits.items.len;

        // Length of the original valid slice
        const old_len: usize = self.slice.len;

        // Expand ArrayList capacity and length
        try self.digits.ensureTotalCapacity(new_capacity);
        self.digits.expandToCapacity();

        // Get old and new slices (self.digits.items may have moved)
        const old_slice = self.digits.items[old_cap - old_len .. old_cap];
        self.slice = self.digits.items[self.digits.items.len - old_len ..];

        assert(old_slice.len == self.slice.len);

        // Data is moving forward and may overlap, so copy end-first
        std.mem.copyBackwards(u8, self.slice, old_slice);
    }

    /// Push a digit character to the front of the `BigDecimal`.
    fn pushCharFront(self: *Self, ch: u8) Allocator.Error!void {
        assert(ch >= '0' and ch <= '9');

        const new_len = self.slice.len + 1;

        try self.ensureCapacity(new_len);

        self.slice = self.digits.items[self.digits.items.len - new_len ..];

        self.slice[0] = ch;
    }

    pub fn initFromString(allocator: Allocator, s: []const u8) Allocator.Error!Self {
        var self = Self.init(allocator);
        errdefer self.deinit();

        try self.ensureCapacity(s.len);

        var i: usize = 0;
        while (i < s.len) : (i += 1) {
            try self.pushCharFront(s[s.len - i - 1]);
        }

        return self;
    }

    pub fn add(self: *Self, other: []const u8) !void {
        try self.ensureCapacity(other.len);

        var carry: bool = false;
        var i: usize = 0;
        while (i < other.len or i < self.slice.len or carry) : (i += 1) {
            // Get other char ('0'...'9')
            const other_char = if (i < other.len) other[other.len - 1 - i] else '0';

            if (other_char < '0' or other_char > '9') {
                assert(false);
                return;
            }

            // Get our char ('0'...'9')
            const self_char = if (i < self.slice.len) self.slice[self.slice.len - 1 - i] else '0';

            // Add digits together
            const new_digit: u8 = (other_char - '0') + (self_char - '0') + if (carry) @as(u8, 1) else @as(u8, 0);

            carry = new_digit >= 10;

            const new_ch: u8 = (new_digit % 10) + '0';

            // Overwrite digit char
            if (i < self.slice.len) {
                self.slice[self.slice.len - 1 - i] = new_ch;
            } else {
                try self.pushCharFront(new_ch);
            }

            // std.debug.print("{c} + {c} -> {c} : {s}\n", .{ self_char, other_char, new_ch, self.slice });
        }
    }
};

test "BigDecimal" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var a = try BigDecimal.initFromString(allocator, "123");
    // defer a.deinit();

    try a.add("9000");

    std.debug.print("{s}\n", .{a.slice});
    try std.testing.expectEqualSlices(u8, "9123", a.slice);

    try a.add("900");

    try std.testing.expectEqualSlices(u8, "10023", a.slice);
}
