/*
 * ESP32 IoT Firmware with BLE UART Service
 * Supports multiple sensor types: UART, I2C, SPI, Analog, Digital
 * Implements ring buffer for data logging
 * BLE GATT server with Nordic UART Service UUID
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <SPI.h>
#include "ring_buffer.h"

// BLE Service and Characteristic UUIDs (Nordic UART Service)
#define SERVICE_UUID "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define TX_CHARACTERISTIC_UUID "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define RX_CHARACTERISTIC_UUID "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

// Pin definitions
#define LED_PIN 2            // Built-in LED
#define ANALOG_PIN_1 34      // ADC1 channel
#define ANALOG_PIN_2 35      // ADC1 channel
#define DIGITAL_PIN_1 4      // Digital input
#define DIGITAL_PIN_2 5      // Digital output

// I2C configuration (example for BME280 or similar)
#define I2C_SDA 21
#define I2C_SCL 22

// Ring buffer for storing sensor data
RingBuffer<String, 1000> dataBuffer;

// BLE objects
BLEServer *pServer = NULL;
BLECharacteristic *pTxCharacteristic = NULL;
BLECharacteristic *pRxCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Sensor configuration
struct SensorConfig {
  String id;
  String type;  // "analog", "digital", "i2c", "spi", "uart"
  int pin;
  int samplingRateMs;
  bool enabled;
};

SensorConfig sensors[] = {
  {"temp", "analog", ANALOG_PIN_1, 1000, true},
  {"voltage", "analog", ANALOG_PIN_2, 1000, true},
  {"button", "digital", DIGITAL_PIN_1, 500, true},
};

const int numSensors = sizeof(sensors) / sizeof(sensors[0]);
unsigned long lastSampleTime[10] = {0};

// BLE Server Callbacks
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("Client connected");
    digitalWrite(LED_PIN, HIGH);
    
    // Send buffered data to newly connected client
    sendBufferedData();
  }

  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("Client disconnected");
    digitalWrite(LED_PIN, LOW);
  }
};

// BLE RX Characteristic Callbacks (receive commands from app)
class RxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue().c_str();
    
    if (rxValue.length() > 0) {
      Serial.print("Received command: ");
      Serial.println(rxValue);
      processCommand(rxValue);
    }
  }
};

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 IoT Firmware Starting...");

  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(DIGITAL_PIN_1, INPUT);
  pinMode(DIGITAL_PIN_2, OUTPUT);

  // Initialize I2C
  Wire.begin(I2C_SDA, I2C_SCL);
  
  // Initialize SPI
  SPI.begin();

  // Initialize BLE
  initBLE();

  Serial.println("Firmware initialized. Ready for BLE connections.");
}

void loop() {
  // Handle BLE connection state changes
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Read sensors at configured intervals
  unsigned long currentTime = millis();
  
  for (int i = 0; i < numSensors; i++) {
    if (sensors[i].enabled && 
        (currentTime - lastSampleTime[i] >= sensors[i].samplingRateMs)) {
      
      readAndSendSensor(i);
      lastSampleTime[i] = currentTime;
    }
  }

  // Blink LED to show activity
  if (deviceConnected) {
    static unsigned long lastBlink = 0;
    if (currentTime - lastBlink > 1000) {
      digitalWrite(LED_PIN, !digitalRead(LED_PIN));
      lastBlink = currentTime;
    }
  }

  delay(10);
}

void initBLE() {
  // Create BLE Device
  BLEDevice::init("ESP32-IoT");

  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create TX Characteristic (ESP32 -> App)
  pTxCharacteristic = pService->createCharacteristic(
    TX_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTxCharacteristic->addDescriptor(new BLE2902());

  // Create RX Characteristic (App -> ESP32)
  pRxCharacteristic = pService->createCharacteristic(
    RX_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  pRxCharacteristic->setCallbacks(new RxCallbacks());

  // Start service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE UART Service started, waiting for connections...");
}

void readAndSendSensor(int index) {
  SensorConfig &sensor = sensors[index];
  double value = 0;
  String unit = "";

  // Read sensor based on type
  if (sensor.type == "analog") {
    int rawValue = analogRead(sensor.pin);
    // Convert to voltage (ESP32 ADC is 0-4095 for 0-3.3V)
    value = (rawValue / 4095.0) * 3.3;
    unit = "V";
    
    // For temperature sensor example (if using analog temp sensor)
    if (sensor.id == "temp") {
      value = (value - 0.5) * 100.0;  // Example: LM35 conversion
      unit = "°C";
    }
  }
  else if (sensor.type == "digital") {
    value = digitalRead(sensor.pin);
    unit = "";
  }
  else if (sensor.type == "i2c") {
    // Example: Read from I2C sensor
    value = readI2CSensor();
    unit = "°C";
  }

  // Create JSON message
  StaticJsonDocument<200> doc;
  doc["sensor"] = sensor.id;
  doc["value"] = value;
  doc["unit"] = unit;
  doc["ts"] = millis();

  String message;
  serializeJson(doc, message);
  message += "\n";

  // Store in ring buffer
  dataBuffer.push(message);

  // Send via BLE if connected
  if (deviceConnected) {
    pTxCharacteristic->setValue(message.c_str());
    pTxCharacteristic->notify();
  }

  // Debug output
  Serial.print("Sensor: ");
  Serial.print(sensor.id);
  Serial.print(" = ");
  Serial.print(value);
  Serial.print(" ");
  Serial.println(unit);
}

void sendBufferedData() {
  // Send all buffered data to newly connected client
  Serial.println("Sending buffered data...");
  
  for (size_t i = 0; i < dataBuffer.size(); i++) {
    String data = dataBuffer.get(i);
    if (data.length() > 0) {
      pTxCharacteristic->setValue(data.c_str());
      pTxCharacteristic->notify();
      delay(10);  // Small delay to avoid overwhelming client
    }
  }
  
  Serial.println("Buffered data sent.");
}

void processCommand(String command) {
  // Parse JSON command
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, command);

  if (error) {
    Serial.print("JSON parse error: ");
    Serial.println(error.c_str());
    return;
  }

  String cmd = doc["cmd"];

  if (cmd == "set") {
    // Set digital output
    String sensorId = doc["sensor"];
    int value = doc["value"];
    
    // Find sensor and set output
    for (int i = 0; i < numSensors; i++) {
      if (sensors[i].id == sensorId && sensors[i].type == "digital") {
        digitalWrite(sensors[i].pin, value);
        Serial.print("Set ");
        Serial.print(sensorId);
        Serial.print(" to ");
        Serial.println(value);
        break;
      }
    }
  }
  else if (cmd == "config") {
    // Configure sensor
    String sensorId = doc["sensor"];
    int samplingRate = doc["samplingRate"];
    
    for (int i = 0; i < numSensors; i++) {
      if (sensors[i].id == sensorId) {
        sensors[i].samplingRateMs = samplingRate;
        Serial.print("Configured ");
        Serial.print(sensorId);
        Serial.print(" sampling rate: ");
        Serial.println(samplingRate);
        break;
      }
    }
  }
  else if (cmd == "clear") {
    // Clear ring buffer
    dataBuffer.clear();
    Serial.println("Buffer cleared");
  }
}

double readI2CSensor() {
  // Example: Read from I2C temperature sensor
  // This is a placeholder - implement actual I2C reading based on your sensor
  // For BME280, you would use the Adafruit BME280 library
  
  // Simulated reading
  return 25.0 + (random(0, 100) / 100.0);
}
