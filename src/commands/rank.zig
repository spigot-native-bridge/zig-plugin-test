const std = @import("std");
const bridge = @import("zig-bridge");
const root = @import("root");
const _rank = @import("../rank.zig");

const commands = bridge.commands;
const types = bridge.types;

const Message = bridge.chat.Message;

const CommandSender = commands.CommandSender;
const SubcommandMap = commands.SubcommandMap;
const Command = commands.Command;

const RankRegistry = _rank.RankRegistry;

pub const RankCommand = Command{
    .name = "rank",
    .description = "Command for managing ranks",
    .callback = internal.rankCommand,
    .init = internal.init,
    .subcommands = SubcommandMap.initComptime(.{
        .{ "list", internal.RankListCommand },
        .{ "create", internal.RankCreateCommand },
        .{ "set", internal.set.RankSetCommand },
    }),
};

pub const internal = struct {
    var state: *root.PluginState = undefined;
    var rankRegistry: *RankRegistry = undefined;

    pub const RankListCommand = Command{
        .name = "list",
        .description = "List all of the registered ranks",
        .callback = internal.rankListCommand,
    };

    pub const RankCreateCommand = Command{
        .name = "create",
        .description = "Create a new rank",
        .usageMessage = "/rank create <name>",
        .callback = internal.rankCreateCommand,
    };

    pub fn init() !void {
        state = &root.pluginState;
        rankRegistry = &state.rankRegistry;
    }

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

            if (iterator.len >= idx) {
                try message.appendPart(.{ .text = ", ", .modifiers = &.{.reset} });
            }
        }

        try sender.sendChatMessage(message);
    }

    pub fn rankCreateCommand(sender: CommandSender, _: []const u8, args: [][]const u8) !void {
        if (args.len != 1) {
            try sender.sendMessage("This command only takes a single argument.");
            return;
        }

        const name = args[0];

        root.pluginState.rankRegistry.registerRank(.{ .name = name, .id = try std.ascii.allocLowerString(root.pluginState.allocator, name) }) catch |e| {
            try sender.sendMessageFormat("Failed to create rank, {any}", .{e});
        };
    }

    pub const set = struct {
        pub const RankSetCommand = Command{
            .name = "set",
            .description = "A list of commands to control variables of a rank.",
            .subcommands = SubcommandMap.initComptime(.{
                .{ "prefix", RankSetPrefixCommand },
                .{ "color", RankSetColorCommand },
            }),
        };

        pub const RankSetPrefixCommand = Command{
            .name = "prefix",
            .description = "Set the prefix of a rank",
            .callback = rankSetPrefixCommand,
        };

        pub const RankSetColorCommand = Command{
            .name = "color",
            .description = "Set the color of a rank",
            .callback = rankSetColorCommand,
        };

        pub fn rankSetPrefixCommand(sender: CommandSender, _: []const u8, args: [][]const u8) !void {
            if (args.len != 2) {
                try sender.sendMessage("This command takes two arguments.");
                return;
            }

            const id = args[0];
            const prefix = args[1];

            var rank = rankRegistry.getRank(id) orelse {
                try sender.sendMessageFormat("No rank found with the id '{s}'", .{id});
                return;
            };

            rank.prefix = try bridge.chat.translateColor("&", prefix);
        }

        pub fn rankSetColorCommand(sender: CommandSender, _: []const u8, args: [][]const u8) !void {
            if (args.len != 2) {
                try sender.sendMessage("This command takes two arguments.");
                return;
            }

            const id = args[0];
            const color = args[1];

            var rank = rankRegistry.getRank(id) orelse {
                try sender.sendMessageFormat("No rank found with the id '{s}'", .{id});
                return;
            };

            const colorTyped = std.meta.stringToEnum(bridge.chat.Color, color) orelse {
                try sender.sendMessageFormat("No color found by the name '{s}'", .{color});
                return;
            };

            rank.color = colorTyped;
        }
    };
};
