/*
 * ESP32 Bridge for DDS Fire Alarm Monitoring System - ULTIMATE FIX
 * 
 * Simple bridge that receives data from Serial2 (RXD2/TXD2)
 * and sends raw data to Firebase
 * 
 * WiFi: Wifiii
 * Password: tes12345
 * Firebase: testing1do-default-rtdb.asia-southeast1.firebasedatabase.app
 * 
 * ULTIMATE FIX: Timestamp robust dengan multiple fallback methods
 */

#include <WiFi.h>
#include <FirebaseESP32.h>
#include <ArduinoJson.h>
#include <time.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

// Serial2 Configuration
#define RXD2 16
#define TXD2 17

// Control codes
#define STX 0x02
#define ETX 0x03

// WiFi Configuration
#define WIFI_SSID "Wifiii"
#define WIFI_PASSWORD "tes12345"

// Firebase Configuration
#define FIREBASE_HOST "testing1do-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC"

// Firebase Objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// NTP Client
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0, 60000);

// Variables
String receivedPacket = "";
bool packetInProgress = false;
String lastSentPacket = "";
String lastFirebaseValue = "";
unsigned long previousFirebaseCheckMillis = 0;
const long firebaseCheckInterval = 2000;
unsigned long previousStatusMillis = 0;
const long statusInterval = 3000;

// NTP Configuration
const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 0; // UTC time
const int daylightOffset_sec = 0;

// Global timestamp variables
unsigned long lastKnownGoodTimestamp = 0;
unsigned long timestampUpdateCounter = 0;

void sendToFirebase(String packetData);
void sendStatusToFirebase(); // ULTIMATE FIX VERSION
void readFromFirebaseAndSendToSerial2();
unsigned long getCurrentUnixTimestamp(); // NEW FUNCTION

