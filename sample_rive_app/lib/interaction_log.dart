import 'package:flutter/material.dart';

enum LogKind { riveEvent, dataBind, info }

Color _colorFor(LogKind kind, ColorScheme scheme) => switch (kind) {
  LogKind.riveEvent => scheme.tertiary,
  LogKind.dataBind => scheme.secondary,
  LogKind.info => scheme.onSurfaceVariant,
};

IconData _iconFor(LogKind kind) => switch (kind) {
  LogKind.riveEvent => Icons.bolt_outlined,
  LogKind.dataBind => Icons.tune_outlined,
  LogKind.info => Icons.info_outline,
};

class LogEntry {
  LogEntry({
    required this.kind,
    required this.message,
    this.details,
    this.coalesceKey,
    this.count = 1,
  }) : time = DateTime.now();

  final DateTime time;
  final LogKind kind;
  final String message;
  final String? details;

  /// Consecutive entries sharing a non-null key collapse into one row with a
  /// repeat [count] — keeps a drag from flooding the log with one line per
  /// frame.
  final String? coalesceKey;
  final int count;

  String get formattedTime {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

/// Scrollable log panel shown below the animation.
///
/// [entries] is newest-first; the list is rendered in reverse so the newest
/// entry sits at the bottom and stays in view, like a terminal.
class InteractionLogView extends StatelessWidget {
  const InteractionLogView({
    super.key,
    required this.entries,
    required this.onClear,
  });

  final List<LogEntry> entries;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Text('Interaction log', style: theme.textTheme.titleSmall),
              const SizedBox(width: 8),
              Text(
                '(${entries.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: entries.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear log',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'Interact with the animation above',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      _LogRow(entry: entries[index]),
                ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _colorFor(entry.kind, scheme);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(entry.kind), size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            entry.formattedTime,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (entry.count > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '×${entry.count}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.details != null)
                  Text(
                    entry.details!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
