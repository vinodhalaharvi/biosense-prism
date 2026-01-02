const std = @import("std");

const ECG_FS: f64 = 250.0;
const HEART_RATE: f64 = 72.0;
const TWO_PI: f64 = 6.283185307179586;

pub fn main() void {
    std.debug.print("time,ecg\n", .{});

    var t: f64 = 0.0;
    const dt: f64 = 1.0 / ECG_FS;

    var last_time: i128 = std.time.nanoTimestamp();

    while (true) {
        // wait ~4 ms (250 Hz) using busy wait
        while (true) {
            const now: i128 = std.time.nanoTimestamp();
            if (now - last_time >= 4_000_000) {
                last_time = now;
                break;
            }
        }

        const base: f64 =
            @as(f64, 0.3) *
            std.math.sin(TWO_PI * (HEART_RATE / @as(f64, 60.0)) * t);

        const beats: f64 = t * HEART_RATE / @as(f64, 60.0);
        const phase: f64 = beats - std.math.floor(beats);

        const r_peak: f64 =
            if (phase < @as(f64, 0.02))
                @as(f64, 1.2)
            else
                @as(f64, 0.0);

        const ecg: f64 = base + r_peak;

        std.debug.print("{d:.3},{d:.4}\n", .{ t, ecg });

        t += dt;
    }
}
