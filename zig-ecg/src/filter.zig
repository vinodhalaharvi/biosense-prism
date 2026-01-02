const std = @import("std");

pub fn lowPass(
    allocator: std.mem.Allocator,
    input: []f64,
    fs: f64,
    cutoff: f64,
) ![]f64 {

    var output = try allocator.alloc(f64, input.len);

    const alpha = (2.0 * std.math.pi * cutoff) /
        ((2.0 * std.math.pi * cutoff) + fs);

    output[0] = input[0];

    for (1..input.len) |i| {
        output[i] = output[i - 1] + alpha * (input[i] - output[i - 1]);
    }

    return output;
}

pub fn highPass(
    allocator: std.mem.Allocator,
    input: []f64,
    fs: f64,
    cutoff: f64,
) ![]f64 {

    var output = try allocator.alloc(f64, input.len);

    const alpha = fs / (fs + 2.0 * std.math.pi * cutoff);

    output[0] = input[0];

    for (1..input.len) |i| {
        output[i] = alpha * (output[i - 1] + input[i] - input[i - 1]);
    }

    return output;
}

pub fn bandPass(
    allocator: std.mem.Allocator,
    input: []f64,
    fs: f64,
    low: f64,
    high: f64,
) ![]f64 {

    const hp = try highPass(allocator, input, fs, low);
    defer allocator.free(hp);

    const bp = try lowPass(allocator, hp, fs, high);
    return bp;
}

pub fn reverse(
    allocator: std.mem.Allocator,
    input: []f64,
) ![]f64 {
    var out = try allocator.alloc(f64, input.len);
    const N = input.len;

    for (0..N) |i| {
        out[i] = input[N - 1 - i];
    }
    return out;
}

pub fn iirFilter(
    allocator: std.mem.Allocator,
    input: []f64,
    b: [3]f64,
    a: [3]f64,
) ![]f64 {

    var y = try allocator.alloc(f64, input.len);
    @memset(y, 0.0);

    for (0..input.len) |n| {
        y[n] += b[0] * input[n];

        if (n >= 1) {
            y[n] += b[1] * input[n - 1];
            y[n] -= a[1] * y[n - 1];
        }
        if (n >= 2) {
            y[n] += b[2] * input[n - 2];
            y[n] -= a[2] * y[n - 2];
        }
    }

    return y;
}

pub fn butterworthBandpass(
    fs: f64,
    low: f64,
    high: f64,
) struct { b: [3]f64, a: [3]f64 } {

    const w1 = std.math.tan(std.math.pi * low / fs);
    const w2 = std.math.tan(std.math.pi * high / fs);

    const bw = w2 - w1;
    const w0 = std.math.sqrt(w1 * w2);

    const norm = 1.0 / (1.0 + bw + w0 * w0);

    const b0 = bw * norm;
    const b1 = 0.0;
    const b2 = -bw * norm;

    const a0 = 1.0;
    const a1 = 2.0 * (w0 * w0 - 1.0) * norm;
    const a2 = (1.0 - bw + w0 * w0) * norm;

    return .{
        .b = .{ b0, b1, b2 },
        .a = .{ a0, a1, a2 },
    };
}

pub fn filtfilt(
    allocator: std.mem.Allocator,
    input: []f64,
    fs: f64,
    low: f64,
    high: f64,
) ![]f64 {

    const coeffs = butterworthBandpass(fs, low, high);

    const forward = try iirFilter(
        allocator,
        input,
        coeffs.b,
        coeffs.a,
    );
    defer allocator.free(forward);

    const reversed = try reverse(allocator, forward);
    defer allocator.free(reversed);

    const backward = try iirFilter(
        allocator,
        reversed,
        coeffs.b,
        coeffs.a,
    );
    defer allocator.free(backward);

    const output = try reverse(allocator, backward);
    return output;
}
