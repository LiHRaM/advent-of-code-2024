//! Solution for: https://adventofcode.com/2024/day/4

const std = @import("std");
const testing = std.testing;
const DATA = @embedFile("data.txt");

fn IndexOfScalarIter(comptime T: type) type {
    return struct {
        const Self = @This();

        index: usize = 0,
        haystack: []const T,
        needle: T,

        /// Continue the iterator.
        /// Returns `usize` on success, otherwise `null`.
        fn next(self: *Self) ?usize {
            if (std.mem.indexOfScalar(T, self.haystack[self.index..], self.needle)) |index| {
                defer self.index += index + 1;
                return self.index + index;
            }

            return null;
        }

        /// Create an iterator that will find the index
        /// of each instance of `needle`.
        fn create(needle: T, haystack: []const T) Self {
            return .{
                .needle = needle,
                .haystack = haystack,
            };
        }
    };
}

fn Point() type {
    return struct {
        const Self = @This();

        row: usize,
        col: usize,

        fn move(self: Self, rows: i64, cols: i64) ?Self {
            const row: i64 = @as(i64, @intCast(self.row)) + rows;
            if (row < 0) return null;
            const col: i64 = @as(i64, @intCast(self.col)) + cols;
            if (col < 0) return null;

            return .{
                .row = @as(usize, @intCast(row)),
                .col = @as(usize, @intCast(col)),
            };
        }
    };
}

test "pt" {
    const pt = Point(){
        .row = 0,
        .col = 0,
    };

    try std.testing.expectEqual(Point(){ .row = 1, .col = 1 }, pt.move(1, 1));
    try std.testing.expectEqual(null, pt.move(-1, -1));
}

/// The Sparse Matrix only stores relevant values.
/// We will use it to store the letters 'X', 'M', 'A' and 'S'.
fn SparseMatrix(comptime T: type) type {
    return struct {
        const Self = @This();

        values: std.ArrayList(T),
        colIndexes: std.ArrayList(usize),
        rowIndexes: std.ArrayList(usize),

        fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .values = std.ArrayList(T).init(allocator),
                .colIndexes = std.ArrayList(usize).init(allocator),
                .rowIndexes = std.ArrayList(usize).init(allocator),
            };
        }

        fn deinit(self: Self) void {
            self.values.deinit();
            self.colIndexes.deinit();
            self.rowIndexes.deinit();
        }

        fn insert(self: *Self, value: T, rowIndex: usize, colIndex: usize) !void {
            try self.values.append(value);
            try self.colIndexes.append(colIndex);
            try self.rowIndexes.append(rowIndex);
        }

        fn iterByScalar(self: Self, needle: []const T) IndexOfScalarIter(T) {
            return IndexOfScalarIter(T).create(needle, self.values.items);
        }

        fn getPoint(self: Self, index: usize) Point() {
            return Point(){
                .row = self.rowIndexes.items[index],
                .col = self.colIndexes.items[index],
            };
        }

        /// Returns the position of a value at the given coordinates.
        /// Returns `null` if no such value can be found.
        fn findPoint(self: Self, point: Point()) ?usize {
            const start: usize = std.mem.indexOfScalar(usize, self.rowIndexes.items, point.row) orelse return null;
            const end: usize = std.mem.lastIndexOfScalar(usize, self.rowIndexes.items, point.row) orelse return null;

            const sliceIx: usize = std.mem.indexOfScalar(usize, self.colIndexes.items[start .. end + 1], point.col) orelse return null;
            return start + sliceIx;
        }

        fn print(self: Self) void {
            std.debug.print("V: {any}\nCOLS: {any}\nROWS: {any}\n", .{ self.values.items, self.colIndexes.items, self.rowIndexes.items });
        }
    };
}

test "slice assumptions" {
    const data = "0123456789";
    try std.testing.expectEqual(0, data[0..0].len);
    try std.testing.expectEqual(1, data[0..1].len);
    try std.testing.expectEqual('9', data[9..10][0]);
}

test "matrix operations" {
    var m = SparseMatrix(u8).init(std.testing.allocator);
    defer m.deinit();

    try omnom(&m, "SMA\nSMM\nASS");
    m.print();
    try std.testing.expectEqual(0, m.findPoint(Point(){ .row = 0, .col = 0 }));
    try std.testing.expectEqual(8, m.findPoint(Point(){ .row = 2, .col = 2 }));
}

fn omnom(matrix: *SparseMatrix(u8), text: []const u8) !void {
    var rowIndex: usize = 0;
    var rowIter = std.mem.splitScalar(u8, text, '\n');
    while (rowIter.next()) |row| {
        defer rowIndex += 1;

        for (row, 0..) |char, colIndex| {
            switch (char) {
                'M', 'A', 'S' => try matrix.insert(char, rowIndex, colIndex),
                else => continue,
            }
        }
    }
}

fn process(comptime text: []const u8, allocator: std.mem.Allocator) !usize {
    // Step 1: Collect letters ['M','A','S'] into an appropriate data structure
    // Step 2: For each 'A', check the corners.
    // Step 2.1: Check the top left corner. If it is 'M', assume the bottom right corner is an 'A'.
    // Step 2.2. Repeat for top right corner.

    var sum: usize = 0;

    var m = SparseMatrix(u8).init(allocator);
    defer m.deinit();

    try omnom(&m, text);

    var iterA = IndexOfScalarIter(u8).create('A', m.values.items);

    while (iterA.next()) |posA| {
        const ptA = m.getPoint(posA);

        // TODO: Refactor this into a single function with different parameters
        // never gonna happen ofc
        const ptTopLeft = ptA.move(-1, -1) orelse continue;
        const posTopLeft = m.findPoint(ptTopLeft) orelse continue;
        const valTopLeft = m.values.items[posTopLeft];
        const ptBotRight = ptA.move(1, 1) orelse continue;
        const posBotRight = m.findPoint(ptBotRight) orelse continue;
        const valBotRight = m.values.items[posBotRight];
        const expectedBotRight: u8 = switch (valTopLeft) {
            'M' => 'S',
            'S' => 'M',
            else => continue,
        };
        if (valBotRight != expectedBotRight) continue;

        const ptTopRight = ptA.move(-1, 1) orelse continue;
        const posTopRight = m.findPoint(ptTopRight) orelse continue;
        const valTopRight = m.values.items[posTopRight];
        const ptBotLeft = ptA.move(1, -1) orelse continue;
        const posBotLeft = m.findPoint(ptBotLeft) orelse continue;
        const valBotLeft = m.values.items[posBotLeft];
        const expectedBotLeft: u8 = switch (valTopRight) {
            'M' => 'S',
            'S' => 'M',
            else => continue,
        };
        if (valBotLeft != expectedBotLeft) continue;

        sum += 1;
    }

    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const result = try process(DATA, allocator);
    std.debug.print("{d}\n", .{result});
}

test "example 1" {
    const data =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    try std.testing.expectEqual(9, process(data, std.testing.allocator));
}
