/// AI JSON dizisindeki tek bir bileşen (`runtimeType` ile ayrılır).
sealed class UiComponent {
  const UiComponent();

  /// Firestore / log için (AI ile aynı `runtimeType` alanları).
  Map<String, dynamic> toJson();

  factory UiComponent.fromJson(Map<String, dynamic> json) {
    final type =
        json['runtimeType'] as String? ?? json['type'] as String? ?? '';
    switch (type) {
      case 'metricCard':
        return UiMetricCard(
          label: json['label'] as String,
          value: json['value'] as String,
          isAlert: json['isAlert'] as bool? ?? false,
        );
      case 'spendingChart':
        return UiSpendingChart(
          dataPoints: (json['dataPoints'] as List<dynamic>)
              .map((e) => (e as num).toDouble())
              .toList(),
          labels: (json['labels'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
        );
      case 'actionButton':
        return UiActionButton(
          text: json['text'] as String,
          actionType: json['actionType'] as String,
        );
      case 'tripLayout':
        return UiTripLayout(
          layoutType: json['layoutType'] as String,
          data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
        );
      default:
        throw FormatException('Bilinmeyen UiComponent: $type', json);
    }
  }
}

final class UiMetricCard extends UiComponent {
  const UiMetricCard({
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final bool isAlert;

  @override
  Map<String, dynamic> toJson() => {
        'runtimeType': 'metricCard',
        'label': label,
        'value': value,
        'isAlert': isAlert,
      };
}

final class UiSpendingChart extends UiComponent {
  const UiSpendingChart({
    required this.dataPoints,
    required this.labels,
  });

  final List<double> dataPoints;
  final List<String> labels;

  @override
  Map<String, dynamic> toJson() => {
        'runtimeType': 'spendingChart',
        'dataPoints': dataPoints,
        'labels': labels,
      };
}

final class UiActionButton extends UiComponent {
  const UiActionButton({
    required this.text,
    required this.actionType,
  });

  final String text;
  final String actionType;

  @override
  Map<String, dynamic> toJson() => {
        'runtimeType': 'actionButton',
        'text': text,
        'actionType': actionType,
      };
}

final class UiTripLayout extends UiComponent {
  const UiTripLayout({
    required this.layoutType,
    required this.data,
  });

  final String layoutType;
  final Map<String, dynamic> data;

  @override
  Map<String, dynamic> toJson() => {
        'runtimeType': 'tripLayout',
        'layoutType': layoutType,
        'data': data,
      };
}