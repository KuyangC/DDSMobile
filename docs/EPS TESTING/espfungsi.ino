/*
LEBIH SUKSES LAGI ESP TO FIREBASE DARI MASTER

 * ESP32 Bridge for DDS Fire Alarm Monitoring System
 * 
 * Simple bridge that receives data from Serial2 (RXD2/TXD2)
 * and sends raw data to Firebase
 * 
 * WiFi: Wifiii
 * Password: tes12345
 * Firebase: testing1do-default-rtdb.asia-southeast1.firebasedatabase.app
 */

#include <WiFi.h>
#include <FirebaseESP32.h>  // Gunakan library yang benar
#include <ArduinoJson.h>    // Library ini akan otomatis terinstall dengan Firebase

// Serial2 Configuration
#define RXD2 16
#define TXD2 17

// Control codes
#define STX 0x02
#define ETX 0x03

// WiFi Configuration
#define WIFI_SSID "Elektro ITI20"
#define WIFI_PASSWORD "iti elektro"

// Firebase Configuration - GUNAKAN DATABASE SECRET, BUKAN PRIVATE KEY
#define FIREBASE_HOST "testing1do-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "rcy10oVwCVIhWRdTVk8ZBT7bLAUHZE7fPHKKOKpK" // Ganti dengan Database Secret dari Firebase Console

// Firebase Objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Variables
String receivedPacket = "";
String masterStatus = "";
bool packetInProgress = false;
String lastSentPacket = ""; // To store the last packet sent to Firebase


void sendToFirebase(String packetData);

void setup() {
  Serial.begin(38400);
  Serial2.begin(38400, SERIAL_8N1, RXD2, TXD2);

  Serial.println("=== ESP32 Bridge Starting ===");
  Serial.println("DDS Fire Alarm Monitoring System");
  
  // Initialize WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    
    // Initialize Firebase dengan konfigurasi yang benar
    config.host = FIREBASE_HOST;
    config.signer.tokens.legacy_token = FIREBASE_AUTH;
    
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
    
    Serial.println("✓ Firebase initialized!");
    Serial.println("✓ Bridge ready!");
  } else {
    Serial.println("\n✗ WiFi connection failed!");
  }
}

void loop() {
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected! Reconnecting...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    delay(2000);
    return;
  }
  
  // === Receive and parse data from Serial2 ===
  while (Serial2.available() > 0) {
    byte data = Serial2.read();
    
    // Debug: Print raw byte data
    Serial.print("[");
    Serial.print(data, HEX);
    Serial.print("]");
    
    // Debug: Print character representation
    if (data >= 32 && data <= 126) { // Printable characters
      Serial.print("(");
      Serial.print((char)data);
      Serial.print(")");
    } else if (data == STX) {
      Serial.print("(STX)");
    } else if (data == ETX) {
      Serial.print("(ETX)");
    } else {
      Serial.print("(NON-PRINT)");
    }

    if (!packetInProgress && data == STX) {
      // Start of a new packet, the data collected so far is the master status.
      receivedPacket = ""; // Clear slave data buffer
      packetInProgress = true;
      Serial.println("\n=== SLAVE PACKET START ===");
    }
    else if (packetInProgress && data == ETX) {
      // End of the packet. Combine master and slave data.
      Serial.println("\n=== PACKET END ===");
      
      // Combine master status and the received slave packet
      String fullPacket = masterStatus;
      fullPacket.concat(receivedPacket);
      fullPacket.trim();

      Serial.print("Complete packet received (Master+Slave): [");
      Serial.print(fullPacket);
      Serial.println("]");
      Serial.print("Packet length: ");
      Serial.println(fullPacket.length());
      
      // Check if the packet has changed before sending
      if (fullPacket != lastSentPacket) {
        Serial.println("Packet has changed. Sending to Firebase...");
        sendToFirebase(fullPacket); // Send the combined packet
        lastSentPacket = fullPacket; // Update the last sent packet
      } else {
        Serial.println("Packet has not changed. Not sending to Firebase.");
      }
      
      // Reset for the next full transmission
      receivedPacket = "";
      masterStatus = ""; // IMPORTANT: Clear master status after sending
      packetInProgress = false;
      Serial.println("=== READY FOR NEXT PACKET ===\n");
    }
    else if (packetInProgress) {
      // We are inside a slave packet, append data to it.
      receivedPacket += (char)data;
    }
    else {
      // We are not in a slave packet, so append to master status buffer.
      masterStatus += (char)data;
      Serial.print(" (CAPTURED AS MASTER STATUS)");
    }
  }
  
  // === Send data from Serial Monitor to TXD2 ===
  if (Serial.available() > 0) {
    String input = Serial.readString();
    input.trim();
    
    if (input.length() > 0) {
      Serial.print("Sending to TXD2: ");
      Serial.println(input);
      
      for (int i = 0; i < input.length(); i++) {
        Serial2.write(input[i]);
        delay(2);
      }
    }
  }
  
  // The old interval-based sending logic is removed.
  // Data is now sent immediately upon receiving an ETX character.
  
  delay(1);
}

void sendToFirebase(String packetData) {
  if (packetData.length() == 0) return;
  
  // Create JSON data - STRUCTURE TETAP SAMA SEPERTI SEMULA
  FirebaseJson json;
  json.set("device_id", "ESP32_Bridge_001");
  json.set("status", "online");
  json.set("wifi_signal", WiFi.RSSI());
  json.set("parsed_packet", packetData); // Field asli tetap dipertahankan
  json.set("timestamp", millis());
  
  // Send to Firebase - PATH TIDAK DIUBAH
  String path = "/esp32_bridge/data";
  
  if (Firebase.setJSON(fbdo, path, json)) {
    Serial.println("✓ Data sent to Firebase!");
  } else {
    Serial.print("✗ Firebase error: ");
    Serial.println(fbdo.errorReason());
  }
}
