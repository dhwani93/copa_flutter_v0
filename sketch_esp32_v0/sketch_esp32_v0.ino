#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <esp_task_wdt.h>

#define DEVICE_NAME "SmartPotty-ESP32"
#define SERVICE_UUID "abcd1234-5678-1234-5678-abcdef123456"
#define CHARACTERISTIC_UUID "abcd5678-1234-5678-1234-abcdef987654"
#define LED_PIN 15 // LED to indicate unlock

BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;
BLEAdvertising *pAdvertising = nullptr;
bool deviceConnected = false;
unsigned long unlockStartTime = 0;
bool isUnlocking = false;

// ✅ BLE Server Callbacks (To Keep Advertising)
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer *pServer) {
        Serial.println("✅ Device Connected!");
        deviceConnected = true;
    }

    void onDisconnect(BLEServer *pServer) {
        Serial.println("❌ Device Disconnected! Restarting Advertising...");
        deviceConnected = false;
        pAdvertising->start(); // Restart advertising after disconnection
    }
};

// ✅ BLE Characteristic Callbacks
class UnlockCallback : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        std::string value = std::string(pCharacteristic->getValue().c_str()); // Safe conversion

        if (value == "unlock") {
            Serial.println("🔑 Unlock command received!");
            digitalWrite(LED_PIN, HIGH);
            unlockStartTime = millis(); // Start timer for unlocking
            isUnlocking = true;
            Serial.println("🚪 Unlock process started...");
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

    // Initialize BLE
    BLEDevice::init(DEVICE_NAME);
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    // Create Service and Characteristic
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ
    );
    pCharacteristic->setCallbacks(new UnlockCallback());
    pService->start();

    // Start Advertising
    pAdvertising = pServer->getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->start();
    BLEDevice::startAdvertising();

    Serial.println("📡 ESP32 BLE is Advertising & Ready for Connection!");

    // Watchdog Timer Setup
    esp_task_wdt_config_t wdtConfig = {
        .timeout_ms = 10000, // 10 seconds timeout
        .idle_core_mask = (1 << 0) | (1 << 1),
        .trigger_panic = true
    };
    esp_task_wdt_init(&wdtConfig);
    esp_task_wdt_add(nullptr);

    Serial.println("🛡️ Watchdog Timer Initialized!");
}

void loop() {
    // Reset the watchdog timer
    if (esp_task_wdt_status(nullptr) == ESP_OK) {
        esp_task_wdt_reset();
    } else {
        Serial.println("⚠️ Watchdog task not found! Skipping reset.");
    }

    // Handle Unlock Timing
    if (isUnlocking && (millis() - unlockStartTime >= 2000)) { // 2 seconds
        digitalWrite(LED_PIN, LOW); // Turn off LED
        isUnlocking = false;
        Serial.println("🚪 Door unlocked successfully!");
    }

    // Debugging delay
    delay(100);
}