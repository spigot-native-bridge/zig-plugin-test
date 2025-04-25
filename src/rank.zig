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

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .ranks = std.StringHashMap(Rank).init(allocator),
        };
    }

    pub fn registerRank(self: *Self, rank: Rank) !void {
        try self.ranks.put(rank.id, rank);
    }

    pub fn getRank(self: *const Self, id: RankId) ?Rank {
        return self.ranks.get(id);
    }
};
