//! Solution for: https://adventofcode.com/2024/day/3

const std = @import("std");
const testing = std.testing;
const DATA = @embedFile("data.txt");

/// Stores the value of a `mul` operation.
const MulOp = struct {
    rhs: usize,
    lhs: usize,
};

const ParseError = error{
    NotFound,
    NumTooLong,
};

/// Parse the literal from the text, returning its length.
fn parseLiteral(comptime literal: []const u8, text: []const u8) !usize {
    if (literal.len > text.len)
        return ParseError.NotFound;

    var i: u8 = 0;
    while (i < literal.len) {
        if (literal[i] != text[i]) {
            return ParseError.NotFound;
        }

        i += 1;
    }

    return i;
}

fn parseNum(text: []const u8) !usize {
    var i: usize = 0;
    while (i < text.len) {
        switch (text[i]) {
            '0'...'9' => i += 1,
            else => {
                if (i == 0) return ParseError.NotFound;
                break;
            },
        }
    }

    if (i > 3) return ParseError.NumTooLong;
    return i;
}

fn parseMul(text: []const u8) !MulOp {
    var pos: usize = 0;
    pos += try parseLiteral("mul", text);
    pos += try parseLiteral("(", text[pos..]);

    const lhsLen = try parseNum(text[pos..]);
    const lhs = try std.fmt.parseInt(usize, text[pos .. pos + lhsLen], 10);
    pos += lhsLen;

    pos += try parseLiteral(",", text[pos..]);

    const rhsLen = try parseNum(text[pos..]);
    const rhs = try std.fmt.parseInt(usize, text[pos .. pos + rhsLen], 10);
    pos += rhsLen;

    pos += try parseLiteral(")", text[pos..]);

    return MulOp{
        .lhs = lhs,
        .rhs = rhs,
    };
}

fn indexOf(comptime char: u8, startAt: usize, text: []const u8) ?usize {
    var loc: usize = startAt;
    while (loc < text.len) {
        if (text[loc] == char) {
            std.debug.print("{any} == {any} at {any}\n", .{ text[loc], char, loc });
            return loc;
        }
        loc += 1;
    }

    return null;
}

fn indexOfAny(comptime chars: []const u8, startAt: usize, text: []const u8) ?usize {
    var loc: usize = startAt;
    while (loc < text.len) {
        for (chars) |char| {
            if (text[loc] == char) {
                std.debug.print("{any} == {any} at {any}\n", .{ text[loc], char, loc });
                return loc;
            }
        }
        loc += 1;
    }

    return null;
}

fn process(comptime data: []const u8) !usize {
    var sum: usize = 0;
    var last: usize = 0;
    var enabled: bool = true;

    while (indexOfAny("md", last, data)) |ix| {
        defer last = ix + 1;

        switch (data[ix]) {
            'm' => {
                if (!enabled) continue;
                if (parseMul(data[ix..])) |op| {
                    std.debug.print("op: {any}\n", .{op});
                    sum += (op.lhs * op.rhs);
                } else |_| {
                    // silence is golden
                }
            },
            'd' => {
                if (parseLiteral("don't()", data[ix..]) catch 0 > 0) {
                    enabled = false;
                } else if (parseLiteral("do()", data[ix..]) catch 0 > 0) {
                    enabled = true;
                }
            },
            else => continue,
        }
    }

    return sum;
}

pub fn main() !void {
    const result = try process(DATA);
    std.debug.print("{d}\n", .{result});
}

test "parseLiteral" {
    try std.testing.expectEqual(3, parseLiteral("mul", "mul"));
    try std.testing.expectEqual(1, parseLiteral("(", "(hello)"));
    try std.testing.expectError(ParseError.NotFound, parseLiteral(",", "."));
}

test "parseNum" {
    try std.testing.expectEqual(3, try parseNum("123,,"));
    try std.testing.expectError(ParseError.NumTooLong, parseNum("1234"));
    try std.testing.expectError(ParseError.NotFound, parseNum("-1"));
    try std.testing.expectError(ParseError.NotFound, parseNum(",,"));
}

test "parseMul" {
    try std.testing.expectEqual(MulOp{ .lhs = 1, .rhs = 2 }, try parseMul("mul(1,2)"));
    try std.testing.expectEqual(MulOp{ .lhs = 10, .rhs = 2 }, try parseMul("mul(10,2)"));
    try std.testing.expectError(ParseError.NotFound, parseMul("mul(1,2]"));
    try std.testing.expectError(ParseError.NumTooLong, parseMul("mul(1,1234)"));
}

test "indexOf" {
    try std.testing.expectEqual(0, indexOf('m', 0, "mul"));
    try std.testing.expectEqual(1, indexOf('m', 0, "uml"));
    try std.testing.expectEqual(2, indexOf('m', 0, "lum"));
}

test "process" {
    try std.testing.expectEqual(2, try process("mul(1,2)"));
    try std.testing.expectEqual(8, try process("mul(1,2)mul(2,1)mul(2,2)"));
    try std.testing.expectEqual(161, try process("xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"));
    try std.testing.expectEqual(48, try process("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"));
}
