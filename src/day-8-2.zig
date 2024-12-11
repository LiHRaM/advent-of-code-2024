//! Solution for: https://adventofcode.com/2024/day/8

const std = @import("std");
const shared = @import("./shared/shared.zig");
const testing = std.testing;
const DATA = @embedFile("day-8-1.txt");
const EXAMPLE_DATA = @embedFile("day-8-1.example.txt");
const SparseMatrix = shared.sparse_matrix.SparseMatrix;
const SparseMatrixElement = shared.sparse_matrix.SparseMatrixElement;
const Antinodes = std.AutoHashMap(SparseMatrixElement, void);

const BoundedSparseMatrix = struct {
    const Self = @This();

    inner: SparseMatrix,
    row_len: usize,
    col_len: usize,

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.*.inner.deinit(allocator);
    }

    pub fn contains(self: Self, point: SparseMatrixElement) bool {
        return self.col_len > point.col and self.row_len > point.row;
    }
};

fn createMatrixFromText(allocator: std.mem.Allocator, text: []const u8) !BoundedSparseMatrix {
    var matrix = shared.sparse_matrix.SparseMatrix{};
    var row: usize = 0;
    var col_len: usize = 0;
    var lines = std.mem.split(u8, text, "\n");
    while (lines.next()) |line| {
        defer row += 1;

        if (row == 0) {
            col_len = line.len;
        }

        for (line, 0..) |char, col| {
            if (char != '.') {
                try matrix.append(allocator, .{
                    .v = char,
                    .row = row,
                    .col = col,
                });
            }
        }
    }

    return .{
        .inner = matrix,
        .row_len = row - 1,
        .col_len = col_len,
    };
}

test "no duplicates" {
    var nodes = Antinodes.init(std.testing.allocator);
    defer nodes.deinit();

    try nodes.put(SparseMatrixElement{ .v = 'A', .row = 0, .col = 0 }, undefined);
    try nodes.put(SparseMatrixElement{ .v = 'A', .row = 0, .col = 0 }, undefined);
    try nodes.put(SparseMatrixElement{ .v = 'B', .row = 1, .col = 1 }, undefined);
    try nodes.put(SparseMatrixElement{ .v = 'B', .row = 1, .col = 1 }, undefined);

    try std.testing.expectEqual(2, nodes.count());
}

/// Returns the nodes as a HashSet
/// Should be deallocated by the caller.
///
/// The time complexity is `O(n²)`
fn findAntinodes(allocator: std.mem.Allocator, matrix: BoundedSparseMatrix) !Antinodes {
    var nodes = Antinodes.init(allocator);

    for (matrix.inner.items(.v), 0..) |left, i| {
        for (matrix.inner.items(.v), 0..) |right, j| {
            // Do not process the node in relation to itself.
            if (i == j) continue;

            // Skip nodes which do not have the same frequency.
            if (left != right) continue;

            // given nodes A and B, calculate the distance D from A to B,
            const A = matrix.inner.get(i);
            const B = matrix.inner.get(j);
            const D = A.dist(B);

            // place antinodes for each source antenna as well
            try nodes.put(A.place(.{ .cols = 0, .rows = 0 }, '#').?, undefined);
            try nodes.put(B.place(.{ .cols = 0, .rows = 0 }, '#').?, undefined);

            // iteratively place new 'A = (A - D) while contained by matrix
            var aNext = A.place(D.reverse(), '#');
            while (aNext) |a| {
                if (!matrix.contains(a)) break;
                try nodes.put(a, undefined);
                aNext = a.place(D.reverse(), '#');
            }

            // and another node 'B = (B + D)
            var bNext = B.place(D, '#');
            while (bNext) |b| {
                if (!matrix.contains(b)) break;
                try nodes.put(b, undefined);
                bNext = b.place(D, '#');
            }
        }
    }

    return nodes;
}

test "antinodes" {
    const map =
        \\....
        \\00..
        \\....
    ;

    var matrix = try createMatrixFromText(std.testing.allocator, map);
    defer matrix.deinit(std.testing.allocator);

    var antinodes = try findAntinodes(std.testing.allocator, matrix);
    defer antinodes.deinit();

    try std.testing.expectEqual(4, antinodes.count());
}

fn process(comptime text: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var matrix = try createMatrixFromText(allocator, text);
    defer matrix.deinit(allocator);

    shared.sparse_matrix.printMatrix(matrix.inner);

    var antinodes = try findAntinodes(allocator, matrix);
    defer antinodes.deinit();

    return antinodes.count();
}

pub fn main() !void {
    const result = try process(DATA);
    std.debug.print("{d}\n", .{result});
}

test "example" {
    try std.testing.expectEqual(34, try process(EXAMPLE_DATA));
}
