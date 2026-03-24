# IoT Dashboard - Flutter ESP32 BLE Application

A comprehensive Flutter Android application for connecting to ESP32 devices via Bluetooth Low Energy (BLE), featuring modular dashboard widgets, real-time sensor data logging, and visualization.

## 🌟 Features

### Flutter App
- **BLE Connectivity**: Scan, connect, and communicate with ESP32 devices using flutter_blue_plus
- **Modular Dashboard**: Customizable widget-based dashboard inspired by Blynk and Home Assistant
- **Multiple Widget Types**:
  - **Gauge Widget**: Circular gauge with animated needle for real-time values
  - **Chart Widget**: Line charts with historical data visualization using fl_chart
  - **Value Widget**: Simple numeric display with statistics (min/max/avg)
  - **Toggle Widget**: On/off control for digital outputs
  - **Status Widget**: Connection and system status monitoring
- **Data Logging**: Ring buffer-based data logger with 10,000 entry capacity
- **Data Export**: CSV export functionality for data analysis
- **Real-time Data**: Live sensor data streaming and visualization
- **Process Monitoring**: Track active BLE connections and async operations
- **Persistent Storage**: Save devices, sensors, and dashboard configurations
- **Modern UI**: Dark theme with Material 3 design
- **State Management**: Riverpod 2.x for reactive state management

### ESP32 Firmware
- **BLE GATT Server**: Nordic UART Service implementation
- **Multi-Sensor Support**:
  - Analog sensors (ADC)
  - Digital I/O
  - I2C sensors
  - SPI sensors
  - UART sensors
- **Ring Buffer**: 1000-entry circular buffer for data persistence
- **JSON Protocol**: Structured data transmission
- **Configurable Sampling**: Adjustable sampling rates per sensor
- **Auto-Send on Connect**: Sends buffered data to new clients

## 📋 Requirements

### Flutter Development
- Flutter SDK 3.0 or higher
- Android Studio or VS Code
- Android SDK (API 21+)
- Physical Android device (BLE not supported in emulators)

### ESP32 Development
- Arduino IDE 1.8.x or 2.x
- ESP32 board support
- ArduinoJson library v6.x

## 🏗️ Architecture

### Flutter App Structure
```
iot_app/
├── lib/
│   ├── models/          # Data models (Device, DataPoint, SensorConfig, WidgetConfig)
│   ├── services/        # Business logic (BLE, DataLogger, Storage)
│   ├── providers/       # Riverpod state management
│   ├── screens/         # UI screens (Home, Dashboard, Scan, RawData, Settings)
│   ├── widgets/         # Reusable widgets (Gauge, Chart, Value, Toggle, Status)
│   ├── core/            # Theme, constants
│   ├── main.dart        # App entry point
│   └── app.dart         # MaterialApp configuration
├── test/                # Unit tests
├── android/             # Android platform configuration
└── pubspec.yaml         # Dependencies
```

### Key Dependencies
- `flutter_blue_plus: ^1.31.15` - BLE communication
- `riverpod: ^2.4.9` - State management
- `fl_chart: ^0.65.0` - Charts and graphs
- `shared_preferences: ^2.2.2` - Local storage
- `csv: ^6.0.0` - CSV export

## 🚀 Setup Instructions

### Flutter App Setup

