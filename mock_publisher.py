import time, json, math, random
import paho.mqtt.client as mqtt

BROKER="localhost"
TOPIC="biosense/device/esp32-001"

client = mqtt.Client()
client.connect(BROKER, 1883, 60)

def gen_ecg_sample(t):
    base = 0.02*math.sin(2*math.pi*0.2*t)
    beat = 1.0 * math.exp(-((t % 1.0)-0.12)**2/0.0009)
    noise = 0.02*random.uniform(-1,1)
    return base + beat + noise

def gen_ppg_sample(t):
    return 40000 + 2000*math.sin(2*math.pi*1.0*t) + 500*random.uniform(-1,1)

t0 = time.time()
ecg_rate = 250.0
ppg_rate = 100.0

ecg_next = t0
ppg_next = t0

while True:
    now = time.time()
    if now >= ecg_next:
        t = now - t0
        val = gen_ecg_sample(t)
        msg = {
            "deviceId":"esp32-001",
            "timestamp": int(now*1000),
            "sensors": {
                "ecg": {"value": val, "unit":"mV", "sampleRate": int(ecg_rate)}
            }
        }
        client.publish(TOPIC, json.dumps(msg))
        ecg_next += 1.0/ecg_rate

    if now >= ppg_next:
        t = now - t0
        val = gen_ppg_sample(t)
        msg = {
            "deviceId":"esp32-001",
            "timestamp": int(now*1000),
            "sensors": {
                "ppg": {"value": int(val), "unit":"raw", "sampleRate": int(ppg_rate)},
                "spo2": {"value": round(97 + random.uniform(-1.5,1.5),1), "unit":"%"},
                "temp": {"value": round(36.6 + random.uniform(-0.25,0.25),2), "unit":"C"}
            }
        }
        client.publish(TOPIC, json.dumps(msg))
        ppg_next += 1.0/ppg_rate

    time.sleep(0.0008)

