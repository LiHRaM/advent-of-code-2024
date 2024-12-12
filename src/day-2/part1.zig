//! Solution for: https://adventofcode.com/2024/day/2

const std = @import("std");
const testing = std.testing;
const DATA = @embedFile("data.txt");
const EXAMPLE_DATA = @embedFile("data.example.txt");

pub fn main() !void {
    const result = try process(DATA.len, DATA);
    std.debug.print("{d}\n", .{result});
}

const Trend = enum { increasing, decreasing };
fn process(comptime n: usize, data: *const [n:0]u8) !usize {
    var accumulator: usize = 0;

    var iterLines = std.mem.splitScalar(u8, data, '\n');
    while (iterLines.next()) |line| {
        var safe = true;
        var prev: ?usize = null;
        var trend: ?Trend = null;

        var iterNums = std.mem.splitScalar(u8, line, ' ');
        while (iterNums.next()) |rawNum| {
            if (rawNum.len == 0) {
                safe = false;
                break;
            }

            const num = try std.fmt.parseInt(usize, rawNum, 10);

            if (prev) |p| {
                // Any two adjacent levels differ by at least one and at most three.
                const difference = @max(p, num) - @min(p, num);
                const in_range = switch (difference) {
                    1...3 => true,
                    else => false,
                };
                if (!in_range) {
                    safe = false;
                    break;
                }

                // The levels are either all increasing or all decreasing.
                const currentTrend = if (p > num) Trend.decreasing else Trend.increasing;
                if (trend) |t| {
                    if (t != currentTrend) {
                        safe = false;
                        break;
                    }
                } else {
                    trend = currentTrend;
                }
            }

            prev = num;
        }

        if (safe) {
            accumulator += 1;
        }
    }
    return accumulator;
}

test "example result passes" {
    const result = try process(EXAMPLE_DATA.len, EXAMPLE_DATA);
    try std.testing.expectEqual(2, result);
}
