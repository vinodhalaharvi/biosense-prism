const mqtt = require('mqtt');
const WebSocket = require('ws');
const fs = require('fs');

const MQTT_BROKER = 'mqtt://localhost:1883';
const MQTT_TOPIC = 'biosense/device/+';
const WS_PORT = 8081;

const mqttClient = mqtt.connect(MQTT_BROKER);
const wss = new WebSocket.Server({ port: WS_PORT });

mqttClient.on('connect', () => {
  console.log('Connected to MQTT broker');
  mqttClient.subscribe(MQTT_TOPIC, (err) => {
    if (err) console.error('Failed to subscribe', err);
    else console.log('Subscribed to', MQTT_TOPIC);
  });
});

mqttClient.on('message', (topic, payload) => {
  const msg = payload.toString();
  wss.clients.forEach(ws => {
    if (ws.readyState === WebSocket.OPEN) ws.send(msg);
  });
  fs.appendFile('./data.log', msg + '\n', (err) => {
    if (err) console.error('Failed to write data.log', err);
  });
});

wss.on('connection', (ws) => {
  console.log('WebSocket client connected');
  ws.send(JSON.stringify({type:'server', message:'connected to forwarder'}));
});

console.log('WebSocket server listening on ws://localhost:' + WS_PORT);

