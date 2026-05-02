import 'ui_component.dart';

class UserMessage {
  const UserMessage({
    required this.id,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String text;
  final DateTime timestamp;
}

class AgentMessage {
  const AgentMessage({
    required this.id,
    required this.text,
    this.uiComponents = const [],
    required this.timestamp,
  });

  final String id;
  final String text;
  final List<UiComponent> uiComponents;
  final DateTime timestamp;
}