//! Solution for: https://adventofcode.com/2024/day/6

const std = @import("std");
const testing = std.testing;
const DATA = @embedFile("data.txt");
const EXAMPLE_DATA = @embedFile("data.example.txt");

const Coordinate = struct {
    x: usize,
    y: usize,
};

const Position = struct {
    const Self = @This();

    v: u8,
    x: usize,
    y: usize,

    fn turn(self: Self) Self {
        return Self{
            .v = switch (self.v) {
                '^' => '>',
                '>' => 'v',
                'v' => '<',
                '<' => '^',
                else => self.v,
            },
            .x = self.x,
            .y = self.y,
        };
    }

    fn moveUp(self: Self) ?Self {
        if (self.y == 0) return null;
        return Self{
            .v = self.v,
            .x = self.x,
            .y = self.y - 1,
        };
    }

    fn moveDown(self: Self) ?Self {
        return Self{
            .v = self.v,
            .x = self.x,
            .y = self.y + 1,
        };
    }

    fn moveLeft(self: Self) ?Self {
        if (self.x == 0) return null;
        return Self{
            .v = self.v,
            .x = self.x - 1,
            .y = self.y,
        };
    }

    fn moveRight(self: Self) ?Self {
        return Self{
            .v = self.v,
            .x = self.x + 1,
            .y = self.y,
        };
    }
};

const Map = std.MultiArrayList(Position);

const BoundedMap = struct {
    const Self = @This();

    map: Map,
    width: usize,
    height: usize,

    fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.map.deinit(allocator);
    }

    fn fromText(allocator: std.mem.Allocator, comptime text: []const u8) !Self {
        // Note: This function could accept a function to select which items are inserted
        // However, that is beyond the scope of what I'm willing to do to generalize this solution so far.

        var map = Map{};
        var width: usize = 0;
        var height: usize = 0;

        var rows = std.mem.splitScalar(u8, text, '\n');
        while (rows.next()) |line| {
            if (line.len == 0) break;

            defer height += 1;

            if (height == 0) {
                width = line.len;
            }

            for (line, 0..) |char, i| {
                if (char != '.') {
                    try map.append(allocator, Position{
                        .v = char,
                        .x = i,
                        .y = height,
                    });
                }
            }
        }

        return Self{
            .map = map,
            .height = height,
            .width = width,
        };
    }

    fn print(self: Self) void {
        const fmt =
            \\Dimensions: {d} by {d}
            \\V: {c}
            \\X: {d}
            \\Y: {d}
            \\
        ;

        std.debug.print(fmt, .{
            self.width,
            self.height,
            self.map.items(.v),
            self.map.items(.x),
            self.map.items(.y),
        });
    }

    fn contains(self: Self, pos: Position) bool {
        return pos.x < self.width and pos.y < self.height;
    }

    fn getGuard(self: Self) ?Position {
        for (self.map.items(.v), 0..) |v, i| {
            const isGuard = switch (v) {
                'v', '<', '>', '^' => true,
                else => false,
            };

            if (isGuard) {
                return self.map.get(i);
            }
        }

        return null;
    }

    fn getValueAt(self: Self, row: usize, col: usize) ?u8 {
        const rows = self.map.items(.x);
        const cols = self.map.items(.y);

        const colRangeStart = std.mem.indexOfScalar(usize, cols, col) orelse return null;
        const colRangeEnd = (std.mem.lastIndexOfScalar(usize, cols[colRangeStart..], col) orelse return null) + colRangeStart;
        const foundItemPosition = (std.mem.indexOfScalar(usize, rows[colRangeStart .. colRangeEnd + 1], row) orelse return null) + colRangeStart;

        return self.map.get(foundItemPosition).v;
    }
};

test "getValueAt == 'X'" {
    const data =
        \\X...
        \\....
        \\....
    ;

    var bm = try BoundedMap.fromText(std.testing.allocator, data);
    defer bm.deinit(std.testing.allocator);
    errdefer bm.print();

    try std.testing.expectEqual('X', bm.getValueAt(0, 0));
}

fn getNextPosition(guard: Position, bm: BoundedMap) ?Position {
    const potentialPosition = switch (guard.v) {
        '^' => guard.moveUp(),
        'v' => guard.moveDown(),
        '<' => guard.moveLeft(),
        '>' => guard.moveRight(),
        else => null,
    } orelse return null;

    if (!bm.contains(potentialPosition)) return null;

    if (bm.getValueAt(potentialPosition.x, potentialPosition.y) == '#') {
        return guard.turn();
    }

    return potentialPosition;
}

fn process(allocator: std.mem.Allocator, comptime text: []const u8) !usize {
    var bm = try BoundedMap.fromText(allocator, text);
    defer bm.deinit(allocator);

    bm.print();

    var guard: Position = bm.getGuard() orelse return 0;

    var positionsHistory = std.AutoArrayHashMap(Coordinate, void).init(allocator);
    defer positionsHistory.deinit();

    try positionsHistory.put(.{ .x = guard.x, .y = guard.y }, undefined);

    while (getNextPosition(guard, bm)) |pos| {
        defer guard = pos;

        try positionsHistory.put(.{ .x = pos.x, .y = pos.y }, undefined);
    }

    // for (positionsHistory.keys(), 0..) |key, i| {
    //     std.debug.print("{d}: {any}\n", .{ i, key });
    // }

    return positionsHistory.count();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const result = try process(allocator, DATA);
    std.debug.print("Number of distinct positions: {d}\n", .{result});
}
