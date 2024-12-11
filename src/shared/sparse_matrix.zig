const std = @import("std");

pub const Distance = struct {
    const Self = @This();

    rows: isize,
    cols: isize,

    pub fn reverse(self: Self) Self {
        return Self{
            .rows = -self.rows,
            .cols = -self.cols,
        };
    }
};

test "reverse distance" {
    try std.testing.expectEqual((Distance{ .rows = -1, .cols = -1 }), (Distance{ .rows = 1, .cols = 1 }).reverse());
}

pub const SparseMatrixElement = struct {
    const Self = @This();

    v: u8,
    row: usize,
    col: usize,

    pub fn dist(self: Self, other: Self) Distance {
        return Distance{
            .rows = @as(isize, @intCast(other.row)) - @as(isize, @intCast(self.row)),
            .cols = @as(isize, @intCast(other.col)) - @as(isize, @intCast(self.col)),
        };
    }

    pub fn place(self: Self, distance: Distance, value: u8) ?Self {
        const row = std.math.add(isize, @intCast(self.row), distance.rows) catch return null;
        const col = std.math.add(isize, @intCast(self.col), distance.cols) catch return null;

        if (row < 0 or col < 0) return null;

        return Self{
            .v = value,
            .row = @intCast(row),
            .col = @intCast(col),
        };
    }
};

test "dist" {
    // Happy path
    try std.testing.expectEqual(Distance{ .rows = 1, .cols = 1 }, (SparseMatrixElement{ .v = 'A', .row = 1, .col = 1 }).dist(SparseMatrixElement{ .v = 'A', .row = 2, .col = 2 }));
}

test "move" {
    // Happy path
    try std.testing.expectEqual(SparseMatrixElement{ .v = '#', .row = 1, .col = 1 }, (SparseMatrixElement{ .v = 'A', .row = 0, .col = 0 }).place(Distance{ .rows = 1, .cols = 1 }, '#'));

    // Negative rows
    try std.testing.expectEqual(null, (SparseMatrixElement{ .v = 'A', .row = 0, .col = 0 }).place(.{ .cols = 0, .rows = -1 }, '#'));

    // Negative columns
    try std.testing.expectEqual(null, (SparseMatrixElement{ .v = 'A', .row = 0, .col = 0 }).place(.{ .cols = -1, .rows = 0 }, '#'));
}

pub const SparseMatrix = std.MultiArrayList(SparseMatrixElement);

pub fn SparseMatrixOfAny(allocator: std.mem.Allocator, haystack: []const u8, needle: []const u8) SparseMatrix {
    var matrix = SparseMatrix{};
    var lines = std.mem.splitScalar(u8, haystack, '\n');

    var row: usize = 0;
    while (lines.next()) |line| {
        defer row += 1;

        for (line, 0..) |char, col| {
            if (std.mem.containsAtLeast(u8, needle, 1, char)) {
                matrix.append(allocator, SparseMatrixElement{
                    .v = char,
                    .row = row,
                    .col = col,
                });
            }
        }
    }

    return matrix;
}

pub fn printMatrix(matrix: SparseMatrix) void {
    const format =
        \\== SparseMatrix ==
        \\V: {c}
        \\COL: {d}
        \\ROW: {d}
        \\== SparseMatrix ==
        \\
    ;

    std.debug.print(format, .{
        matrix.items(.v),
        matrix.items(.col),
        matrix.items(.row),
    });
}
