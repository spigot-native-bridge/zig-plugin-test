const std = @import("std");
const bridge = @import("zig-bridge");

const plugin = bridge.native_plugin;
const events = bridge.events;
const chat = bridge.chat;

const BridgeError = bridge.BridgeError;

const Message = chat.Message;

// functions called by mappings/native_plugin.BridgeNativePluginExport
pub export fn load(state: *plugin.PluginState) void {
    // 'listenFallible' for an event listener that can return an error (specifically, BridgeError, meaning, BridgeError!void)
    // 'listen' for an event listener that simply returns 'void'
    state.eventRegistry.listenFallible(events.blocks.BlockBreakEvent, handleBlockBreakEvent) catch unreachable;
    state.eventRegistry.listenFallible(events.player.PlayerJoinEvent, onPlayerJoin) catch unreachable;

    // default is events.debugErrorCallback
    state.eventRegistry.setErrorCallback(events.unreachableErrorCallback);
}

pub export fn enable(state: *plugin.PluginState) void {
    // commandRegistry is not yet available in onLoad
    state.commandRegistry.registerCommand(.{ .name = "meow", .callback = meowCommand }) catch unreachable;
}

pub export fn disable(_: *plugin.PluginState) void {
    std.debug.print("plugin has disabled... - zig", .{});
}

pub fn onPlayerJoin(event: *events.player.PlayerJoinEvent) BridgeError!void {
    const message = try Message.initSlice(
        plugin.state.allocator,
        &.{
            .{ .text = "meow", .color = .aqua, .modifiers = &.{ .italic, .bold } },
            .{ .text = "wowie yellow", .color = .yellow },
        },
    );

    try event.player.sendChatMessage(message);
}

pub fn handleBlockBreakEvent(event: *events.blocks.BlockBreakEvent) BridgeError!void {
    event.setCancelled(true);
}

pub fn meowCommand(player: bridge.types.player.Player, _: []const u8, _: []const u8) !void {
    try player.sendMessage("meowww owo");
}
