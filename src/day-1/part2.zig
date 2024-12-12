//! Solution for: https://adventofcode.com/2024/day/1

const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const data = @embedFile("data.txt");

pub fn main() !void {
    const numSize = u64;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var leftList = ArrayList(numSize).init(allocator);
    defer leftList.deinit();

    var rightList = ArrayList(numSize).init(allocator);
    defer rightList.deinit();

    var splits = std.mem.splitAny(u8, data, "\n");
    while (splits.next()) |line| {
        var numbersRaw = std.mem.splitAny(u8, line, " ");
        var isLeft = true;
        while (numbersRaw.next()) |numberRaw| {
            if (numberRaw.len == 0) continue;
            const num = try std.fmt.parseInt(numSize, numberRaw, 10);
            var list = if (isLeft) &leftList else &rightList;
            try list.append(num);
            isLeft = !isLeft;
        }
    }

    std.mem.sort(numSize, leftList.items, {}, comptime std.sort.asc(numSize));
    std.mem.sort(numSize, rightList.items, {}, comptime std.sort.asc(numSize));

    if (leftList.items.len != rightList.items.len) {
        std.log.err("list lengths do not match\n", .{});
        return;
    }

    var rightListOccurrences = std.AutoHashMap(numSize, numSize).init(allocator);
    defer rightListOccurrences.deinit();

    for (rightList.items) |item| {
        const prev = try rightListOccurrences.fetchPut(item, @as(numSize, 1));
        if (prev) |*pair| {
            try rightListOccurrences.put(item, pair.value + @as(numSize, 1));
        }
    }

    var accumulator: usize = 0;
    for (leftList.items) |item| {
        if (rightListOccurrences.get(item)) |occurrences| {
            accumulator += item * occurrences;
        }
    }

    std.debug.print("{d}\n", .{accumulator});
}
