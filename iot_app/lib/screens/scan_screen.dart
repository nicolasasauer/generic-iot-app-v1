import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/device.dart';

/// Screen for scanning and connecting to BLE devices
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  Widget build(BuildContext context) {
    final discoveredDevices = ref.watch(discoveredDevicesProvider);
    final isScanning = ref.watch(isScanningProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(bluetoothNotifierProvider.notifier).startScan();
        },
        child: Column(
          children: [
            // Scan control header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isScanning
                          ? () => ref
                              .read(bluetoothNotifierProvider.notifier)
                              .stopScan()
                          : () => ref
                              .read(bluetoothNotifierProvider.notifier)
                              .startScan(durationSeconds: 10),
                      icon: isScanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(isScanning ? 'Stop Scan' : 'Scan for Devices'),
                    ),
                  ),
                ],
              ),
            ),

            // Connected devices section
            if (connectedDevices.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Connected Devices',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: connectedDevices.length,
                itemBuilder: (context, index) {
                  final device = connectedDevices.values.elementAt(index);
                  return _buildConnectedDeviceCard(device);
                },
              ),
              const Divider(height: 32),
            ],

            // Discovered devices section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Available Devices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Device list
            Expanded(
              child: discoveredDevices.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isScanning
                                ? 'Scanning for devices...'
                                : 'No devices found\nTap "Scan for Devices" to start',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final scanResult = devices[index];
                      return _buildDeviceCard(scanResult);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(ScanResult scanResult) {
    final device = scanResult.device;
    final rssi = scanResult.rssi;
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';
    final deviceId = device.remoteId.str;
    
    final isConnected = ref
        .watch(connectedDevicesProvider)
        .containsKey(deviceId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth,
              color: _getRssiColor(rssi),
            ),
          ],
        ),
        title: Text(deviceName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(deviceId, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.signal_cellular_alt, size: 14, color: _getRssiColor(rssi)),
                const SizedBox(width: 4),
                Text('$rssi dBm', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: isConnected
            ? OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(bluetoothNotifierProvider.notifier)
                      .disconnectFromDevice(deviceId);
                },
                child: const Text('Disconnect'),
              )
            : ElevatedButton(
                onPressed: () async {
                  final success = await ref
                      .read(bluetoothNotifierProvider.notifier)
                      .connectToDevice(deviceId);

                  if (success && mounted) {
                    // Save device to storage
                    final iotDevice = IotDevice(
                      id: deviceId,
                      name: deviceName,
                      address: deviceId,
                      isConnected: true,
                      rssi: rssi,
                      lastSeen: DateTime.now(),
                    );
                    await ref
                        .read(devicesProvider.notifier)
                        .saveDevice(iotDevice);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connected to $deviceName'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to connect'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Connect'),
              ),
      ),
    );
  }

  Widget _buildConnectedDeviceCard(IotDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
        title: Text(device.name),
        subtitle: Text(device.address),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await ref
                .read(bluetoothNotifierProvider.notifier)
                .disconnectFromDevice(device.id);
          },
        ),
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }
}
