import 'package:flutter/material.dart';

List<Map<String, dynamic>> _daysFromData(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// `tripLayout` + `layoutType` / `data` → widget.
Widget buildTripLayout(String layoutType, Map<String, dynamic> data) {
  switch (layoutType) {
    case 'itinerary_viewer':
      return ItineraryWidget(days: _daysFromData(data['days']));
    case 'budget_alert':
      return BudgetWarningWidget(
        current: '${data['current'] ?? ''}',
        limit: '${data['limit'] ?? ''}',
      );
    case 'booking_confirmation':
      return BookingCard(
        details: Map<String, dynamic>.from(data['booking_info'] as Map? ?? {}),
      );
    default:
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          data['message'] as String? ?? 'Plan hazırlanıyor…',
          style: const TextStyle(height: 1.35),
        ),
      );
  }
}

class ItineraryWidget extends StatelessWidget {
  const ItineraryWidget({super.key, required this.days});

  final List<Map<String, dynamic>> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (days.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Henüz günlük plan yok.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.map_outlined),
        title: Text(
          'Program (${days.length} gün)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          for (var i = 0; i < days.length; i++)
            ListTile(
              title: Text(
                days[i]['title'] as String? ?? 'Gün ${i + 1}',
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                _itemsLine(days[i]['items']),
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  static String _itemsLine(dynamic items) {
    if (items is! List) return '';
    return items.map((e) => e.toString()).join(' · ');
  }
}

class BudgetWarningWidget extends StatelessWidget {
  const BudgetWarningWidget({
    super.key,
    required this.current,
    required this.limit,
  });

  final String current;
  final String limit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
        title: Text(
          'Uyarı',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onErrorContainer,
          ),
        ),
        subtitle: Text(
          'Güncel: $current   Limit: $limit',
          style: TextStyle(color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.details});

  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (details.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Rezervasyon bilgisi yok.', style: theme.textTheme.bodyMedium),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rezervasyon',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...details.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        e.key,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Text(e.value.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}