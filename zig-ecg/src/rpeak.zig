const std = @import("std");

pub fn derivative(
    allocator: std.mem.Allocator,
    input: []f64,
) ![]f64 {

    var out = try allocator.alloc(f64, input.len);
    out[0] = 0.0;

    for (1..input.len) |i| {
        out[i] = input[i] - input[i - 1];
    }

    return out;
}

pub fn square(
    allocator: std.mem.Allocator,
    input: []f64,
) ![]f64 {

    var out = try allocator.alloc(f64, input.len);

    for (input, 0..) |v, i| {
        out[i] = v * v;
    }

    return out;
}

pub fn movingAverage(
    allocator: std.mem.Allocator,
    input: []f64,
    window: usize,
) ![]f64 {

    var out = try allocator.alloc(f64, input.len);
    var sum: f64 = 0.0;

    for (0..input.len) |i| {
        sum += input[i];
        if (i >= window) {
            sum -= input[i - window];
        }

        if (i < window) {
            out[i] = sum / @as(f64, @floatFromInt(i + 1));
        } else {
            out[i] = sum / @as(f64, @floatFromInt(window));
        }
    }

    return out;
}

pub fn detectPeaks(
    allocator: std.mem.Allocator,
    signal: []f64,
    fs: f64,
) ![]usize {

    const refractory = @as(usize, @intFromFloat(0.2 * fs));
    
    var peaks_list: std.ArrayList(usize) = .{};
    errdefer peaks_list.deinit(allocator);

    var max_val: f64 = 0.0;
    for (signal) |v| {
        if (v > max_val) max_val = v;
    }

    const threshold = 0.3 * max_val;

    var last_peak: isize = -@as(isize, @intCast(refractory));

    for (1..signal.len - 1) |i| {
        if (signal[i] > threshold and
            signal[i] > signal[i - 1] and
            signal[i] > signal[i + 1] and
            @as(isize, @intCast(i)) - last_peak >= @as(isize, @intCast(refractory)))
        {
            try peaks_list.append(allocator, i);
            last_peak = @as(isize, @intCast(i));
        }
    }

    return try peaks_list.toOwnedSlice(allocator);
}

pub fn rPeakDetect(
    allocator: std.mem.Allocator,
    ecg: []f64,
    fs: f64,
) ![]usize {

    const diff = try derivative(allocator, ecg);
    defer allocator.free(diff);

    const sq = try square(allocator, diff);
    defer allocator.free(sq);

    const win = @as(usize, @intFromFloat(0.15 * fs));
    const ma = try movingAverage(allocator, sq, win);
    defer allocator.free(ma);

    return detectPeaks(allocator, ma, fs);
}

