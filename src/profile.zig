const std = @import("std");
const bridge = @import("zig-bridge");
const rank = @import("rank.zig");

const types = bridge.types;

const UniqueId = types.UniqueId;
const Player = types.player.Player;

const RankId = rank.RankId;

pub const Profile = struct {
    const Self = @This();

    id: UniqueId,
    parentRank: RankId,

    pub fn getRank(self: *const Self, registry: rank.RankRegistry) ?rank.Rank {
        return registry.getRank(self.parentRank);
    }
};

pub const ProfileRegistry = struct {
    const Self = @This();

    profiles: std.AutoHashMap(UniqueId, Profile),

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .profiles = std.AutoHashMap(UniqueId, Profile).init(allocator),
        };
    }

    pub fn registerProfile(self: *Self, profile: Profile) !void {
        try self.profiles.put(profile.id, profile);
    }

    pub fn getProfile(self: *const Self, id: UniqueId) *?Profile {
        return @constCast(&self.profiles.get(id));
    }
};
