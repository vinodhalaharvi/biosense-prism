const std = @import("std");

pub fn rrIntervals(
    allocator: std.mem.Allocator,
    r_peaks: []usize,
    fs: f64,
) ![]f64 {

    if (r_peaks.len < 2)
        return error.NotEnoughBeats;

    var rr = try allocator.alloc(f64, r_peaks.len - 1);

    for (1..r_peaks.len) |i| {
        const diff_samples = r_peaks[i] - r_peaks[i - 1];
        rr[i - 1] = (@as(f64, @floatFromInt(diff_samples)) / fs) * 1000.0;
    }

    return rr;
}

fn mean(data: []f64) f64 {
    var sum: f64 = 0.0;
    for (data) |v| sum += v;
    return sum / @as(f64, @floatFromInt(data.len));
}

pub fn sdnn(rr: []f64) f64 {
    const mu = mean(rr);

    var sum_sq: f64 = 0.0;
    for (rr) |v| {
        const d = v - mu;
        sum_sq += d * d;
    }

    return std.math.sqrt(sum_sq / @as(f64, @floatFromInt(rr.len - 1)));
}

pub fn rmssd(rr: []f64) f64 {
    var sum_sq: f64 = 0.0;

    for (1..rr.len) |i| {
        const diff = rr[i] - rr[i - 1];
        sum_sq += diff * diff;
    }

    return std.math.sqrt(sum_sq / @as(f64, @floatFromInt(rr.len - 1)));
}

pub fn pnn50(rr: []f64) f64 {
    var count: usize = 0;

    for (1..rr.len) |i| {
        if (@abs(rr[i] - rr[i - 1]) > 50.0) {
            count += 1;
        }
    }

    return (@as(f64, @floatFromInt(count)) / @as(f64, @floatFromInt(rr.len - 1))) * 100.0;
}

pub const HRV = struct {
    sdnn: f64,
    rmssd: f64,
    pnn50: f64,
};

pub fn computeHRV(
    allocator: std.mem.Allocator,
    r_peaks: []usize,
    fs: f64,
) !HRV {

    const rr = try rrIntervals(allocator, r_peaks, fs);
    defer allocator.free(rr);

    return HRV{
        .sdnn = sdnn(rr),
        .rmssd = rmssd(rr),
        .pnn50 = pnn50(rr),
    };
}
