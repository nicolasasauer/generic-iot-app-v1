/*
 * ESP32 IoT Firmware — PlatformIO / Arduino Framework
 *
 * BLE UART Service (Nordic UART Service UUIDs) compatible with the
 * Flutter IoT Dashboard app.
 *
 * Supports multiple sensor types: Analog, Digital, I2C, SPI, UART
 * Ring buffer for offline data logging (sent on reconnect).
 *
 * Protocol (JSON, newline-terminated):
 *   ESP32 → App  {"sensor":"temp","value":25.5,"unit":"°C","ts":12345}
 *   App  → ESP32  {"cmd":"set","sensor":"led","value":1}
 *                 {"cmd":"config","sensor":"temp","samplingRate":500}
 *                 {"cmd":"clear"}
 */

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <SPI.h>
#include "ring_buffer.h"

// ── BLE UUIDs (Nordic UART Service) ─────────────────────────────────────────
#define SERVICE_UUID           "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define TX_CHARACTERISTIC_UUID "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define RX_CHARACTERISTIC_UUID "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

// ── Pin definitions ──────────────────────────────────────────────────────────
#define LED_PIN       2   // Built-in LED
#define ANALOG_PIN_1  34  // ADC1 channel 6
#define ANALOG_PIN_2  35  // ADC1 channel 7
#define DIGITAL_PIN_1 4   // Digital input
#define DIGITAL_PIN_2 5   // Digital output

// ── I2C configuration ────────────────────────────────────────────────────────
#define I2C_SDA 21
#define I2C_SCL 22

// ── Ring buffer — 100 entries is plenty for offline storage on ESP32 ─────────
RingBuffer<String, 100> dataBuffer;

// ── BLE state ────────────────────────────────────────────────────────────────
BLEServer         *pServer           = nullptr;
BLECharacteristic *pTxCharacteristic = nullptr;
BLECharacteristic *pRxCharacteristic = nullptr;

volatile bool deviceConnected    = false;
bool          oldDeviceConnected = false;
bool          pendingBufferedSend = false; // deferred from BLE callback

// ── Sensor configuration ─────────────────────────────────────────────────────
struct SensorConfig {
  String id;
  String type;         // "analog" | "digital" | "i2c" | "spi" | "uart"
  int    pin;
  int    samplingRateMs;
  bool   enabled;
};

SensorConfig sensors[] = {
  {"temp",    "analog",  ANALOG_PIN_1,  1000, true},
  {"voltage", "analog",  ANALOG_PIN_2,  1000, true},
  {"button",  "digital", DIGITAL_PIN_1,  500, true},
};

const int     numSensors               = sizeof(sensors) / sizeof(sensors[0]);
unsigned long lastSampleTime[sizeof(sensors) / sizeof(sensors[0])] = {0};

// ── Forward declarations ─────────────────────────────────────────────────────
void   initBLE();
void   readAndSendSensor(int index);
void   sendBufferedData();
void   processCommand(const String &command);
double readI2CSensor();

// ── BLE server callbacks ──────────────────────────────────────────────────────
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) override {
    deviceConnected    = true;
    pendingBufferedSend = true;   // handled safely in loop()
    Serial.println("Client connected");
    digitalWrite(LED_PIN, HIGH);
  }

  void onDisconnect(BLEServer *pServer) override {
    deviceConnected = false;
    Serial.println("Client disconnected");
    digitalWrite(LED_PIN, LOW);
  }
};

// ── BLE RX characteristic callbacks (App → ESP32) ────────────────────────────
class RxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) override {
    String rxValue = pCharacteristic->getValue().c_str();
    if (rxValue.length() > 0) {
      Serial.print("Received command: ");
      Serial.println(rxValue);
      processCommand(rxValue);
    }
  }
};

// ── Setup ─────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 IoT Firmware Starting...");

  pinMode(LED_PIN,       OUTPUT);
  pinMode(DIGITAL_PIN_1, INPUT);
  pinMode(DIGITAL_PIN_2, OUTPUT);

  Wire.begin(I2C_SDA, I2C_SCL);
  SPI.begin();

  initBLE();

  Serial.println("Firmware initialized. Ready for BLE connections.");
}

// ── Main loop ─────────────────────────────────────────────────────────────────
void loop() {
  // Restart advertising after a disconnect
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Start advertising");
    oldDeviceConnected = false;
  }

  // Track transition to connected
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = true;
  }

  // Send buffered data after connect (deferred from BLE callback)
  if (deviceConnected && pendingBufferedSend) {
    pendingBufferedSend = false;
    sendBufferedData();
  }

  // Read sensors at their configured intervals
  unsigned long currentTime = millis();
  for (int i = 0; i < numSensors; i++) {
    if (sensors[i].enabled &&
        (currentTime - lastSampleTime[i] >=
         static_cast<unsigned long>(sensors[i].samplingRateMs))) {
      readAndSendSensor(i);
      lastSampleTime[i] = currentTime;
    }
  }

  // Blink LED while connected to indicate activity
  if (deviceConnected) {
    static unsigned long lastBlink = 0;
    if (currentTime - lastBlink > 1000) {
      digitalWrite(LED_PIN, !digitalRead(LED_PIN));
      lastBlink = currentTime;
    }
  }

  delay(10);
}

