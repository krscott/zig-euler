const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn readFileAllocPanicking(allocator: Allocator, filename: []const u8) []u8 {
    var file = std.fs.cwd().openFile(filename, .{}) //
    catch |e| std.debug.panic("Could not open file '{s}': {s}", .{ filename, @errorName(e) });
    defer file.close();

    const text = file.reader().readAllAlloc(allocator, 2 << 20) //
    catch |e| std.debug.panic("Could not open file '{s}': {s}", .{ filename, @errorName(e) });

    return text;
}
