export function sma(buffer, windowLen) {
  if (!buffer.length) return 0;
  const start = Math.max(0, buffer.length - windowLen);
  const slice = buffer.slice(start);
  const sum = slice.reduce((a,b)=>a+b,0);
  return sum / slice.length;
}

export function detectPeaks(buffer, threshold=0.6, sr=250, refractoryMs=250) {
  const peaks = [];
  let lastPeak = -Infinity;
  const refractorySamples = Math.floor((refractoryMs/1000)*sr);
  for (let i=0;i<buffer.length;i++){
    if (buffer[i] > threshold && (i - lastPeak) > refractorySamples) {
      peaks.push({index:i, value: buffer[i]});
      lastPeak = i;
    }
  }
  return peaks;
}

