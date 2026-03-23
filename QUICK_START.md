# Quick Start Guide - IoT Dashboard

Get up and running in 5 minutes!

## Prerequisites Checklist

- [ ] Android phone/tablet (Android 5.0+)
- [ ] ESP32 development board
- [ ] USB cable
- [ ] Computer with Arduino IDE
- [ ] Optional: Sensors (temperature, buttons, etc.)

## Step 1: ESP32 Setup (5 minutes)

### 1.1 Install Arduino IDE
1. Download from https://www.arduino.cc/en/software
2. Install and open

### 1.2 Add ESP32 Support
1. File → Preferences
2. Additional Board Manager URLs: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. Tools → Board → Board Manager
4. Search "ESP32" → Install "esp32 by Espressif"

### 1.3 Install Libraries
1. Sketch → Include Library → Manage Libraries
2. Search and install: **ArduinoJson** (v6.x)

### 1.4 Upload Firmware
1. Connect ESP32 via USB
2. Tools → Board → "ESP32 Dev Module"
3. Tools → Port → Select your COM port
4. Open `esp32/firmware/iot_firmware.ino`
5. Click Upload (→ button)
6. Wait for "Done uploading"

### 1.5 Verify
1. Tools → Serial Monitor
2. Set baud rate to 115200
3. You should see:
   ```
   ESP32 IoT Firmware Starting...
   BLE UART Service started, waiting for connections...
   ```

## Step 2: Flutter App Setup (Optional - Pre-built APK)

### Option A: Use Pre-built APK (Fastest)
*If APK provided:*
1. Copy APK to phone
2. Install (enable "Install from unknown sources" if needed)
3. Skip to Step 3

### Option B: Build from Source
```bash
# Navigate to project
cd iot_app

# Get dependencies
flutter pub get

# Connect Android phone via USB
# Enable USB debugging on phone

# Build and install
flutter run
```

## Step 3: Connect & Use (2 minutes)

### 3.1 Launch App
1. Open "IoT Dashboard" on your Android phone
2. Grant Bluetooth and Location permissions when prompted

### 3.2 Scan for ESP32
1. Tap "Devices" tab at bottom
2. Tap "SCAN FOR DEVICES" button
3. Wait for "ESP32-IoT" to appear
4. Tap "CONNECT" next to ESP32-IoT
5. Wait for "Connected" message

### 3.3 Create Your First Widget
1. Tap "Dashboard" tab
2. Tap floating "+" button
3. Enter widget title: "Temperature"
4. Select widget type: "Gauge"
5. Tap "Add Sensor Configuration" if no sensors exist
   - Name: "temp"
   - Type: "Analog"
6. Select sensor: "temp"
7. Set Min Value: 0, Max Value: 50
8. Tap "SAVE"

### 3.4 View Live Data
- Dashboard shows live gauge updating
- Tap "Data Log" to see raw data stream
- Tap "EXPORT" to save CSV file

## Quick Test Without Sensors

The ESP32 firmware includes simulated sensors by default:
- **temp**: Simulated temperature (analog reading)
- **voltage**: Voltage measurement
- **button**: Digital input (if pin connected to GND)

## Troubleshooting

### ESP32 Upload Failed
- Hold BOOT button while uploading
- Try different USB cable
- Check driver installation

### App Can't Find ESP32
- Enable Bluetooth on phone
- Enable Location services
- Move closer to ESP32
- Check Serial Monitor shows "waiting for connections"

### No Data on Dashboard
- Verify ESP32 Serial Monitor shows sensor readings
- Check sensor is enabled in firmware
- Reconnect BLE device

### Permission Errors
- Settings → Apps → IoT Dashboard → Permissions
- Enable all permissions (Bluetooth, Location, Storage)

## Next Steps

### Add Real Sensors

**Temperature Sensor (LM35)**:
```
LM35 Pin 1 (VCC) → ESP32 3.3V
LM35 Pin 2 (OUT) → ESP32 GPIO 34
LM35 Pin 3 (GND) → ESP32 GND
```

**Button**:
```
Button → ESP32 GPIO 4
Button → GND
```

### Customize Firmware

Edit `iot_firmware.ino`:
```cpp
// Change sensor configuration
SensorConfig sensors[] = {
  {"temp", "analog", 34, 1000, true},      // Sample every 1 second
  {"humidity", "analog", 35, 2000, true},  // Sample every 2 seconds
};
```

### Add More Widgets

1. Dashboard → "+" button
2. Try different types:
   - **Chart**: Historical data graph
   - **Value**: Simple number display
   - **Toggle**: Control outputs
   - **Status**: System monitoring

### Export Data

1. Data Log tab
2. Tap "EXPORT"
3. CSV file saved to device
4. Open with Excel/Sheets

## Example Use Cases

### Home Temperature Monitor
- Connect DHT22 sensor
- Create gauge widget (0-50°C)
- Create chart widget (24h history)
- Export data for analysis

### LED Controller
- Connect LED to GPIO 5
- Create toggle widget
- Control LED from app
- Monitor on/off status

### Multi-Sensor Station
- Temperature (analog)
- Humidity (I2C)
- Light level (analog)
- Motion sensor (digital)

## Resources

- **Full Documentation**: See README.md
- **ESP32 Details**: See esp32/esp32_README.md
- **Project Structure**: See PROJECT_STRUCTURE.md
- **Serial Monitor**: Essential for debugging

## Common Commands

### BLE Commands (App → ESP32)

Set digital pin:
```json
{"cmd":"set","sensor":"led","value":1}
```

Change sampling rate:
```json
{"cmd":"config","sensor":"temp","samplingRate":500}
```

Clear buffer:
```json
{"cmd":"clear"}
```

## Support

Having issues?

1. Check Serial Monitor for ESP32 errors
2. Verify BLE permissions granted
3. Try restarting ESP32
4. Reinstall app if needed
5. Review README.md troubleshooting section

## Success Indicators

✅ Serial Monitor shows sensor readings  
✅ App shows "Connected"  
✅ Dashboard widgets update in real-time  
✅ Data Log shows incoming data  
✅ LED on ESP32 blinks when connected

---

**Ready to build?** Start with Step 1!

**Questions?** Check README.md for detailed documentation.

**Happy building!** 🚀
