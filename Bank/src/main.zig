const std = @import("std");

const Customer = struct {
    time_left: usize,
    value: usize,
};

fn mostImpatient(context: void, a: Customer, b: Customer) std.math.Order {
    _ = context;
    return std.math.order(a.time_left, b.time_left);
}

pub fn main() !void {
    var customer_count: usize = 0;
    var bank_time_left: usize = 0;

    var header_parsed = false;

    var reader = std.io.getStdIn().reader();
    var buffer: [256]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var pq = std.PriorityQueue(Customer, void, mostImpatient).init(allocator, void{});

    while (reader.readUntilDelimiter(&buffer, '\n')) |line| {
        var iterator = std.mem.splitScalar(u8, line, ' ');
        var first = iterator.next() orelse @panic("syntax error: early stop");
        var second = iterator.next() orelse @panic("syntax error: early stop");

        var first_number = try std.fmt.parseInt(usize, first, 10);
        var second_number = try std.fmt.parseInt(usize, second, 10);

        if (header_parsed) {
            try pq.add(Customer{
                .value = first_number,
                .time_left = second_number,
            });
        } else {
            customer_count = first_number;
            bank_time_left = second_number;
            header_parsed = true;
        }

        if (pq.len >= customer_count) {
            break;
        }
    } else |_| {}

    // Where index is a certain time slot.
    var customers = try allocator.alloc(Customer, @min(bank_time_left, customer_count));
    @memset(customers, Customer{ .time_left = 0, .value = 0 });
    while (pq.len > 0) {
        var elem = pq.remove();
        //std.debug.print("now having prcoessing: {d}\n", .{elem.value});
        while (true) {
            var smallest_slot: usize = 0;
            var smallest_value: usize = customers[0].value;

            for (customers[0..@min(elem.time_left + 1, customers.len)], 0..) |slot, index| {
                if (slot.value < smallest_value) {
                    smallest_slot = index;
                    smallest_value = slot.value;
                }
            }
            //std.debug.print("the smallest slot is: {d}\n", .{smallest_slot});
            if (customers[smallest_slot].value < elem.value) {
                var next = customers[smallest_slot];
                //std.debug.print("element: {d} to slot {d}\n", .{ elem.value, smallest_slot });
                customers[smallest_slot] = elem;
                elem = next;
                if (next.value == 0) {
                    break;
                }
            } else {
                break;
            }
        }
    }

    var accumulator: i64 = 0;
    for (customers) |customer| {
        accumulator += @intCast(customer.value);
    }

    try std.io.getStdOut().writer().print("{d}", .{accumulator});
}

// 12468449
