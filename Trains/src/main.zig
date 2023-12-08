const std = @import("std");

//
//   6 5 2 4 7 8 9
//               ^
//             ^ 1
//           ^ 2 0
//         ^ 3 0
//         3 0
//         1

fn longest_train(allocator: std.mem.Allocator, cars_list: []usize) !usize {
    if (cars_list.len < 2) {
        // Handles edge cases 0 and 1.
        return cars_list.len;
    }

    var best_length: usize = 0;
    var ascending = try allocator.alloc(usize, cars_list.len);
    var descending = try allocator.alloc(usize, cars_list.len);

    var i: usize = cars_list.len;
    while (true) {
        i -= 1;
        ascending[i] = 0;
        descending[i] = 0;
        //std.debug.print("i = {d}\n", .{i});
        for (i + 1..cars_list.len) |j| {
            //std.debug.print("    j = {d}\n", .{j});
            if (cars_list[i] > cars_list[j] and ascending[i] < ascending[j] + 1) {
                ascending[i] = ascending[j] + 1;
            } else if (cars_list[j] >= cars_list[i] and descending[i] < descending[j] + 1) {
                descending[i] = descending[j] + 1;
            }
            best_length = @max(ascending[i] + descending[i] + 1, best_length);
        }
        if (i == 0) {
            break;
        }
    }
    return best_length;
}

pub fn main() !void {
    var cars_expected: usize = 0;
    var header_parsed = false;

    var reader = std.io.getStdIn().reader();
    var buffer: [256]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var cars_added: usize = 0;
    var cars_list: []usize = undefined;
    while (reader.readUntilDelimiter(&buffer, '\n')) |line| {
        var number = try std.fmt.parseInt(usize, line, 10);
        if (header_parsed) {
            cars_list[cars_added] = number;
            cars_added += 1;
        } else {
            cars_expected = number;
            cars_list = try allocator.alloc(usize, cars_expected);
            header_parsed = true;
        }

        if (cars_added >= cars_expected) {
            break;
        }
    } else |_| {}

    const best_length = try longest_train(allocator, cars_list);
    try std.io.getStdOut().writer().print("{d}", .{best_length});
}

// 12487970