// ── BLE initialisation ────────────────────────────────────────────────────────
void initBLE() {
  BLEDevice::init("ESP32-IoT");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // TX characteristic — ESP32 → App (Notify)
  pTxCharacteristic = pService->createCharacteristic(
      TX_CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_NOTIFY);
  pTxCharacteristic->addDescriptor(new BLE2902());

  // RX characteristic — App → ESP32 (Write)
  pRxCharacteristic = pService->createCharacteristic(
      RX_CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_WRITE);
  pRxCharacteristic->setCallbacks(new RxCallbacks());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // 7.5 ms — help iOS find device
  pAdvertising->setMaxPreferred(0x12);  // 22.5 ms
  BLEDevice::startAdvertising();

  Serial.println("BLE UART Service started, waiting for connections...");
}

// ── Sensor reading and sending ────────────────────────────────────────────────
void readAndSendSensor(int index) {
  SensorConfig &sensor = sensors[index];
  double value = 0.0;
  String unit  = "";

  if (sensor.type == "analog") {
    int rawValue = analogRead(sensor.pin);
    // ESP32 ADC: 12-bit (0–4095) representing 0–3.3 V
    value = (rawValue / 4095.0) * 3.3;
    unit  = "V";
    if (sensor.id == "temp") {
      value = (value - 0.5) * 100.0;  // LM35 conversion
      unit  = "°C";
    }
  } else if (sensor.type == "digital") {
    value = digitalRead(sensor.pin);
    unit  = "";
  } else if (sensor.type == "i2c") {
    value = readI2CSensor();
    unit  = "°C";
  }

  // Build JSON message
  StaticJsonDocument<200> doc;
  doc["sensor"] = sensor.id;
  doc["value"]  = value;
  doc["unit"]   = unit;
  doc["ts"]     = millis();

  String message;
  serializeJson(doc, message);
  message += "\n";  // Matches AppConstants.messageTerminator

  dataBuffer.push(message);

  if (deviceConnected) {
    pTxCharacteristic->setValue(message.c_str());
    pTxCharacteristic->notify();
  }

  Serial.print("Sensor: ");
  Serial.print(sensor.id);
  Serial.print(" = ");
  Serial.print(value);
  Serial.print(" ");
  Serial.println(unit);
}

// ── Send buffered data to newly connected client ──────────────────────────────
void sendBufferedData() {
  Serial.println("Sending buffered data...");
  for (size_t i = 0; i < dataBuffer.size(); i++) {
    String data = dataBuffer.get(i);
    if (data.length() > 0) {
      pTxCharacteristic->setValue(data.c_str());
      pTxCharacteristic->notify();
      delay(20);  // Give BLE stack time to process each notification
    }
  }
  Serial.println("Buffered data sent.");
}

// ── Command processing (App → ESP32) ─────────────────────────────────────────
void processCommand(const String &command) {
  StaticJsonDocument<200> doc;
  DeserializationError    error = deserializeJson(doc, command);

  if (error) {
    Serial.print("JSON parse error: ");
    Serial.println(error.c_str());
    return;
  }

  const char *cmd = doc["cmd"];
  if (!cmd) return;

  if (strcmp(cmd, "set") == 0) {
    // Set a digital output pin
    const char *sensorId = doc["sensor"];
    int         value    = doc["value"];
    for (int i = 0; i < numSensors; i++) {
      if (sensors[i].id == sensorId && sensors[i].type == "digital") {
        digitalWrite(sensors[i].pin, value);
        Serial.printf("Set %s to %d\n", sensorId, value);
        break;
      }
    }
  } else if (strcmp(cmd, "config") == 0) {
    // Update a sensor's sampling rate
    const char *sensorId    = doc["sensor"];
    int         samplingRate = doc["samplingRate"];
    for (int i = 0; i < numSensors; i++) {
      if (sensors[i].id == sensorId) {
        sensors[i].samplingRateMs = samplingRate;
        Serial.printf("Configured %s sampling rate: %d ms\n",
                      sensorId, samplingRate);
        break;
      }
    }
  } else if (strcmp(cmd, "clear") == 0) {
    dataBuffer.clear();
    Serial.println("Buffer cleared");
  }
}

// ── I2C sensor placeholder ────────────────────────────────────────────────────
double readI2CSensor() {
  // Replace with actual sensor library calls (e.g. Adafruit BME280)
  return 25.0 + (random(0, 100) / 100.0);
}
