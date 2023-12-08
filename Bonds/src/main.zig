const std = @import("std");

const CacheKey = [32]u1;
const StringHashMapF64 = std.AutoHashMap(CacheKey, f64);

fn best_bonds_column(cache: []StringHashMapF64, banned_rows: CacheKey, column: usize, rows: usize, missions_list: []usize) !f64 {
    if (cache[column].get(banned_rows)) |v| {
        return v;
    }

    if (column == 0) {
        // The last column does not search past itself.
        var best_odds: f64 = 0;
        for (0..rows) |i| {
            if (banned_rows[i] == 0) {
                const that = missions_list[i];
                const that_float: f64 = @floatFromInt(that);
                best_odds = @max(best_odds, that_float / 100);
            }
        }

        try cache[0].put(banned_rows, best_odds);
        return best_odds;
    }

    var best_odds: f64 = 0;
    for (0..rows) |i| {
        if (banned_rows[i] == 0) {
            const that = missions_list[i + rows * column];
            const that_float: f64 = @floatFromInt(that);

            var new_banned_rows = banned_rows;
            new_banned_rows[i] = 1;
            const previous_odds = try best_bonds_column(cache, new_banned_rows, column - 1, rows, missions_list);
            best_odds = @max(best_odds, previous_odds * (that_float / 100));
        }
    }

    if (rows > column + 4) {
        try cache[column].put(banned_rows, best_odds);
    }
    return best_odds;
}

pub fn main() !void {
    var header_parsed = false;

    var reader = std.io.getStdIn().reader();
    var buffer: [256]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var missions_list: []usize = undefined;
    var bonds_count: usize = 0;
    var bonds_added: usize = 0;
    while (reader.readUntilDelimiter(&buffer, '\n')) |line| {
        if (header_parsed) {
            var iterator = std.mem.splitScalar(u8, line, ' ');
            for (0..bonds_count) |i| {
                var num_str = iterator.next() orelse @panic("not enough numbers");
                var number = try std.fmt.parseInt(usize, num_str, 10);
                missions_list[bonds_added + i * bonds_count] = number;
            }
            bonds_added += 1;
        } else {
            var number = try std.fmt.parseInt(usize, line, 10);
            bonds_count = number;
            missions_list = try allocator.alloc(usize, bonds_count * bonds_count);
            header_parsed = true;
        }
        if (bonds_added >= bonds_count) {
            break;
        }
    } else |_| {}

    if (bonds_added == 0) {
        try std.io.getStdOut().writer().print("0", .{});
        return; // Man, you ugly!
    }

    var cache = try allocator.alloc(StringHashMapF64, bonds_added);
    for (cache) |*c| {
        c.* = StringHashMapF64.init(allocator);
    }

    var banned_rows: CacheKey = undefined;
    @memset(&banned_rows, 0);

    const best_length = try best_bonds_column(cache, banned_rows, bonds_added - 1, bonds_added, missions_list);
    try std.io.getStdOut().writer().print("{d:.20}\n", .{best_length * 100});
}

// 12487958
