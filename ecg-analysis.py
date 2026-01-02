#signal processing
import wfdb
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt, find_peaks
import neurokit2 as nk
from scipy.fft import fft, fftfreq

#bpf
def bandpass(sig, fs, low=0.5, high=40):
    """Bandpass filter for ECG"""
    nyq = 0.5 * fs
    b, a = butter(2, [low/nyq, high/nyq], btype='band')
    return filtfilt(b, a, sig)
#respiratory filter
def respiratory_filter(sig, fs, low=0.1, high=0.5):
    """Bandpass filter for respiratory signal"""
    nyq = 0.5 * fs
    b, a = butter(2, [low/nyq, high/nyq], btype='band')
    return filtfilt(b, a, sig)


record = wfdb.rdrecord('data/100', channels=[0])
signal = record.p_signal.flatten()
fs = record.fs
N = len(signal)

#filter ecg
filtered = bandpass(signal, fs)

#ecg raw vs filtered
plt.figure(figsize=(12,4))
plt.plot(signal[:1000], label='Raw ECG')
plt.plot(filtered[:1000], label='Filtered ECG')
plt.legend()
plt.title("Raw vs Filtered ECG")
plt.show()

#r-peak detection
signals, info = nk.ecg_process(filtered, sampling_rate=fs)
r_peaks = info["ECG_R_Peaks"]

# 2000 sanples for plotting
r_peaks_short = r_peaks[r_peaks < 2000]

plt.figure(figsize=(12,4))
plt.plot(filtered[:2000], label="Filtered ECG")
plt.scatter(r_peaks_short, filtered[r_peaks_short], color="red", label="R-peaks")
plt.legend()
plt.title("ECG R-Peak Detection")
plt.show()

#hrv
hrv = nk.hrv_time(r_peaks, sampling_rate=fs)

print("\nHRV Metrics:")
print("SDNN   :", hrv["HRV_SDNN"].values[0])
print("RMSSD  :", hrv["HRV_RMSSD"].values[0])
print("pNN50  :", hrv["HRV_pNN50"].values[0])

#fft
yf = fft(filtered)
xf = fftfreq(N, 1 / fs)

plt.figure(figsize=(12,4))
plt.plot(xf[:N//2], np.abs(yf[:N//2]))
plt.title("ECG Frequency Spectrum")
plt.xlabel("Frequency (Hz)")
plt.ylabel("Magnitude")
plt.xlim(0, 60)
plt.show()

#respiratory rate estimation (according to chatgpt)
resp_signal = respiratory_filter(signal, fs)
resp_peaks, _ = find_peaks(resp_signal, distance=fs*1.2)  # 1.2s between breaths
resp_rate = len(resp_peaks) * (60 / (len(signal)/fs))  # breaths per minute

# for 2000 samples
resp_peaks_short = resp_peaks[resp_peaks < 2000]

plt.figure(figsize=(12,4))
plt.plot(resp_signal[:2000], label='Resp Signal')
plt.scatter(resp_peaks_short, resp_signal[resp_peaks_short], color='red', label='Breaths')
plt.legend()
plt.title(f"Respiratory Rate Estimation ~ {resp_rate:.1f} BPM")
plt.show()
