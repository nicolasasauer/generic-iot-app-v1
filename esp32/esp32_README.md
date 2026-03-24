# ESP32 IoT Firmware

This directory contains the ESP32 firmware for the IoT Dashboard application.

## Features

- BLE GATT Server with Nordic UART Service
- Multi-sensor support (Analog, Digital, I2C, SPI, UART)
- Ring buffer for data logging (1000 entries)
- JSON protocol for data transmission
- Configurable sampling rates
- Auto-send buffered data on connection
- LED status indicator

## Hardware Requirements

- ESP32 Development Board (ESP32-WROOM-32 or similar)
- USB cable for programming
- Optional sensors:
  - Analog sensors (e.g., LM35 temperature sensor)
  - Digital sensors (buttons, switches)
  - I2C sensors (e.g., BME280, BMP180)
  - SPI sensors

## Pin Configuration

### Default Pins
- **LED_PIN**: GPIO 2 (built-in LED)
- **ANALOG_PIN_1**: GPIO 34 (ADC1_CH6)
- **ANALOG_PIN_2**: GPIO 35 (ADC1_CH7)
- **DIGITAL_PIN_1**: GPIO 4 (input)
- **DIGITAL_PIN_2**: GPIO 5 (output)
- **I2C_SDA**: GPIO 21
- **I2C_SCL**: GPIO 22
- **SPI_MOSI**: GPIO 23
- **SPI_MISO**: GPIO 19
- **SPI_SCK**: GPIO 18
- **SPI_CS**: GPIO 5

## Wiring Examples

### Analog Temperature Sensor (LM35)
```
LM35 VCC  -> ESP32 3.3V
LM35 GND  -> ESP32 GND
LM35 OUT  -> ESP32 GPIO 34
```

### Digital Button
```
Button    -> ESP32 GPIO 4
Button    -> GND (with internal pull-up)
```

### I2C Sensor (BME280)
```
BME280 VCC  -> ESP32 3.3V
BME280 GND  -> ESP32 GND
BME280 SDA  -> ESP32 GPIO 21
BME280 SCL  -> ESP32 GPIO 22
```

## Installation

### 1. Install Arduino IDE
Download from: https://www.arduino.cc/en/software

### 2. Install ESP32 Board Support
1. Open Arduino IDE
2. Go to `File -> Preferences`
3. Add to "Additional Board Manager URLs":
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Go to `Tools -> Board -> Board Manager`
5. Search for "ESP32" and install "esp32 by Espressif Systems"

### 3. Install Required Libraries
Go to `Sketch -> Include Library -> Manage Libraries` and install:
- **ArduinoJson** by Benoit Blanchon (v6.x)
- **ESP32 BLE Arduino** (included with ESP32 board support)

Optional (for I2C sensors):
- **Adafruit BME280 Library**
- **Adafruit Unified Sensor**

### 4. Configure Board
1. Connect ESP32 via USB
2. Select `Tools -> Board -> ESP32 Arduino -> ESP32 Dev Module`
3. Select correct port: `Tools -> Port -> COMx` (Windows) or `/dev/ttyUSBx` (Linux)
4. Set upload speed: `Tools -> Upload Speed -> 115200`

### 5. Upload Firmware
1. Open `iot_firmware.ino`
2. Click Upload button (→)
3. Wait for compilation and upload to complete
4. Open Serial Monitor (`Tools -> Serial Monitor`) at 115200 baud

## Protocol

### Data Format (ESP32 -> App)
JSON messages terminated with newline:
```json
{"sensor":"temp","value":25.5,"unit":"°C","ts":1234567890}
```

Fields:
- `sensor`: Sensor ID string
- `value`: Numeric sensor value
- `unit`: Unit of measurement string
- `ts`: Timestamp (milliseconds since boot)

### Command Format (App -> ESP32)
JSON commands for configuration and control:

**Set Digital Output:**
```json
{"cmd":"set","sensor":"led","value":1}
```

**Configure Sampling Rate:**
```json
{"cmd":"config","sensor":"temp","samplingRate":500}
```

**Clear Buffer:**
```json
{"cmd":"clear"}
```

## BLE Service

**Service UUID:** `6e400001-b5a3-f393-e0a9-e50e24dcca9e` (Nordic UART Service)

**Characteristics:**
- **TX (ESP32 -> App):** `6e400003-b5a3-f393-e0a9-e50e24dcca9e`
  - Notify enabled
  - Sends sensor data

- **RX (App -> ESP32):** `6e400002-b5a3-f393-e0a9-e50e24dcca9e`
  - Write enabled
  - Receives commands

## Customization

### Adding New Sensors

Edit the `sensors[]` array in `iot_firmware.ino`:

```cpp
SensorConfig sensors[] = {
  {"temp", "analog", ANALOG_PIN_1, 1000, true},
  {"humidity", "i2c", 0, 2000, true},  // Add your sensor
};
```

### Modifying Sampling Rates

Change the `samplingRateMs` value in sensor config (in milliseconds):
```cpp
{"temp", "analog", ANALOG_PIN_1, 500, true},  // Sample every 500ms
```

### Adjusting Buffer Size

Modify the ring buffer size in the declaration:
```cpp
RingBuffer<String, 2000> dataBuffer;  // Increase to 2000 entries
```

## Troubleshooting

### Upload Fails
- Hold BOOT button while uploading
- Check USB cable (must support data, not just power)
- Try different USB port
- Reduce upload speed to 921600 or 460800

### No BLE Advertisement
- Check Serial Monitor for errors
- Ensure BLE is not disabled in menuconfig
- Try resetting ESP32
- Check power supply (USB must provide sufficient current)

### Sensors Not Reading
- Verify pin connections
- Check sensor power (3.3V vs 5V)
- Use multimeter to verify sensor output
- Enable debug output in Serial Monitor

### BLE Connection Drops
- Reduce distance to ESP32
- Check for interference (Wi-Fi, other BLE devices)
- Increase connection interval in BLE settings
- Add delays between notify() calls

## Power Consumption

Typical current consumption:
- **Idle (BLE advertising):** ~50-80 mA
- **Connected (data streaming):** ~80-120 mA
- **Deep sleep mode:** ~10 μA (not implemented in base firmware)

For battery operation, consider implementing:
- Deep sleep between readings
- Reduced BLE advertising interval
- Lower sampling rates

## Serial Monitor Output

Example output:
```
ESP32 IoT Firmware Starting...
BLE UART Service started, waiting for connections...
Firmware initialized. Ready for BLE connections.
Client connected
Sending buffered data...
Buffered data sent.
Sensor: temp = 25.3 °C
Sensor: voltage = 3.28 V
Sensor: button = 0
```

## License

This firmware is part of the IoT Dashboard project and is provided as-is for educational and development purposes.
