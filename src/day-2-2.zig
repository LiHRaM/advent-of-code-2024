//! Solution for: https://adventofcode.com/2024/day/2

const std = @import("std");
const testing = std.testing;
const DATA = @embedFile("day-2-1.txt");
const EXAMPLE_DATA = @embedFile("day-2-1.example.txt");

pub fn main() !void {
    const result = try process(DATA.len, DATA);
    std.debug.print("{d}\n", .{result});
}

const Trend = enum {
    increasing,
    decreasing,
};

fn isInRange(a: usize, b: usize) bool {
    const difference = @max(a, b) - @min(a, b);
    if (difference > 3) return false;
    if (difference < 1) return false;

    return true;
}

fn getTrend(a: usize, b: usize, trend: ?Trend) ?Trend {
    const t = if (a > b)
        Trend.decreasing
    else if (a < b)
        Trend.increasing
    else
        return null;

    if (trend == null) return t;
    if (t != trend) return null;

    return t;
}

fn areLevelsSafe(levels: []usize) bool {
    var trend: ?Trend = null;

    var i: usize = 0;
    while (i < levels.len - 1) {
        if (!isInRange(levels[i], levels[i + 1])) {
            return false;
        }

        if (getTrend(levels[i], levels[i + 1], trend)) |t| {
            trend = t;
        } else {
            return false;
        }

        i += 1;
    }

    return true;
}

fn areLevelsSafeWithDampener(levels: std.ArrayList(usize)) !bool {
    var i: usize = 0;
    while (i < levels.items.len) {
        var copy = try levels.clone();
        defer copy.deinit();
        _ = copy.orderedRemove(i);

        if (areLevelsSafe(copy.items)) {
            std.debug.print("{any} is safe when removing {d} at {d}: {any}\n", .{
                levels.items,
                levels.items[i],
                i,
                copy.items,
            });
            return true;
        }
        i += 1;
    }
    return false;
}

fn process(comptime n: usize, data: *const [n:0]u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var accumulator: usize = 0;

    var iterLines = std.mem.splitScalar(u8, data, '\n');
    while (iterLines.next()) |line| {
        if (line.len == 0) continue;

        var iterNums = std.mem.splitScalar(u8, line, ' ');
        var reportNumbers = std.ArrayList(usize).init(allocator);
        defer reportNumbers.deinit();

        while (iterNums.next()) |rawNum| {
            const num = try std.fmt.parseInt(usize, rawNum, 10);
            try reportNumbers.append(num);
        }

        if (areLevelsSafe(reportNumbers.items) or try areLevelsSafeWithDampener(reportNumbers)) {
            accumulator += 1;
        }
    }
    return accumulator;
}

test "getTrend 1 2 null is increasing" {
    try std.testing.expectEqual(Trend.increasing, getTrend(1, 2, null));
}

test "getTrend 1 2 decreasing is null" {
    try std.testing.expectEqual(null, getTrend(1, 2, Trend.decreasing));
}

test "getTrend 2 1 null is decreasing" {
    try std.testing.expectEqual(Trend.decreasing, getTrend(2, 1, null));
}

test "getTrend 2 1 increasing is null" {
    try std.testing.expectEqual(null, getTrend(2, 1, Trend.increasing));
}

test "getTrend 2 2 null is null" {
    try std.testing.expectEqual(null, getTrend(2, 2, null));
}

test "always fails" {
    const data =
        \\1 2 1 2 1 2
        \\2 1 2 1 2 1
        \\1 5 9 5 1 5
        \\1 9 1 9 1 9
        \\9 1 9 1 9 1
        \\1 1 1 1 1 1
    ;
    const result = try process(data.len, data);
    try std.testing.expectEqual(0, result);
}

test "safe with dampener" {
    const data =
        \\1 2 3 1 4 5 6
        \\3 2 3 4 5 6 7
        \\1 2 3 4 5 6 5
    ;
    const result = try process(data.len, data);
    try std.testing.expectEqual(3, result);
}

test "always passes" {
    const data =
        \\1 2 3 4 5
        \\5 4 3 2 1
    ;
    const result = try process(data.len, data);
    try std.testing.expectEqual(2, result);
}
