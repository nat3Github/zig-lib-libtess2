const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const translate = b.addTranslateC(.{ .optimize = optimize, .target = target, .root_source_file = b.path("Include/tesselator.h") });
    const libtess_c = translate.addModule("libtess");
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
}
