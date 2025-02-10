#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <esp_task_wdt.h>

// ✅ Configuration Constants
#define DEVICE_NAME "SmartPotty-ESP32"
#define SERVICE_UUID "abcd1234-5678-1234-5678-abcdef123456"
#define CHARACTERISTIC_UUID "abcd5678-1234-5678-1234-abcdef987654"
#define LED_PIN 15  // LED Indicator
#define WIFI_SSID "New Variant"
#define WIFI_PASSWORD "LebronJames"
#define TTLOCK_API_URL "http://api.ttlock.com/v3/lock/unlock"

// ✅ TTLock API Credentials
const char TTLOCK_CLIENT_ID[] PROGMEM = "YOUR_CLIENT_ID";
const char TTLOCK_ACCESS_TOKEN[] PROGMEM = "YOUR_ACCESS_TOKEN";
const int TTLOCK_LOCK_ID = 1234567;  // Replace with actual TTLock ID

// ✅ BLE Variables
BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;
BLEAdvertising *pAdvertising = nullptr;
bool deviceConnected = false;
unsigned long unlockStartTime = 0;
bool isUnlocking = false;

// ✅ WiFi Connection Function
void connectToWiFi() {
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("🌐 Connecting to WiFi");
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 15) {
        delay(1000);
        Serial.print(".");
        attempts++;
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("✅ WiFi Connected!");
    } else {
        Serial.println("❌ WiFi Connection Failed!");
    }
}

// ✅ BLE Server Callbacks (Keep Advertising)
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) override {
        Serial.println("✅ Device Connected!");
        deviceConnected = true;
    }

    void onDisconnect(BLEServer* pServer) override {
        Serial.println("❌ Device Disconnected! Restarting Advertising...");
        deviceConnected = false;
        pAdvertising->start(); // Restart advertising
    }
};

// ✅ Function to Send Unlock Command to TTLock API
void sendUnlockRequestToTTLock() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("🚫 WiFi not connected! Cannot send unlock request.");
        return;
    }

    HTTPClient http;
    http.begin(TTLOCK_API_URL);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");

    // ✅ Construct POST Data
    String postData = "client_id=" + String(TTLOCK_CLIENT_ID) +
                      "&access_token=" + String(TTLOCK_ACCESS_TOKEN) +
                      "&lockId=" + String(TTLOCK_LOCK_ID);

    Serial.println("📡 Sending Unlock Request to TTLock...");
    int httpResponseCode = http.POST(postData);

    if (httpResponseCode > 0) {
        Serial.println("✅ TTLock Unlock Success! Response: " + http.getString());
    } else {
        Serial.println("❌ TTLock Unlock Failed! HTTP Code: " + String(httpResponseCode));
    }

    http.end();
}

// ✅ BLE Characteristic Callbacks
class UnlockCallback : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) override {
        std::string value = std::string(pCharacteristic->getValue().c_str()); // Safe conversion

        if (value == "unlock") {
            Serial.println("🔑 Unlock command received!");
            digitalWrite(LED_PIN, HIGH);
            unlockStartTime = millis(); // Start timer for unlocking
            isUnlocking = true;
            Serial.println("🚪 Unlock process started...");

            // ✅ Send Unlock Request to TTLock API
            sendUnlockRequestToTTLock();
        } else {
            Serial.println("❌ Invalid command received!");
        }
    }
};

void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);

    delay(1000); // Startup delay

    Serial.println("🚀 Initializing BLE...");
    
    // ✅ Connect to WiFi
    connectToWiFi();

    // ✅ Initialize BLE
    BLEDevice::init(DEVICE_NAME);
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    // ✅ Create Service and Characteristic
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    pCharacteristic->setCallbacks(new UnlockCallback());
    pService->start();

    // ✅ Start BLE Advertising
    pAdvertising = pServer->getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(false);
    pAdvertising->start();
    BLEDevice::startAdvertising();

    Serial.println("📡 ESP32 BLE is Advertising & Ready for Connection!");

    // ✅ Watchdog Timer Setup (Corrected)
    esp_task_wdt_config_t wdtConfig = {
        .timeout_ms = 10000,  // 10 seconds timeout
        .idle_core_mask = (1 << 0) | (1 << 1),  // Apply to both cores
        .trigger_panic = true
    };
    esp_task_wdt_init(&wdtConfig);
    esp_task_wdt_add(NULL);

    Serial.println("🛡️ Watchdog Timer Initialized!");
}

void loop() {
    // ✅ Reset Watchdog Timer
    if (esp_task_wdt_status(NULL) == ESP_OK) {
        esp_task_wdt_reset();
    } else {
        Serial.println("⚠️ Watchdog task not found! Skipping reset.");
    }

    // ✅ Handle Unlock Timing
    if (isUnlocking && (millis() - unlockStartTime >= 2000)) { // 2 seconds
        digitalWrite(LED_PIN, LOW); // Turn off LED
        isUnlocking = false;
        Serial.println("🚪 Door unlocked successfully!");
    }

    // ✅ Debugging delay
    delay(100);
}
