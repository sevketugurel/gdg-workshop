import 'package:flutter/material.dart';

import 'package:travel_app_gdg/models/chat_models.dart';
import 'ui_renderer.dart';

class AgentBubble extends StatelessWidget {
  const AgentBubble({super.key, required this.message, this.onUiAction});

  final AgentMessage message;
  final UiActionCallback? onUiAction;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (message.uiComponents.isNotEmpty) ...[
              const SizedBox(height: 8),
              UiRenderer(
                components: message.uiComponents,
                onAction: onUiAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}