const std = @import("std");
const Allocator = std.mem.Allocator;
const max = std.math.max;
const assert = std.debug.assert;

const iterutil = @import("./common/iterutil.zig");
const filter = iterutil.filter;
const count = iterutil.count;
const until = iterutil.until;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{answer()});
}

/// A leap year occurs on any year evenly divisible by 4, but not on a century unless it is divisible by 400.
fn isLeapYear(year: u16) bool {
    return (year % 4 == 0 and year % 100 != 0) or year % 400 == 0;
}

const Month = enum(u4) {
    January = 1,
    February,
    March,
    April,
    May,
    June,
    July,
    August,
    September,
    October,
    November,
    December,

    pub fn next(self: Month) Month {
        return switch (self) {
            Month.December => Month.January,
            else => |x| @intToEnum(Month, @enumToInt(x) + 1),
        };
    }

    pub fn totalDays(self: Month, year: u16) u8 {
        return switch (self) {
            Month.January => 31,
            Month.February => if (isLeapYear(year)) @as(u8, 29) else @as(u8, 28),
            Month.March => 31,
            Month.April => 30,
            Month.May => 31,
            Month.June => 30,
            Month.July => 31,
            Month.August => 31,
            Month.September => 30,
            Month.October => 31,
            Month.November => 30,
            Month.December => 31,
        };
    }

    pub fn number(self: Month) u4 {
        return @enumToInt(self);
    }
};

const Weekday = enum(u3) {
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,

    pub fn next(self: Weekday) Weekday {
        return switch (self) {
            Weekday.Saturday => Weekday.Sunday,
            else => |x| @intToEnum(Weekday, @enumToInt(x) + 1),
        };
    }

    pub fn str(self: Weekday) []const u8 {
        return switch (self) {
            Weekday.Sunday => "Sunday",
            Weekday.Monday => "Monday",
            Weekday.Tuesday => "Tuesday",
            Weekday.Wednesday => "Wednesday",
            Weekday.Thursday => "Thursday",
            Weekday.Friday => "Friday",
            Weekday.Saturday => "Saturday",
        };
    }
};

const Date = struct {
    year: u16,
    month: Month,
    day: u8,
    weekday: Weekday,

    pub fn isValidYMD(self: Date) bool {
        return self.year >= 1 and self.day >= 1 and self.day <= self.month.totalDays(self.year);
    }
};

fn debugPrintDate(date: Date) void {
    std.debug.print("{d:0>4}-{d:0>2}-{d:0>2} {s}\n", .{
        date.year,
        date.month.number(),
        date.day,
        date.weekday.str(),
    });
}

const DateIter = struct {
    const Self = @This();

    date: Date,

    pub fn init(start: Date) Self {
        assert(start.isValidYMD());
        return Self{
            .date = start,
        };
    }

    pub fn next(self: *Self) ?Date {
        var year = self.date.year;
        var month = self.date.month;
        var day = self.date.day + 1;
        var weekday = self.date.weekday.next();

        if (day > month.totalDays(year)) {
            day = 1;
            month = month.next();
            if (month == Month.January) {
                year += 1;
            }
        }

        self.date = Date{
            .year = year,
            .month = month,
            .day = day,
            .weekday = weekday,
        };

        assert(self.date.isValidYMD());

        // debugPrintDate(self.date);

        return self.date;
    }
};

fn is20thCSundayTheFirst(d: Date) bool {
    return d.year >= 1901 and d.year <= 2000 and d.weekday == Weekday.Sunday and d.day == 1;
}

fn isYear2001(d: Date) bool {
    return d.year == 2001;
}

fn countFirstSundaysBefore2001(start: Date) usize {
    var dates = DateIter.init(start);

    return count(filter(is20thCSundayTheFirst, until(isYear2001, dates)));
}

test "since 2000" {
    var first_sundays = countFirstSundaysBefore2001(Date{
        .year = 2000,
        .month = Month.January,
        .day = 1,
        .weekday = Weekday.Saturday,
    });

    try std.testing.expectEqual(first_sundays, 1);
}

test "since 1998" {
    var first_sundays = countFirstSundaysBefore2001(Date{
        .year = 1998,
        .month = Month.January,
        .day = 1,
        .weekday = Weekday.Thursday,
    });

    try std.testing.expectEqual(first_sundays, 5);
}

fn answer() u64 {
    return countFirstSundaysBefore2001(Date{
        .year = 1900,
        .month = Month.January,
        .day = 1,
        .weekday = Weekday.Monday,
    });
}

test "solution" {
    try std.testing.expectEqual(answer(), 171);
}
