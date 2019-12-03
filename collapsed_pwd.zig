const std = @import("std");
const mem = std.mem;

fn shorten(allocator: *mem.Allocator, input: []const u8) ![]const u8 {
    const envMap = try std.process.getEnvMap(allocator);
    var buf = try std.Buffer.initCapacity(allocator, input.len);
    var start: usize = 0;
    if (envMap.get("HOME")) |home| {
        if (mem.startsWith(u8, input, home)) {
            try buf.append("~/");
            start = home.len;
        } else {
            try buf.append("/");
        }
    }
    const sepStr = &[_]u8{std.fs.path.sep};
    var it = mem.tokenize(input[start..], sepStr);
    while (it.next()) |part| {
        if (it.index < (it.buffer.len - it.delimiter_bytes.len)) {
            if (part.len > 4) {
                try buf.append(part[0..4]);
                try buf.append("…");
            } else {
                try buf.append(part);
            }
            try buf.append(sepStr);
        } else try buf.append(part);
    }
    return buf.toOwnedSlice();
}

pub fn main() !void {
    var buf: [1024 * 8]u8 = undefined;
    const allocator = &std.heap.FixedBufferAllocator.init(&buf).allocator;
    const cwd = try std.process.getCwdAlloc(allocator);
    try (std.io.getStdOut().outStream().stream).print("{}\n", try shorten(allocator, cwd));
}
