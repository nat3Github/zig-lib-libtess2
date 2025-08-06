const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const translate = b.addTranslateC(.{
        .optimize = optimize,
        .target = target,
        .link_libc = true,
        .root_source_file = b.path("Include/tesselator.h"),
    });

    const libtess_c = translate.addModule("libtess_c");
    libtess_c.addIncludePath(b.path("Include"));
    libtess_c.addIncludePath(b.path("Source"));
    libtess_c.addCSourceFiles(.{ .files = &.{
        "Source/geom.c",
        "Source/sweep.c",
        "Source/bucketalloc.c",
        "Source/mesh.c",
        "Source/tess.c",
        "Source/dict.c",
        "Source/priorityq.c",
    } });
    libtess_c.link_libc = true;
    const libtess_mod = b.addModule("libtess", .{
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path("src/libtess.zig"),
    });
    libtess_mod.addImport("c", libtess_c);
    const exe_unit_tests = b.addTest(.{
        .root_module = libtess_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
