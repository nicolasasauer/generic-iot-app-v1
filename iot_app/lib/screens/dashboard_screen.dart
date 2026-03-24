import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/widget_config_dialog.dart';
import '../widgets/iot_gauge_widget.dart';
import '../widgets/iot_chart_widget.dart';
import '../widgets/iot_value_widget.dart';
import '../widgets/iot_toggle_widget.dart';
import '../widgets/iot_status_widget.dart';
import '../models/widget_config.dart';

/// Main dashboard screen with configurable widgets
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final widgets = ref.watch(dashboardProvider);

    return Scaffold(
      body: widgets.isEmpty
          ? _buildEmptyState()
          : _buildDashboard(widgets),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWidgetDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Widget'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No widgets yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first widget',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(List<WidgetConfig> widgets) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final widget = widgets[index];
                return _buildWidgetCard(widget);
              },
              childCount: widgets.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetCard(WidgetConfig config) {
    return GestureDetector(
      onLongPress: () => _showWidgetOptions(config),
      child: Card(
        child: Column(
          children: [
            // Widget header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      config.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isEditMode)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteWidget(config.id),
                    ),
                ],
              ),
            ),
            // Widget content
            Expanded(
              child: _buildWidgetContent(config),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetContent(WidgetConfig config) {
    switch (config.type) {
      case WidgetType.gauge:
        return IotGaugeWidget(config: config);
      case WidgetType.chart:
        return IotChartWidget(config: config);
      case WidgetType.value:
        return IotValueWidget(config: config);
      case WidgetType.toggle:
        return IotToggleWidget(config: config);
      case WidgetType.status:
        return IotStatusWidget(config: config);
    }
  }

  void _showAddWidgetDialog() {
    showDialog(
      context: context,
      builder: (context) => WidgetConfigDialog(
        onSave: (config) {
          ref.read(dashboardProvider.notifier).addWidget(config);
        },
      ),
    );
  }

  void _showWidgetOptions(WidgetConfig config) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editWidget(config);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteWidget(config.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editWidget(WidgetConfig config) {
    showDialog(
      context: context,
      builder: (context) => WidgetConfigDialog(
        initialConfig: config,
        onSave: (updatedConfig) {
          ref.read(dashboardProvider.notifier).updateWidget(updatedConfig);
        },
      ),
    );
  }

  void _deleteWidget(String widgetId) {
    ref.read(dashboardProvider.notifier).removeWidget(widgetId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Widget removed')),
    );
  }
}
