const std = @import("std");

const ReadListError = error{not_enough};

pub fn readList(allocator: std.mem.Allocator) ![]usize {
    var reader = std.io.getStdIn().reader();

    // This buffer was too short before, causing truncation. I am surprised
    // Zig didn't return an error. Oh well.
    var buffer: [1024 * 10]u8 = undefined;
    @memset(&buffer, 0);

    var list_count_str = reader.readUntilDelimiter(&buffer, '\n') catch "0";
    var list_count_trim = std.mem.trim(u8, list_count_str, &std.ascii.whitespace);
    var list_count = try std.fmt.parseInt(usize, list_count_trim, 10);
    @memset(&buffer, 0);

    var list_str = reader.readUntilDelimiter(&buffer, '\n') catch "";
    var list_iterator = std.mem.splitAny(u8, list_str, &std.ascii.whitespace);
    var list = try allocator.alloc(usize, list_count);
    @memset(list, 0);

    for (list) |*e| {
        var entry = list_iterator.next() orelse return ReadListError.not_enough;
        var num = try std.fmt.parseInt(usize, entry, 10);
        e.* = num;
    }

    return list;
}

const PurchaseStatus = enum {
    impossible,
    possible,
    ambiguous,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var menu = try readList(allocator);

    var purchase_status: [30001]PurchaseStatus = undefined;
    @memset(&purchase_status, .impossible);
    var purchase_lut: [30001][100]usize = undefined;
    for (&purchase_lut) |*lut| {
        @memset(lut, 0);
    }
    purchase_status[0] = .possible;

    for (0..purchase_lut.len) |value| {
        var current_status = purchase_status[value];
        if (current_status == .impossible) {
            continue;
        }
        for (menu, 0..) |item, item_index| {
            const next_index = value + item;
            if (next_index >= purchase_lut.len) {
                continue;
            }

            const next_status = purchase_status[next_index];
            if (next_status == .ambiguous or current_status == .ambiguous) {
                // The current_status check is important. If we do not do this
                // then things get out of order.
                purchase_status[next_index] = .ambiguous;
                continue;
            }

            var next_lut = purchase_lut[value];
            next_lut[item_index] += 1;

            //if (next_index == 1290 or next_index == 1505) {
            //    std.debug.print("reached this point ({})! {} valued {} from {} with {any}\n", .{ next_index, item_index, item, value, next_lut });
            //}

            if (next_status == .possible and !std.mem.eql(usize, &next_lut, &purchase_lut[next_index])) {
                purchase_status[next_index] = .ambiguous;
                continue;
            }
            purchase_lut[next_index] = next_lut;
            purchase_status[next_index] = .possible;
        }
    }

    // for (0..2000) |i| {
    //     if (i % 215 == 0 or i == 925 or i == 1150 or i == 1290) {
    //         std.debug.print("{d}: {any} ({})\n", .{ i, purchase_lut[i][0..menu.len], purchase_status[i] });
    //     }
    // }

    var orders = try readList(allocator);

    for (orders) |order| {
        const status = purchase_status[order];
        if (status == .impossible) {
            try std.io.getStdOut().writer().print("Impossible\n", .{});
            continue;
        }
        if (status == .ambiguous) {
            try std.io.getStdOut().writer().print("Ambiguous\n", .{});
            continue;
        }
        for (purchase_lut[order][0..menu.len], 0..) |v, i| {
            for (0..v) |_| {
                try std.io.getStdOut().writer().print("{d} ", .{i + 1});
            }
        }
        try std.io.getStdOut().writer().print("\n", .{});
    }
}

// 12490298
