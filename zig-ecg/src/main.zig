const std = @import("std");
const fft = @import("fft.zig");
const filter = @import("filter.zig");
const rpeak = @import("rpeak.zig");
const hrv = @import("hrv.zig");

pub fn main() !void {
    // Use GPA for everything
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // FFT test
    const fft_signal = try allocator.alloc(std.math.Complex(f64), 8);
    defer allocator.free(fft_signal);

    for (fft_signal, 0..) |*v, i| {
        v.* = .{ .re = @floatFromInt(i), .im = 0.0 };
    }

    fft.fft(fft_signal);

    std.debug.print("FFT Results:\n", .{});
    for (fft_signal) |v| {
        std.debug.print("{d:.3} + {d:.3}i\n", .{ v.re, v.im });
    }

    // Fake ECG-like signal
    const N = 1000;
    const fs = 250.0;

    const signal = try allocator.alloc(f64, N);
    defer allocator.free(signal);

    for (signal, 0..) |*v, i| {
        const t = @as(f64, @floatFromInt(i)) / fs;
        v.* = std.math.sin(2.0 * std.math.pi * 1.0 * t) +
            0.5 * std.math.sin(2.0 * std.math.pi * 50.0 * t);
    }

    const filtered = try filter.filtfilt(
    allocator,
    signal,
    fs,
    0.5,
    40.0,
);
defer allocator.free(filtered);


    std.debug.print("\nFiltered Signal (first 10 samples):\n", .{});
    for (0..10) |i| {
        std.debug.print("{d:.4}\n", .{filtered[i]});
    }

    const r_peaks = try rpeak.rPeakDetect(
    allocator,
    filtered,
    fs,

);
defer allocator.free(r_peaks);

std.debug.print("Detected {d} R-peaks\n", .{r_peaks.len});

const metrics = try hrv.computeHRV(
    allocator,
    r_peaks,
    fs,
);

std.debug.print(
    \\HRV Metrics
    \\SDNN  : {d:.2} ms
    \\RMSSD : {d:.2} ms
    \\pNN50 : {d:.1} %
    \\
, .{
    metrics.sdnn,
    metrics.rmssd,
    metrics.pnn50,
});


}

