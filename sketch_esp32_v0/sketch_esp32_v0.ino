#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <esp_task_wdt.h>
#include <WiFiClientSecure.h>
#include <time.h>
#include <sys/time.h>

// ✅ Configuration Constants
#define DEVICE_NAME "SmartPotty-ESP32"
#define SERVICE_UUID "abcd1234-5678-1234-5678-abcdef123456"
#define CHARACTERISTIC_UUID "abcd5678-1234-5678-1234-abcdef987654"
#define LOCK_LED_PIN 15
#define REED_DOOR_LED_PIN 27
#define REED_OCCUPANCY_LED_PIN 16
#define REED_OCCUPANCY_SWITCH_PIN_INPUT 17
#define WIFI_SSID "New Variant"
#define WIFI_PASSWORD "LebronJames"
#define TTLOCK_API_URL "http://euapi.ttlock.com/v3/lock/unlock"

// ✅ TTLock API Credentials
const char CID[] PROGMEM = "7485f19f1da341c8bff11a5f913457a2";
const char ATOKEN[] PROGMEM = "c94900daa6a63589ff7a91bbe9146e7b";
const char LID[] PROGMEM = "20566298";

// ✅ BLE Variables
BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;
BLEAdvertising *pAdvertising = nullptr;
bool deviceConnected = false;
unsigned long unlockStartTime = 0;
bool isUnlocking = false;

// ✅ WiFi Connection Function
void connectToWiFi() {
    Serial.println(F("🌐 Connecting to WiFi..."));
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    for (int i = 0; i < 15 && WiFi.status() != WL_CONNECTED; i++) {
        delay(500);
    }
    Serial.println(WiFi.status() == WL_CONNECTED ? F("✅ WiFi Connected!") : F("❌ WiFi Connection Failed!"));
}

// ✅ Initialize NTP Time Sync
void setupTime() {
    Serial.println(F("⏳ Setting up NTP Time Sync..."));
    configTime(0, 0, "pool.ntp.org", "time.nist.gov");
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        Serial.println(F("❌ Failed to sync time! Retrying..."));
        delay(2000);
        if (!getLocalTime(&timeinfo)) {
            Serial.println(F("🚫 Time sync failed twice! Check WiFi."));
            return;
        }
    }
    Serial.println(F("✅ Time Synced Successfully!"));
    Serial.print(F("🕒 UTC Time: "));
    Serial.println(asctime(&timeinfo));
}

// ✅ Get UTC Milliseconds
uint64_t getCurrentUTCMillis() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return ((uint64_t)tv.tv_sec * 1000UL) + (tv.tv_usec / 1000UL);
}

// ✅ BLE Callbacks
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer*) override { deviceConnected = true; }
    void onDisconnect(BLEServer*) override { deviceConnected = false; pAdvertising->start(); }
};

// ✅ Send Unlock Command
void sendUnlock() {
    Serial.println(F("📡 Sending Unlock Request to TTLock API..."));
    if (WiFi.status() != WL_CONNECTED) return;
    WiFiClient client;
    HTTPClient http;
    http.begin(client, TTLOCK_API_URL);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");
    char postData[200];
    sprintf(postData, "clientId=%s&accessToken=%s&lockId=%s&date=%llu", CID, ATOKEN, LID, getCurrentUTCMillis());
    Serial.print(F("🔍 POST Data: "));
    Serial.println(postData);
    int httpResponseCode = http.POST(postData);
    Serial.print(F("✅ HTTP Response Code: "));
    Serial.println(httpResponseCode);
    Serial.println(F("📡 Unlock request completed."));
    http.end();
}

// ✅ BLE Characteristic Callbacks
class UnlockCallback : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) override {
        std::string value = std::string(pCharacteristic->getValue().c_str());
        int occupancyState = digitalRead(REED_OCCUPANCY_SWITCH_PIN_INPUT);

        if (value == "unlock") {
            if (occupancyState == HIGH) {
                pCharacteristic->setValue("Error: COPA is currently in use.");
            } else {
                digitalWrite(LOCK_LED_PIN, HIGH);
                unlockStartTime = millis();
                isUnlocking = true;
                sendUnlock();
                pCharacteristic->setValue("Success: Unlock command received");
            }
        } else {
            pCharacteristic->setValue("Error: Invalid command");
        }
        pCharacteristic->notify();
    }
};

void setup() {
    Serial.begin(115200);
    pinMode(LOCK_LED_PIN, OUTPUT);
    digitalWrite(LOCK_LED_PIN, LOW);
    pinMode(REED_OCCUPANCY_LED_PIN, OUTPUT);
    pinMode(REED_OCCUPANCY_SWITCH_PIN_INPUT, INPUT_PULLUP);
    connectToWiFi();
    setupTime();
    BLEDevice::init(DEVICE_NAME);
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY);
    pCharacteristic->setCallbacks(new UnlockCallback());
    pService->start();
    pAdvertising = pServer->getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
}

void loop() {
    if (isUnlocking && (millis() - unlockStartTime >= 2000)) {
        digitalWrite(LOCK_LED_PIN, LOW);
        isUnlocking = false;
    }
    int occupancyState = digitalRead(REED_OCCUPANCY_SWITCH_PIN_INPUT);
    digitalWrite(REED_OCCUPANCY_LED_PIN, occupancyState == LOW ? LOW : HIGH);
    delay(100);
}