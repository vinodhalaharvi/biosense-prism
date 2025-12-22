//websocket-client.js
const WS_URL = "ws://localhost:8081"; //WebSocket server
const ws = new WebSocket(WS_URL);

ws.onopen = () => console.log("Connected to WebSocket server");

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  updateUI(data);
};

ws.onerror = (err) => console.error("WebSocket error:", err);

function updateUI(msg) {

  if (!msg.sensors) return;

  if (msg.sensors.ecg) addToBuffer('ecg', msg.sensors.ecg.value);
  if (msg.sensors.ppg) addToBuffer('ppg', msg.sensors.ppg.value);

  if (msg.sensors.spo2) document.getElementById("spo2").innerText = msg.sensors.spo2.value.toFixed(1) + "%";
  if (msg.sensors.temp) document.getElementById("temp").innerText = msg.sensors.temp.value.toFixed(1) + "°C";

  if (window.ecgBuffer && window.ecgBuffer.length > 100) {
    const peaks = detectPeaks(window.ecgBuffer, 0.5, 250);
    if (peaks.length > 1) {
      const rr_intervals = [];
      for (let i = 1; i < peaks.length; i++) {
        rr_intervals.push((peaks[i].index - peaks[i-1].index)/250); // seconds
      }
      const hr = 60 / (rr_intervals.reduce((a,b)=>a+b,0)/rr_intervals.length);
      document.getElementById("hr").innerText = Math.round(hr);
    }
  }
}
