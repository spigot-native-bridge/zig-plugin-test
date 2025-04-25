const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "zig_plugin_test",
        .root_module = lib_mod,
    });

    const zig_bridge_module = b.dependency("zig-bridge", .{
        .target = target,
        .optimize = optimize,
    });

    const dep_JNI = b.dependency("jni", .{}).module("JNI");
    lib.root_module.addImport("jni", dep_JNI);

    lib_mod.addImport("zig-bridge", zig_bridge_module.module("zig-bridge"));
    lib.linkLibrary(zig_bridge_module.artifact("zig-bridge"));

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");

    test_step.dependOn(&run_lib_unit_tests.step);
}
