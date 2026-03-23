import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/widget_config.dart';
import '../providers/bluetooth_provider.dart';

/// Toggle widget for digital output control
class IotToggleWidget extends ConsumerStatefulWidget {
  final WidgetConfig config;

  const IotToggleWidget({super.key, required this.config});

  @override
  ConsumerState<IotToggleWidget> createState() => _IotToggleWidgetState();
}

class _IotToggleWidgetState extends ConsumerState<IotToggleWidget> {
  bool _isOn = false;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Toggle switch
          GestureDetector(
            onTap: _isSending ? null : _toggleState,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: _isOn ? Colors.green : Colors.grey[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: _isOn ? 40 : 0,
                    top: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _isOn ? Icons.power : Icons.power_off,
                              color: _isOn ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Status text
          Text(
            _isOn ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isOn ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleState() async {
    if (widget.config.deviceId == null || widget.config.sensorId == null) {
      _showError('Device or sensor not configured');
      return;
    }

    setState(() {
      _isSending = true;
    });

    final newState = !_isOn;
    final command = '{"cmd":"set","sensor":"${widget.config.sensorId}",'
        '"value":${newState ? 1 : 0}}\n';

    final success = await ref
        .read(bluetoothNotifierProvider.notifier)
        .sendCommand(widget.config.deviceId!, command);

    if (mounted) {
      setState(() {
        _isSending = false;
        if (success) {
          _isOn = newState;
        }
      });

      if (!success) {
        _showError('Failed to send command');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
