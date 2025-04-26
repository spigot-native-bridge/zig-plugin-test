const std = @import("std");
const bridge = @import("zig-bridge");
const root = @import("root");

const commands = bridge.commands;
const types = bridge.types;

const Message = bridge.chat.Message;

const CommandSender = commands.CommandSender;
const Command = commands.Command;
const SubcommandMap = commands.SubcommandMap;

pub const RankCommand = Command{
    .name = "rank",
    .description = "Command for managing ranks",
    .callback = rankCommand,
    .subcommands = SubcommandMap.initComptime(.{
        .{
            "list", Command{
                .name = "list",
                .description = "List all of the registered ranks",
                .callback = rankListCommand,
            },
        },
    }),
};

// todo: implement
pub fn rankCommand(sender: CommandSender, _: []const u8, _: [][]const u8) !void {
    try sender.sendMessage("parent command :)");
}

pub fn rankListCommand(sender: CommandSender, _: []const u8, _: [][]const u8) !void {
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

    try sender.sendChatMessage(message);
}
