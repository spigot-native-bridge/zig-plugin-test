const bridge = @import("zig-bridge");
const root = @import("root");
const types = bridge.types;

const Message = bridge.chat.Message;
const Player = bridge.types.player.Player;

// todo: implement
pub fn rankCommand(player: Player, _: []const u8, _: []const u8) !void {
    var message = try Message.init(bridge.native_plugin.state.allocator, .{});
    var iterator = root.pluginState.rankRegistry.ranks.valueIterator();
    var idx: u32 = 0;

    while (iterator.next()) |rank| {
        idx += 1;

        try message.appendPart(.{
            .color = rank.color,
            .modifiers = rank.modifiers,
            .text = rank.name,
        });

        if (iterator.len > idx) {
            try message.appendPart(.{ .text = ", ", .modifiers = &.{.reset} });
        }
    }

    try player.sendChatMessage(message);
}
