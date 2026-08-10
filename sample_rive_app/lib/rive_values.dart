import 'package:flutter/material.dart';

import 'rive_controls.dart';

/// Live, read-only view of every data-bound property.
///
/// The read side of data binding: the Controls tab writes values into the
/// animation, this shows what the animation currently holds. Interacting with
/// the artboard directly (clicking a button, opening the dropdown) updates
/// these values without any control being touched, which is the quickest way
/// to check that interaction and data binding agree.
class RiveValuesView extends StatelessWidget {
  const RiveValuesView({super.key, required this.properties});

  final List<BoundProperty> properties;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (properties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'This animation has no data-bound properties.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final rows = groupProperties(properties);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final header = row.header;
        if (header != null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              header,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
          );
        }

        final bound = row.property!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  propertyLabel(bound.name),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                describeValue(bound),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
