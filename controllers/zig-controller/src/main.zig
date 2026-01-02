const std = @import("std");

const ECG_FS = 250.0;
const PPG_FS = 100.0;

// Intervals in nanoseconds for higher precision
const ECG_INTERVAL_NS = @as(u64, @intFromFloat(std.time.ns_per_s / ECG_FS));
const PPG_INTERVAL_NS = @as(u64, @intFromFloat(std.time.ns_per_s / PPG_FS));

fn generateECG(t: f64) f64 {
    const freq = 1.2; // ~72 bpm
    // Basic simulation: A sine wave (could be replaced with a P-QRS-T model)
    return @sin(2.0 * std.math.pi * freq * t);
}

fn generatePPG(t: f64) f64 {
    const freq = 1.2;
    return (@sin(2.0 * std.math.pi * freq * t) * 0.5) + 0.5;
}

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("time_s,ecg,ppg\n", .{});

    var timer = try std.time.Timer.start();
    const start_time = timer.read();

    var last_ecg_ns: u64 = 0;
    var last_ppg_ns: u64 = 0;

    // Latest known values for synchronized output
    var current_ecg: f64 = 0.0;
    var current_ppg: f64 = 0.0;

    while (true) {
        const now = timer.read() - start_time;

        var updated = false;

        // Check if it's time for an ECG sample
        if (now - last_ecg_ns >= ECG_INTERVAL_NS) {
            const t = @as(f64, @floatFromInt(now)) / std.time.ns_per_s;
            current_ecg = generateECG(t);
            last_ecg_ns += ECG_INTERVAL_NS;
            updated = true;
        }

        // Check if it's time for a PPG sample
        if (now - last_ppg_ns >= PPG_INTERVAL_NS) {
            const t = @as(f64, @floatFromInt(now)) / std.time.ns_per_s;
            current_ppg = generatePPG(t);
            last_ppg_ns += PPG_INTERVAL_NS;
            updated = true;
        }

        // Print only when one of the sensors updates
        if (updated) {
            const timestamp = @as(f64, @floatFromInt(now)) / std.time.ns_per_s;
            try stdout.print("{d:.3},{d:.4},{d:.4}\n", .{ timestamp, current_ecg, current_ppg });

            // Flush periodically or every line for real-time visualization
            try bw.flush();
        }

        // Small sleep to prevent 100% CPU usage
        std.time.sleep(std.time.ns_per_ms);
    }
}