1. **Clone the repository**:
   ```bash
   cd /path/to/generic-iot-app-v1/iot_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Android**:
   - Minimum SDK: 21
   - Target SDK: 34
   - Permissions already configured in AndroidManifest.xml

4. **Run on device**:
   ```bash
   flutter run
   ```

### ESP32 Firmware Setup

1. **Install Arduino IDE**: Download from https://www.arduino.cc/

2. **Add ESP32 Board Support**:
   - Go to File → Preferences
   - Add URL: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
   - Go to Tools → Board → Board Manager
   - Install "esp32 by Espressif Systems"

3. **Install Libraries**:
   - ArduinoJson (v6.x)

4. **Open Firmware**:
   - Open `esp32/firmware/iot_firmware.ino`

5. **Configure and Upload**:
   - Select Board: ESP32 Dev Module
   - Select Port
   - Upload

See `esp32/esp32_README.md` for detailed wiring and configuration.

## 📱 Usage

### 1. Start the App
Launch the IoT Dashboard app on your Android device.

### 2. Scan for Devices
- Navigate to the "Devices" tab
- Tap "Scan for Devices"
- Select your ESP32 device from the list
- Tap "Connect"

### 3. Configure Dashboard
- Navigate to the "Dashboard" tab
- Tap the "+" button to add widgets
- Select widget type (Gauge, Chart, Value, etc.)
- Assign sensor and configure settings
- Save

### 4. Monitor Data
- Real-time data appears on dashboard widgets
- Navigate to "Data Log" tab for raw data
- Export data to CSV for analysis

### 5. Configure Sensors
- Go to "Settings" tab
- Tap "Sensor Configurations"
- Add/edit sensor configurations
- Set sampling rates and ranges

## 🔌 BLE Protocol

### Service UUID
`6e400001-b5a3-f393-e0a9-e50e24dcca9e` (Nordic UART Service)

### Characteristics
- **TX (ESP32 → App)**: `6e400003-b5a3-f393-e0a9-e50e24dcca9e`
- **RX (App → ESP32)**: `6e400002-b5a3-f393-e0a9-e50e24dcca9e`

### Data Format

**Sensor Data (ESP32 → App)**:
```json
{"sensor":"temp","value":25.5,"unit":"°C","ts":1234567890}
```

**Commands (App → ESP32)**:

Set digital output:
```json
{"cmd":"set","sensor":"led","value":1}
```

Configure sensor:
```json
{"cmd":"config","sensor":"temp","samplingRate":500}
```

Clear buffer:
```json
{"cmd":"clear"}
```

## 🧪 Testing

Run all tests:
```bash
cd iot_app
flutter test
```

Test coverage includes:
- Model serialization/deserialization
- Ring buffer implementation
- Data filtering and queries
- Storage operations
- Provider state management

## 🎨 Customization

### Adding Custom Widgets
1. Create new widget class extending `ConsumerWidget`
2. Add to `WidgetType` enum in `models/widget_config.dart`
3. Update widget factory in `screens/dashboard_screen.dart`

### Adding Sensors
1. Update ESP32 firmware `sensors[]` array
2. Add sensor configuration in app settings
3. Create widgets to display sensor data

### Theming
Modify `lib/core/theme.dart` to customize colors and styles.

## 📊 Data Management

### Ring Buffer
- **Capacity**: 10,000 data points (configurable)
- **Behavior**: Circular buffer (oldest data overwritten when full)
- **Persistence**: In-memory only (cleared on app restart)
- **Export**: CSV export for long-term storage

### Storage
- **SharedPreferences**: Device configs, widget layouts, sensor settings
- **CSV Files**: Exported sensor data

## 🔧 Troubleshooting

### BLE Connection Issues
- Enable Bluetooth and Location on Android
- Grant all requested permissions
- Ensure ESP32 is powered and advertising
- Move closer to ESP32 (BLE range ~10m)

### No Data Showing
- Check sensor connections on ESP32
- Verify sensor configuration in app
- Check Serial Monitor on ESP32 for errors
- Ensure correct BLE characteristics are being used

### App Crashes
- Check LogCat for errors
- Verify all permissions granted
- Update Flutter and dependencies
- Clear app data and reinstall

## 🤝 Contributing

This is a complete reference implementation. Feel free to:
- Add more sensor types
- Implement additional widgets
- Enhance data visualization
- Add cloud sync features
- Improve error handling

## 📄 License

This project is provided as-is for educational and development purposes.

## 🙏 Acknowledgments

- Built with Flutter and ESP32
- Inspired by Blynk and Home Assistant
- Uses Nordic UART Service standard
- Material Design 3 theming

## 📞 Support

For issues and questions:
- Check ESP32 Serial Monitor output
- Review Flutter LogCat logs
- Verify BLE permissions and settings
- Consult esp32/esp32_README.md for firmware details

---

**Version**: 1.0.0  
**Last Updated**: 2024