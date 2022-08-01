const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

fn alphabeticalValue(s: []const u8) u64 {
    var sum: u64 = 0;
    for (s) |c| {
        if (c >= 'A' and c <= 'Z') {
            sum += c - 'A' + 1;
        }
    }
    return sum;
}

/// Returns true if a < b
fn ascStr(context: void, a: []const u8, b: []const u8) bool {
    _ = context;

    for (a) |_, i| {
        if (i >= b.len) return false;
        if (a[i] != b[i]) return a[i] < b[i];
    }

    return a.len < b.len;
}

fn answer(allocator: Allocator) u64 {
    var names = std.ArrayList([]const u8).init(allocator);
    defer names.deinit();
    defer for (names.items) |s| allocator.destroy(s.ptr);

    {
        const filename = "data/p022_names.txt";
        var file = std.fs.cwd().openFile(filename, .{}) catch @panic("Could not open file '" ++ filename ++ "'");
        defer file.close();

        var stream = std.io.bufferedReader(file.reader()).reader();
        while (stream.readUntilDelimiterOrEofAlloc(allocator, ',', 1024) catch @panic("read error")) |s| {
            // std.debug.print("{s} | ", .{s});
            names.append(s) catch @panic("Allocation error");
        }
    }

    std.sort.sort([]const u8, names.items[0..], {}, comptime ascStr);

    var sum: u64 = 0;
    for (names.items) |name, i| {
        // std.debug.print("{s} | ", .{s});
        sum += (@as(u64, i) + 1) * alphabeticalValue(name);
    }

    return sum;
}

test "simple problem" {
    try std.testing.expectEqual(alphabeticalValue("COLIN"), 53);
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 871198282);
}
