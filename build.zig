const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // Quem usa: `const br = b.dependency("br", .{}).module("br");` e `exe.root_module.addImport("br", br);`.
    const mod = b.addModule("br", .{ .root_source_file = b.path("br.zig"), .target = target, .optimize = optimize });
    const tests = b.addTest(.{ .root_module = mod });
    b.step("test", "Os mesmos casos do pacote npm (vetores/casos.json)").dependOn(&b.addRunArtifact(tests).step);
}
