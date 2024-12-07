//! Solution for: https://adventofcode.com/2024/day/5

const std = @import("std");
const testing = std.testing;
const DATA = @embedFile("day-5-1.txt");
const EXAMPLE_DATA = @embedFile("day-5-1.example.txt");

fn Rule(comptime T: type) type {
    return struct {
        const Self = @This();

        before: T,
        after: T,
    };
}

const Cmp = []const u8;

const Rules = std.MultiArrayList(Rule(Cmp));
const BanList = std.ArrayList(Cmp);

const State = enum {
    Rules,
    Updates,
};

const RuleParseError = error{
    InvalidSize,
    InvalidDelimiter,
};

fn parseRule(text: Cmp) RuleParseError!Rule(Cmp) {
    if (text.len != 5) return RuleParseError.InvalidSize;
    if (text[2] != '|') return RuleParseError.InvalidDelimiter;

    return .{
        .before = text[0..2],
        .after = text[3..5],
    };
}

test "parseRule" {
    try std.testing.expectEqualDeep(Rule(Cmp){ .before = "01", .after = "02" }, parseRule("01|02"));
    try std.testing.expectEqualDeep(Rule(Cmp){ .before = "02", .after = "01" }, parseRule("02|01"));
    try std.testing.expectEqualDeep(RuleParseError.InvalidSize, parseRule("0110"));
    try std.testing.expectEqualDeep(RuleParseError.InvalidDelimiter, parseRule("01010"));
}

fn process(comptime text: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var rules = Rules{};
    defer rules.deinit(allocator);

    var state: State = .Rules;
    var lines = std.mem.splitScalar(u8, text, '\n');

    var sum: usize = 0;

    lines: while (lines.next()) |line| {
        if (line.len == 0) {
            if (state == .Rules) {
                state = .Updates;
            }
            continue;
        }
        switch (state) {
            .Rules => {
                errdefer |err| std.log.err("Processing rule failed: {}\n", .{err});
                const rule = try parseRule(line);
                try rules.append(allocator, rule);
            },
            .Updates => {
                var numbers = std.ArrayList(Cmp).init(allocator);
                defer numbers.deinit();

                var bans = std.StringHashMap(void).init(allocator);
                defer bans.deinit();

                var updateIter = std.mem.splitScalar(u8, line, ',');
                while (updateIter.next()) |num| {
                    if (bans.get(num)) |_| {
                        continue :lines;
                    }

                    try numbers.append(num);
                    for (rules.items(.before), rules.items(.after)) |before, after| {
                        if (std.mem.eql(u8, num, after)) {
                            try bans.put(before, undefined);
                        }
                    }
                }

                errdefer |err| std.log.err("Failed to parse number: {}\n", .{err});
                const middlePos = @divFloor(numbers.items.len, 2);
                const middleNumber = try std.fmt.parseInt(usize, numbers.items[middlePos], 10);
                sum += middleNumber;
            },
        }
    }

    return sum;
}

pub fn main() !void {
    const result = try process(DATA);
    std.debug.print("Result: {d}\n", .{result});
}

test "example" {
    try std.testing.expectEqual(143, process(EXAMPLE_DATA));
}

test "edge boundaries" {
    // This case is interesting, because when parsing `02`,
    // we need to check all rules in which it is located on both
    // the left AND the right.
    // The initial algorithm I had in mind would have missed this case.
    const data =
        \\01|02
        \\
        \\03,02,01
    ;
    try std.testing.expectEqual(0, process(data));
}
