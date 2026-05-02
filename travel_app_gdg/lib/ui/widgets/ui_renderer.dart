import 'package:flutter/material.dart';

import 'package:travel_app_gdg/models/ui_component.dart';
import 'trip_layout_widgets.dart';

typedef UiActionCallback = void Function(String actionType, String buttonText);

class UiRenderer extends StatelessWidget {
  const UiRenderer({super.key, required this.components, this.onAction});

  final List<UiComponent> components;
  final UiActionCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final c = components[index];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (c) {
            UiMetricCard m => _metricCard(m),
            UiSpendingChart s => _chart(s),
            UiActionButton a => _button(context, a),
            UiTripLayout t => buildTripLayout(t.layoutType, t.data),
          },
        );
      },
    );
  }

  Widget _metricCard(UiMetricCard m) {
    return Card(
      elevation: m.isAlert ? 4 : 1,
      color: m.isAlert ? Colors.orange.shade50 : Colors.white,
      child: ListTile(
        title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(m.value, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _chart(UiSpendingChart s) {
    return SizedBox(
      height: 200,
      child: Card(
        child: Center(
          child: Text(
            '${s.labels.length} veri noktası (grafik yer tutucu)',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _button(BuildContext context, UiActionButton a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: FilledButton(
        onPressed: () {
          if (onAction != null) {
            onAction!(a.actionType, a.text);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(a.actionType)),
            );
          }
        },
        child: Text(a.text),
      ),
    );
  }
}