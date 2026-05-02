import 'package:flutter/material.dart';

import 'package:travel_app_gdg/models/chat_models.dart';

class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.message});

  final UserMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: scheme.onPrimary),
        ),
      ),
    );
  }
}