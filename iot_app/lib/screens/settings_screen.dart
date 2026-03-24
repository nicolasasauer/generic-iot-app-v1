import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../core/constants.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final sensors = ref.watch(sensorConfigsProvider);

    return Scaffold(
      body: ListView(
        children: [
          // App Settings Section
          _buildSectionHeader(context, 'App Settings'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Dark theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Theme settings dialog
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Ring Buffer Size'),
            subtitle: Text(
              '${AppConstants.defaultRingBufferSize} data points',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showBufferSizeDialog(context);
            },
          ),

          const Divider(),

          // Device Management Section
          _buildSectionHeader(context, 'Device Management'),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Saved Devices'),
            subtitle: Text('${devices.length} device(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showDeviceListDialog(context, ref, devices);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('Sensor Configurations'),
            subtitle: Text('${sensors.length} sensor(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showSensorListDialog(context, ref, sensors);
            },
          ),

          const Divider(),

          // Data Management Section
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Clear Dashboard'),
            subtitle: const Text('Remove all widgets'),
            onTap: () {
              _showClearDashboardDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear All Data'),
            subtitle: const Text('Reset app to defaults'),
            onTap: () {
              _showClearAllDialog(context, ref);
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('BLE Service UUID'),
            subtitle: Text(
              AppConstants.bleServiceUuid,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('About'),
            subtitle: const Text('IoT Dashboard for ESP32 devices'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showBufferSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ring Buffer Size'),
        content: const Text(
          'The ring buffer stores the most recent data points in memory. '
          'Older data is automatically discarded when the buffer is full.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeviceListDialog(
    BuildContext context,
    WidgetRef ref,
    List devices,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Devices'),
        content: SizedBox(
          width: double.maxFinite,
          child: devices.isEmpty
              ? const Text('No saved devices')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.address),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          ref
                              .read(devicesProvider.notifier)
                              .removeDevice(device.id);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSensorListDialog(
    BuildContext context,
    WidgetRef ref,
    List sensors,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sensor Configurations'),
        content: SizedBox(
          width: double.maxFinite,
          child: sensors.isEmpty
              ? const Text('No configured sensors')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: sensors.length,
                  itemBuilder: (context, index) {
                    final sensor = sensors[index];
                    return ListTile(
                      title: Text(sensor.name),
                      subtitle: Text('${sensor.type} - ${sensor.unit}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          ref
                              .read(sensorConfigsProvider.notifier)
                              .removeSensor(sensor.id);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDashboardDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Dashboard'),
        content: const Text(
          'Are you sure you want to remove all widgets from the dashboard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(dashboardProvider.notifier).clearAllWidgets();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dashboard cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all saved devices, sensors, widgets, and settings. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.clearAll();
              
              // Reload providers
              ref.invalidate(dashboardProvider);
              ref.invalidate(devicesProvider);
              ref.invalidate(sensorConfigsProvider);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
