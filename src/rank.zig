const std = @import("std");
const bridge = @import("zig-bridge");

const chat = bridge.chat;

const Color = chat.Color;
const Modifier = chat.Modifier;

pub const RankId = []const u8;

pub const Rank = struct {
    id: RankId,
    name: []const u8,
    color: Color = .white,
    modifiers: []const Modifier = &.{},
    prefix: []const u8 = "",
};

pub const RankRegistry = struct {
    const Self = @This();

    //ranks: std.AutoHashMap(RankId, Rank),
    ranks: std.StringHashMap(Rank),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .ranks = std.StringHashMap(Rank).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn registerRank(self: *Self, rank: Rank) !void {
        try self.ranks.put(rank.id, rank);
    }

    pub fn getRank(self: *const Self, id: RankId) ?*Rank {
        return self.ranks.getPtr(id);
    }

    pub fn getFile() std.fs.File {
        std.fs.cwd().access("ranks.json", .{}) catch {
            return std.fs.cwd().createFile("ranks.json", .{ .truncate = false }) catch {
                unreachable;
            };
        };

        return std.fs.cwd().openFile("ranks.json", .{}) catch unreachable;
    }

    pub fn loadRanks(self: *Self) !void {
        const file = getFile();
        defer file.close();

        const json = file.readToEndAlloc(self.allocator, 4096) catch return;
        const ranks = std.json.parseFromSlice([]Rank, self.allocator, json, .{}) catch {
            unreachable;
            //return;
        };

        for (ranks.value) |rank| {
            try self.registerRank(rank);
        }
    }

    pub fn saveRanks(self: *const Self) !void {
        var string = std.ArrayList(u8).init(self.allocator);
        var rankList = std.ArrayList(Rank).init(self.allocator); // yikes.

        var ranks = self.ranks.valueIterator();

        while (ranks.next()) |rank| {
            try rankList.append(rank.*);
        }

        std.json.stringify(rankList.items, .{}, string.writer()) catch unreachable;

        const file = std.fs.cwd().createFile("ranks.json", .{}) catch {
            unreachable;
        };

        defer file.close();

        file.writeAll(try string.toOwnedSlice()) catch unreachable;
    }
};
