const std = @import("std");
const bridge = @import("zig-bridge");
const _rank = @import("rank.zig");
const _profile = @import("profile.zig");

pub const pluginState = struct {
    pub var profileRegistry: ProfileRegistry = undefined;
    pub var rankRegistry: RankRegistry = undefined;

    pub fn init(state: *plugin.PluginState) !void {
        profileRegistry = ProfileRegistry.init(state.allocator);
        rankRegistry = RankRegistry.init(state.allocator);
    }
};

const ProfileRegistry = _profile.ProfileRegistry;
const Profile = _profile.Profile;

const RankRegistry = _rank.RankRegistry;
const Rank = _rank.Rank;

const plugin = bridge.native_plugin;
const events = bridge.events;
const chat = bridge.chat;

const BridgeError = bridge.BridgeError;

const Message = chat.Message;

pub export fn load(state: *plugin.PluginState) void {
    // by default, bridge-zig can only see the load() function, so we have to pass our
    // enable and disable functions to the PluginState so they can be called whenever required.
    state.markPlugin(enable, disable);

    pluginState.init(state) catch unreachable;
}

pub fn enable(state: *plugin.PluginState) BridgeError!void {
    // set the plugin signature for commands
    // this is for the fallback prefix (e.g., /zoop:rank)
    state.commandRegistry.setPluginSignature("zoop");

    // commandRegistry is not yet available in onLoad
    try state.commandRegistry.registerCommand(@import("commands/rank.zig").RankCommand);

    // 'listenFallible' for an event listener that can return an error (specifically, BridgeError, meaning, BridgeError!void)
    // 'listen' for an event listener that simply returns 'void'
    try state.eventRegistry.listenFallible(events.blocks.BlockBreakEvent, handleBlockBreakEvent);
    try state.eventRegistry.listenFallible(events.player.PlayerJoinEvent, onPlayerJoin);
    try state.eventRegistry.listenFallible(events.player.PlayerChatEvent, onChatMessage);

    // default is events.debugErrorCallback
    state.eventRegistry.setErrorCallback(events.debugErrorCallback);

    try pluginState.rankRegistry.registerRank(.{
        .id = "developer",
        .name = "Developer",
        .prefix = try chat.translateColor("&", "&7[&bDeveloper&7]&b"),
        .color = .aqua,
        .modifiers = &.{.italic},
    });
    try pluginState.rankRegistry.registerRank(.{
        .id = "owner",
        .name = "Owner",
        .prefix = try chat.translateColor("&", "&7[&4Owner&7]&4"),
        .color = .dark_red,
    });
}

pub fn disable(_: *plugin.PluginState) BridgeError!void {
    std.debug.print("plugin has disabled... - zig", .{});
}

pub fn onPlayerJoin(event: *events.player.PlayerJoinEvent) BridgeError!void {
    try pluginState.profileRegistry.registerProfile(
        .{
            .id = try event.player.getUniqueId(),
            .parentRank = "owner",
        },
    );

    const message = try Message.initSlice(
        plugin.state.allocator,
        &.{
            .{ .text = "meow", .color = .aqua, .modifiers = &.{ .italic, .bold } },
            .{ .text = "wowie yellow", .color = .yellow },
        },
    );

    try event.player.sendChatMessage(message);
}

// sadly not AsyncPlayerChatEvent (yet)
pub fn onChatMessage(event: *events.player.PlayerChatEvent) BridgeError!void {
    const uniqueId = try event.player.getUniqueId();

    // todo: improve
    const profile = pluginState.profileRegistry.getProfile(uniqueId).* orelse return error.NotFound;
    const rank = profile.getRank(pluginState.rankRegistry) orelse return BridgeError.NotFound;

    const prefix = rank.prefix;

    try event.setFormat(
        try chat.translateColor("&", try std.fmt.allocPrint(plugin.state.allocator, "{s}%1$s&f: %2$s", .{prefix})),
    );
}

pub fn handleBlockBreakEvent(event: *events.blocks.BlockBreakEvent) BridgeError!void {
    event.setCancelled(true);
}
