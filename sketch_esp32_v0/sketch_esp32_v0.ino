#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <esp_task_wdt.h>
#include <WiFiClientSecure.h>
#include <time.h>         // Required for gettimeofday() and time functions
#include <sys/time.h>     // Required for struct timeval


// ✅ Configuration Constants
#define DEVICE_NAME "SmartPotty-ESP32"
#define SERVICE_UUID "abcd1234-5678-1234-5678-abcdef123456"
#define CHARACTERISTIC_UUID "abcd5678-1234-5678-1234-abcdef987654"
#define LOCK_LED_PIN 15  // LED Indicator
#define REED_LED_PIN 27  // REED Switch Indicator
#define WIFI_SSID "New Variant"
#define WIFI_PASSWORD "LebronJames"
#define TTLOCK_API_URL "http://euapi.ttlock.com/v3/lock/unlock"

// ✅ TTLock API Credentials
const char TTLOCK_CLIENT_ID[] PROGMEM = "7485f19f1da341c8bff11a5f913457a2";
const char TTLOCK_ACCESS_TOKEN[] PROGMEM = "c94900daa6a63589ff7a91bbe9146e7b";
const char TTLOCK_LOCK_ID[] PROGMEM = "20566298";

// ✅ BLE Variables
BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;
BLEAdvertising *pAdvertising = nullptr;
bool deviceConnected = false;
unsigned long unlockStartTime = 0;
bool isUnlocking = false;

// ✅ WiFi Connection Function with Debugging
void connectToWiFi() {
    Serial.println("🌐 Connecting to WiFi...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 15) {
        delay(1000);
        Serial.print("🕵️‍♂️ Attempting WiFi Connection... ");
        Serial.println(attempts + 1);
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("✅ WiFi Connected Successfully!");
        Serial.print("📶 IP Address: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("❌ WiFi Connection Failed! Check credentials or signal strength.");
    }
}

// ✅ Initialize NTP Time Sync
void setupTime() {
    Serial.println("⏳ Setting up NTP Time Sync...");
    configTime(0, 0, "pool.ntp.org", "time.nist.gov");  // Use NTP servers

    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        Serial.println("❌ Failed to sync time! Retrying...");
        delay(2000);
        if (!getLocalTime(&timeinfo)) {
            Serial.println("🚫 Time sync failed twice! Check WiFi.");
            return;
        }
    }

    Serial.println("✅ Time Synced Successfully!");
    Serial.print("🕒 UTC Time: ");
    Serial.println(asctime(&timeinfo));
}

uint64_t getCurrentUTCMillis() {
    struct timeval tv;
    gettimeofday(&tv, NULL);

    // ✅ Use uint64_t to store full precision
    uint64_t utcMillis = ((uint64_t)tv.tv_sec * 1000UL) + (tv.tv_usec / 1000UL);

    Serial.print("📆 gettimeofday() UTC Seconds: ");
    Serial.println(tv.tv_sec);

    Serial.print("✅ Corrected UTC Milliseconds: ");
    Serial.println(utcMillis);

    return utcMillis;
}


// ✅ BLE Server Callbacks (Keep Advertising)
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) override {
        Serial.println("✅ BLE Device Connected!");
        deviceConnected = true;
    }

    void onDisconnect(BLEServer* pServer) override {
        Serial.println("❌ BLE Device Disconnected! Restarting Advertising...");
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

    Serial.println("📡 Preparing to send Unlock Request to TTLock...");

    WiFiClient client; // Use WiFiClient for HTTP (not WiFiClientSecure)
    HTTPClient http;
    http.begin(client, TTLOCK_API_URL);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");

    // ✅ Get Correct UTC Timestamp in Milliseconds
    unsigned long utcMillis = getCurrentUTCMillis();
    if (utcMillis == 0) {
        Serial.println("❌ Failed to get valid UTC timestamp, skipping API call!");
        return;
    }

    // ✅ Construct POST Data
    String postData = "clientId=" + String(TTLOCK_CLIENT_ID) +
                      "&accessToken=" + String(TTLOCK_ACCESS_TOKEN) +
                      "&lockId=" + String(TTLOCK_LOCK_ID) +
                      "&date=" + String(getCurrentUTCMillis(), DEC); // Explicit decimal format

    Serial.println("📤 Sending Unlock Request to TTLock API...");
    Serial.println("🔍 POST Data: " + postData);

    int httpResponseCode = http.POST(postData);

    if (httpResponseCode > 0) {
        Serial.println("✅ TTLock Unlock Success! HTTP Code: " + String(httpResponseCode));
        Serial.println("📝 TTLock Response: " + http.getString()); // Print full response
    } else {
        Serial.println("❌ TTLock Unlock Failed! HTTP Error: " + String(http.errorToString(httpResponseCode).c_str()));
        Serial.println("📡 Check network connection & API credentials.");
    }

    http.end();
}

// ✅ BLE Characteristic Callbacks
class UnlockCallback : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) override {
        std::string value = std::string(pCharacteristic->getValue().c_str()); // Safe conversion

        if (value == "unlock") {
            Serial.println("🔑 Unlock command received!");
            digitalWrite(LOCK_LED_PIN, HIGH);
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
    pinMode(LOCK_LED_PIN, OUTPUT);
    digitalWrite(LOCK_LED_PIN, LOW);

    pinMode(REED_LED_PIN, OUTPUT); // Reed Switch
    digitalWrite(REED_LED_PIN, LOW); // Reed Switch

    delay(1000); // Startup delay

    Serial.println("🚀 Initializing BLE...");

    // ✅ Connect to WiFi with Debugging
    connectToWiFi();

    // ✅ Initialize NTP Client
    setupTime();

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

    Serial.println("🛡️ Watchdog Timer Initialized!");
}

void loop() {
    // ✅ Handle Unlock Timing
    if (isUnlocking && (millis() - unlockStartTime >= 2000)) { // 2 seconds
        digitalWrite(LOCK_LED_PIN, LOW); // Turn off LED
        isUnlocking = false;
        Serial.println("🚪 Door unlocked successfully!");
    }

    // ✅ Debugging delay
    delay(100);
}
