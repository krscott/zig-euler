const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;

const primelib = @import("./common/primes.zig");
const Primes = primelib.Primes;
const PrimeLookup = primelib.PrimeLookup;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer(allocator)});
}

// fn getNumDigits(n: usize) usize {
//     return std.math.log10(n) + 1;
// }

var digits_cache: [50]u64 = undefined;
fn digitsSlice(n: u64) []u64 {
    var i: usize = 0;
    var x = n;
    while (x != 0) {
        digits_cache[i] = x % 10;
        x = @divTrunc(x, 10);
        i += 1;
    }
    return digits_cache[0..i];
}

fn getMaskedNumber(digits: []const u64, bitmask: usize, replacement_digit: u64) u64 {
    var out: u64 = 0;
    var x10: u64 = 1;
    var i: usize = 0;
    while (i < digits.len) : (i += 1) {
        const b = @as(usize, 1) << @intCast(u6, i);
        out += x10 * if (bitmask & b == 0) digits[i] else replacement_digit;
        x10 *= 10;
    }
    return out;
}

const FamilyInfo = struct {
    degree: usize,
    min_prime: u64,
};

fn getFamilyInfo(lookup: *PrimeLookup(u64), n: u64) !FamilyInfo {
    if (!try lookup.isPrime(n)) return FamilyInfo{ .degree = 0, .min_prime = 0 };
    if (n < 10) return FamilyInfo{ .degree = 4, .min_prime = 2 };

    const digits_slice = digitsSlice(n);

    var max_deg: usize = 0;
    var max_deg_min_prime: u64 = 0;

    const limit: usize = @as(usize, 1) << @intCast(u6, digits_slice.len);
    const highest_bit_mask = limit >> 1;

    var bitmask: usize = 1;
    while (bitmask < limit) : (bitmask += 1) {
        var primes_count: usize = 0;
        var min_prime: u64 = std.math.maxInt(u64);

        var replacement_digit: usize = 0;
        while (replacement_digit < 10) : (replacement_digit += 1) {
            // Do not replace highest digit with 0
            if (replacement_digit == 0 and bitmask & highest_bit_mask != 0) continue;

            const mn = getMaskedNumber(digits_slice, bitmask, replacement_digit);
            // print("n: {} mask: {} rep: {}, mn: {}\n", .{ n, bitmask, replacement_digit, mn });
            if (try lookup.isPrime(mn)) {
                // print("hit!\n", .{});
                primes_count += 1;

                if (mn < min_prime) {
                    min_prime = mn;
                }
            }
        }

        if (primes_count > max_deg) {
            max_deg = primes_count;
            max_deg_min_prime = min_prime;
        }
    }

    return FamilyInfo{
        .degree = max_deg,
        .min_prime = max_deg_min_prime,
    };
}

fn getSmallestWithDegree(lookup: *PrimeLookup(u64), degree: usize, start: u64) !u64 {
    var n: u64 = start;
    while (true) : (n += 1) {
        const info = try getFamilyInfo(lookup, n);
        if (info.degree >= degree) {
            return info.min_prime;
        }
    }
}

fn answer(allocator: Allocator) u64 {
    var primes = Primes(u64).init(allocator);
    defer primes.deinit();

    var lookup = primes.lookup(allocator);
    defer lookup.deinit();

    return getSmallestWithDegree(&lookup, 8, 56003 + 1) catch @panic("alloc");
}

test "simple problem" {
    var primes = Primes(u64).init(std.testing.allocator);
    defer primes.deinit();

    var lookup = primes.lookup(std.testing.allocator);
    defer lookup.deinit();

    try std.testing.expectEqual(getFamilyInfo(&lookup, 43), .{ .degree = 6, .min_prime = 13 });
    try std.testing.expectEqual(getFamilyInfo(&lookup, 56773), .{ .degree = 7, .min_prime = 56003 });

    try std.testing.expectEqual(getSmallestWithDegree(&lookup, 6, 10), 13);
    try std.testing.expectEqual(getSmallestWithDegree(&lookup, 7, 50000), 56003);
}

test "solution" {
    try std.testing.expectEqual(answer(std.testing.allocator), 121313);
}
