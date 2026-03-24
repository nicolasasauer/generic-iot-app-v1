import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'scan_screen.dart';
import 'raw_data_screen.dart';
import 'settings_screen.dart';
import '../providers/bluetooth_provider.dart';
import '../services/bluetooth_service.dart';
import '../models/device.dart';

/// Main navigation screen with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ScanScreen(),
    RawDataScreen(),
    SettingsScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.bluetooth_outlined),
      selectedIcon: Icon(Icons.bluetooth),
      label: 'Devices',
    ),
    NavigationDestination(
      icon: Icon(Icons.data_array_outlined),
      selectedIcon: Icon(Icons.data_array),
      label: 'Data Log',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bluetoothStatus = ref.watch(bluetoothStatusProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Dashboard'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: bluetoothStatus.when(
              data: (status) => _buildStatusIndicator(status, connectedDevices),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _destinations,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Quick add widget action
                _showAddWidgetDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildStatusIndicator(
    BluetoothStatus status,
    Map<String, IotDevice> connectedDevices,
  ) {
    Color color;
    IconData icon;
    String tooltip;

    switch (status) {
      case BluetoothStatus.connected:
        color = Colors.green;
        icon = Icons.bluetooth_connected;
        tooltip = '${connectedDevices.length} device(s) connected';
        break;
      case BluetoothStatus.scanning:
        color = Colors.blue;
        icon = Icons.bluetooth_searching;
        tooltip = 'Scanning...';
        break;
      case BluetoothStatus.connecting:
        color = Colors.orange;
        icon = Icons.bluetooth;
        tooltip = 'Connecting...';
        break;
      case BluetoothStatus.error:
        color = Colors.red;
        icon = Icons.bluetooth_disabled;
        tooltip = 'Error';
        break;
      default:
        color = Colors.grey;
        icon = Icons.bluetooth;
        tooltip = 'Disconnected';
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          if (connectedDevices.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '${connectedDevices.length}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddWidgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Widget'),
        content: const Text(
          'Navigate to Dashboard screen and tap the + button to add a new widget.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
