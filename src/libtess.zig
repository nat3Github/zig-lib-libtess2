pub const c = @import("c");
test "ok" {
    var alloc = std.testing.allocator;
    _ = util.tess_alloc_from(&alloc);
}
const lensize = @sizeOf(usize);
const std = @import("std");
const mem = std.mem;

const mem_realloc = struct {
    const bytes_size_of_usize = @sizeOf(usize);
    fn reconstruct_ptr(ptr: [*]u8) []u8 {
        var slice: []u8 = undefined;
        slice.ptr = ptr - @sizeOf(usize);
        slice.len = mem.bytesToValue(usize, slice.ptr[0..@sizeOf(usize)]);
        return slice;
    }

    /// sets the first bytes of the slice to the `size` of the allocation
    fn embeded_slice(slice: []u8) [*]u8 {
        const size = slice.len;
        @memcpy(slice[0..@sizeOf(usize)], mem.toBytes(size)[0..]);
        return slice.ptr + @sizeOf(usize);
    }

    fn size_plus_info(size: c_uint) usize {
        return @as(usize, @intCast(size)) + bytes_size_of_usize;
    }

    fn mem_alloc(user_data: ?*anyopaque, size: c_uint) callconv(.C) ?*anyopaque {
        const alloc: *mem.Allocator = @ptrCast(@alignCast(user_data));
        const slice = alloc.alignedAlloc(u8, bytes_size_of_usize, size_plus_info(size)) catch return null;
        return embeded_slice(slice);
    }

    fn mem_realloc(user_data: ?*anyopaque, ptr: ?*anyopaque, size: c_uint) callconv(.C) ?*anyopaque {
        const alloc: *mem.Allocator = @ptrCast(@alignCast(user_data));
        if (ptr) |p| {
            const old_slice = reconstruct_ptr(@ptrCast(p));
            const new_slice = alloc.realloc(old_slice, size_plus_info(size)) catch return null;
            return embeded_slice(new_slice);
        } else {
            return mem_alloc(user_data, size);
        }
    }

    fn mem_free(user_data: ?*anyopaque, ptr: ?*anyopaque) callconv(.C) void {
        const alloc: *mem.Allocator = @ptrCast(@alignCast(user_data));
        if (ptr) |p| {
            const original_slice = reconstruct_ptr(@ptrCast(p));
            alloc.free(original_slice);
        }
    }
};

pub const util = struct {
    pub fn tess_alloc_from(alloc: *mem.Allocator) c.TESSalloc {
        return c.TESSalloc{
            .memalloc = mem_realloc.mem_alloc,
            .memrealloc = mem_realloc.mem_realloc,
            .memfree = mem_realloc.mem_free,
            .userData = @alignCast(@ptrCast(alloc)),
            .meshEdgeBucketSize = 0,
            .meshVertexBucketSize = 0,
            .meshFaceBucketSize = 0,
            .dictNodeBucketSize = 0,
            .regionBucketSize = 0,
            .extraVertices = 0,
        };
    }
};
