usingnamespace @import("std").c;
const os = @import("std").os;

const atomvm = @cImport({
    @cInclude("zig_shim.h");
});

pub fn main() u8 {
    return @intCast(u8, atomvm.c_main(
        @intCast(c_int, os.argv.len),
        @ptrCast([*c][*c]u8, os.argv.ptr)));
}