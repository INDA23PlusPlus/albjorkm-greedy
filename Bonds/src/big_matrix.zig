const std = @import("std");

pub fn main() !void {
    var rngDevice = std.rand.DefaultPrng.init(0);
    var rng = rngDevice.random();
    for (0..20) |_| {
        for (0..20) |_| {
            var v = rng.intRangeAtMost(usize, 0, 100);
            std.debug.print("{d} ", .{v});
        }
        std.debug.print("\n", .{});
    }
}