void setup() {
  Serial.begin(38400);
  Serial2.begin(38400, SERIAL_8N1, RXD2, TXD2);

  Serial.println("=== ESP32 Bridge Starting (ULTIMATE FIX VERSION) ===");
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
    
    // Initialize Firebase
    config.host = FIREBASE_HOST;
    config.signer.tokens.legacy_token = FIREBASE_AUTH;
    
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
    
    // Initialize configTime
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    Serial.print("Synchronizing time with NTP server");
    struct tm timeinfo;
    int timeAttempts = 0;
    while (!getLocalTime(&timeinfo) && timeAttempts < 10) {
      Serial.print(".");
      delay(1000);
      timeAttempts++;
    }
    
    if (getLocalTime(&timeinfo)) {
      Serial.println("\n✓ Time synchronized via configTime!");
      time_t now = time(nullptr);
      lastKnownGoodTimestamp = (unsigned long)now * 1000;
      Serial.print("Initial timestamp: ");
      Serial.println(lastKnownGoodTimestamp);
    } else {
      Serial.println("\n⚠ Failed to sync time, will use fallback");
      // Set a reasonable fallback timestamp (October 2025)
      lastKnownGoodTimestamp = 1728938498000UL;
    }
    
    // Initialize NTP Client
    timeClient.begin();
    timeClient.setTimeOffset(0);
    
    // Test NTP Client
    Serial.print("Testing NTP Client...");
    timeClient.update();
    if (timeClient.isTimeSet()) {
      Serial.println("✓ NTP Client working!");
      Serial.print("NTP Epoch: ");
      Serial.println(timeClient.getEpochTime());
    } else {
      Serial.println("⚠ NTP Client not working, will use fallback");
    }
    
    Serial.println("✓ Firebase initialized!");
    Serial.println("✓ Bridge ready!");
    Serial.println("🔥 ULTIMATE FIX: Multiple timestamp fallback methods active");
    
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

    if (!packetInProgress && data == STX) {
      receivedPacket = "";
      packetInProgress = true;
      Serial.print("<STX>");
    }
    else if (packetInProgress && data == ETX) {
      Serial.print("<ETX>");
      Serial.println();
      Serial.print("Packet received: ");
      Serial.println(receivedPacket);
      
      if (receivedPacket != lastSentPacket) {
        Serial.println("Packet has changed. Sending to Firebase...");
        sendToFirebase(receivedPacket);
        lastSentPacket = receivedPacket;
      } else {
        Serial.println("Packet has not changed. Not sending to Firebase.");
      }
      
      receivedPacket = "";
      packetInProgress = false;
    }
    else if (packetInProgress) {
      receivedPacket += (char)data;
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
  
  // === Check for new data from Firebase and send to Serial2 ===
  unsigned long currentMillis = millis();
  if (currentMillis - previousFirebaseCheckMillis >= firebaseCheckInterval) {
    previousFirebaseCheckMillis = currentMillis;
    readFromFirebaseAndSendToSerial2();
  }
  
  // === Send status to Firebase every 3 seconds ===
  if (currentMillis - previousStatusMillis >= statusInterval) {
    previousStatusMillis = currentMillis;
    sendStatusToFirebase(); // ULTIMATE FIX VERSION
  }
  
  delay(1);
}

// 🔥 NEW FUNCTION: Robust timestamp getter with multiple fallbacks
unsigned long getCurrentUnixTimestamp() {
  timestampUpdateCounter++;
  
  // Method 1: Try NTP Client first (most accurate)
  timeClient.update();
  if (timeClient.isTimeSet()) {
    unsigned long ntpTimestamp = timeClient.getEpochTime() * 1000;
    
    // Validate timestamp is reasonable (between 2020 and 2030)
    if (ntpTimestamp > 1577836800000UL && ntpTimestamp < 1893456000000UL) {
      lastKnownGoodTimestamp = ntpTimestamp;
      Serial.print("📍 Using NTP timestamp: ");
      Serial.println(ntpTimestamp);
      return ntpTimestamp;
    }
  }
  
  // Method 2: Try system time
  time_t now = time(nullptr);
  if (now > 1577836800UL) { // After 2020
    unsigned long systemTimestamp = (unsigned long)now * 1000;
    lastKnownGoodTimestamp = systemTimestamp;
    Serial.print("📍 Using system timestamp: ");
    Serial.println(systemTimestamp);
    return systemTimestamp;
  }
  
  // Method 3: Use last known good timestamp + elapsed time
  if (lastKnownGoodTimestamp > 0) {
    unsigned long elapsedMillis = millis();
    unsigned long calculatedTimestamp = lastKnownGoodTimestamp + elapsedMillis;
    Serial.print("📍 Using calculated timestamp: ");
    Serial.println(calculatedTimestamp);
    return calculatedTimestamp;
  }
  
  // Method 4: Hardcoded fallback (October 2025)
  unsigned long fallbackTimestamp = 1728938498000UL;
  Serial.print("📍 Using fallback timestamp: ");
  Serial.println(fallbackTimestamp);
  return fallbackTimestamp;
}

void sendToFirebase(String packetData) {
  if (packetData.length() == 0) return;
  
  // Get robust timestamp
  unsigned long unixTimestamp = getCurrentUnixTimestamp();
  
  // Create JSON data
  FirebaseJson json;
  json.set("device_id", "ESP32_Bridge_001");
  json.set("status", "connected");
  json.set("wifi_signal", WiFi.RSSI());
  json.set("parsed_packet", packetData);
  json.set("timestamp", String(unixTimestamp));
  json.set("method", timestampUpdateCounter > 0 ? "robust" : "initial");
  
  // Send to Firebase
  String path = "/esp32_bridge/data";
  
  if (Firebase.setJSON(fbdo, path, json)) {
    Serial.println("✓ Parsed packet sent to Firebase!");
  } else {
    Serial.print("✗ Firebase error: ");
    Serial.println(fbdo.errorReason());
  }
}

// 🔥 ULTIMATE FIX VERSION: Robust status sending
void sendStatusToFirebase() {
  // Get robust timestamp
  unsigned long unixTimestamp = getCurrentUnixTimestamp();
  
  // 🔥 CRITICAL FIX: Kirim timestamp langsung ke path yang Flutter baca
  String timestampPath = "/esp32_bridge/status/timestamp";
  if (Firebase.setString(fbdo, timestampPath, String(unixTimestamp))) {
    Serial.println("✅ Timestamp sent to esp32_bridge/status/timestamp");
    Serial.print("🎯 Timestamp value: ");
    Serial.println(unixTimestamp);
    
    // Convert to readable date for debugging
    time_t timestamp_sec = unixTimestamp / 1000;
    struct tm* tm_info = gmtime(&timestamp_sec);
    char date_str[50];
    strftime(date_str, sizeof(date_str), "%Y-%m-%d %H:%M:%S UTC", tm_info);
    Serial.print("📅 Timestamp date: ");
    Serial.println(date_str);
    
  } else {
    Serial.print("❌ Failed to send timestamp: ");
    Serial.println(fbdo.errorReason());
  }
  
  // Also send full status for debugging
  FirebaseJson json;
  json.set("device_id", "ESP32_Bridge_001");
  json.set("status", "connected");
  json.set("wifi_signal", WiFi.RSSI());
  json.set("timestamp", String(unixTimestamp));
  json.set("counter", String(timestampUpdateCounter));
  json.set("method", "ultimate_fix");
  
  String statusPath = "/esp32_bridge/status/full";
  if (Firebase.setJSON(fbdo, statusPath, json)) {
    Serial.println("✓ Full status sent to esp32_bridge/status/full");
  }
  
  Serial.println("🔥 ULTIMATE FIX ACTIVE - Multiple timestamp methods");
}

void readFromFirebaseAndSendToSerial2() {
  String path = "/esp32_bridge/user_input/data";
  
  if (Firebase.getJSON(fbdo, path)) {
    FirebaseJson* json = fbdo.jsonObjectPtr();
    
    if (json != nullptr) {
      String dataValue = "";
      
      // Read the DATA_UNTUK_ESP field
      if (json->get("DATA_UNTUK_ESP")) {
        dataValue = json->value();
      }
      
      if (dataValue != "" && dataValue != lastFirebaseValue) {
        Serial.print("New data from Firebase (");
        Serial.print(path);
        Serial.print(") [DATA_UNTUK_ESP]: ");
        Serial.println(dataValue);
        
        Serial.print("Sending to Serial2: ");
        Serial.println(dataValue);
        
        Serial2.print(dataValue);
        
        lastFirebaseValue = dataValue;
        
        Serial.println("Clearing DATA_UNTUK_ESP field from Firebase...");
        // Clear only the DATA_UNTUK_ESP field
        FirebaseJson clearJson;
        clearJson.set("DATA_UNTUK_ESP", "");
        
        if (Firebase.setJSON(fbdo, path, clearJson)) {
          Serial.println("✓ DATA_UNTUK_ESP field cleared from Firebase.");
          lastFirebaseValue = ""; 
        } else {
          Serial.print("✗ Firebase error clearing DATA_UNTUK_ESP field: ");
          Serial.println(fbdo.errorReason());
        }
      }
    }
  }
}
