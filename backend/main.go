package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var clients = make(map[*websocket.Conn]bool)

func main() {
	//MQTT SETUP
	opts := mqtt.NewClientOptions()
	opts.AddBroker("tcp://broker.hivemq.com:1883")
	opts.SetClientID(fmt.Sprintf("biosense-backend-%d", time.Now().UnixNano()))

	opts.SetDefaultPublishHandler(func(client mqtt.Client, msg mqtt.Message) {
		fmt.Println("📩 MQTT:", msg.Topic())

		for conn := range clients {
			conn.WriteMessage(websocket.TextMessage, msg.Payload())
		}
	})

	mqttClient := mqtt.NewClient(opts)
	if token := mqttClient.Connect(); token.Wait() && token.Error() != nil {
		log.Fatal(token.Error())
	}

	mqttClient.Subscribe("biosense/device/+", 0, nil)
	fmt.Println("✅ Subscribed to MQTT topics")

	// --- WEBSOCKET SERVER ---
	http.HandleFunc("/ws", wsHandler)

	fmt.Println("🚀 WebSocket server running on ws://localhost:8081/ws")
	log.Fatal(http.ListenAndServe(":8081", nil))
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	clients[conn] = true
	fmt.Println("🔌 WebSocket client connected")
}
