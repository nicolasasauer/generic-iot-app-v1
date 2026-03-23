import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/widget_config.dart';
import '../models/sensor_config.dart';
import '../providers/dashboard_provider.dart';

/// Dialog for configuring a dashboard widget
class WidgetConfigDialog extends ConsumerStatefulWidget {
  final WidgetConfig? initialConfig;
  final Function(WidgetConfig) onSave;

  const WidgetConfigDialog({
    super.key,
    this.initialConfig,
    required this.onSave,
  });

  @override
  ConsumerState<WidgetConfigDialog> createState() =>
      _WidgetConfigDialogState();
}

class _WidgetConfigDialogState extends ConsumerState<WidgetConfigDialog> {
  late TextEditingController _titleController;
  late WidgetType _selectedType;
  String? _selectedSensorId;
  String? _selectedDeviceId;
  final Map<String, dynamic> _settings = {};

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialConfig?.title ?? '',
    );
    _selectedType = widget.initialConfig?.type ?? WidgetType.value;
    _selectedSensorId = widget.initialConfig?.sensorId;
    _selectedDeviceId = widget.initialConfig?.deviceId;
    _settings.addAll(widget.initialConfig?.settings ?? {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensors = ref.watch(sensorConfigsProvider);
    final devices = ref.watch(devicesProvider);

    return AlertDialog(
      title: Text(
        widget.initialConfig == null ? 'Add Widget' : 'Edit Widget',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Widget Title',
                hintText: 'e.g., Temperature',
              ),
            ),
            const SizedBox(height: 16),

            // Widget type selector
            DropdownButtonFormField<WidgetType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Widget Type'),
              items: WidgetType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Device selector
            if (devices.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedDeviceId,
                decoration: const InputDecoration(labelText: 'Device'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None'),
                  ),
                  ...devices.map((device) {
                    return DropdownMenuItem(
                      value: device.id,
                      child: Text(device.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDeviceId = value;
                  });
                },
              ),
            const SizedBox(height: 16),

            // Sensor selector
            if (sensors.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedSensorId,
                decoration: const InputDecoration(labelText: 'Sensor'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None'),
                  ),
                  ...sensors.map((sensor) {
                    return DropdownMenuItem(
                      value: sensor.id,
                      child: Text(sensor.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSensorId = value;
                  });
                },
              ),

            // Add sensor button if no sensors exist
            if (sensors.isEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showAddSensorDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Sensor Configuration'),
              ),
            ],

            // Widget-specific settings
            const SizedBox(height: 16),
            if (_selectedType == WidgetType.gauge ||
                _selectedType == WidgetType.chart) ...[
              const Text('Range:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Min Value',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _settings['minValue'] = double.tryParse(value) ?? 0.0;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Max Value',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _settings['maxValue'] = double.tryParse(value) ?? 100.0;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveWidget,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveWidget() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final config = WidgetConfig(
      id: widget.initialConfig?.id ?? _uuid.v4(),
      title: _titleController.text,
      type: _selectedType,
      sensorId: _selectedSensorId,
      deviceId: _selectedDeviceId,
      settings: _settings,
    );

    widget.onSave(config);
    Navigator.of(context).pop();
  }

  void _showAddSensorDialog(BuildContext context) {
    final nameController = TextEditingController();
    SensorType selectedType = SensorType.analog;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sensor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Sensor Name'),
            ),
            DropdownButtonFormField<SensorType>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: SensorType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString()),
                );
              }).toList(),
              onChanged: (value) {
                selectedType = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final sensor = SensorConfig(
                id: _uuid.v4(),
                name: nameController.text,
                type: selectedType,
              );
              ref.read(sensorConfigsProvider.notifier).addSensor(sensor);
              Navigator.pop(context);
              setState(() {
                _selectedSensorId = sensor.id;
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
