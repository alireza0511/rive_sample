import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Rive number properties don't carry a range at runtime, so the sliders use
/// this default. Override per animation with [RiveAnimationItem.numberRange]
/// when a file expects something else.
const defaultNumberRange = (min: 0.0, max: 100.0);

/// A data-bound view model property, paired with the widget that can drive it.
sealed class BoundProperty {
  const BoundProperty(this.name);

  /// Full slash-separated path, e.g. `Slider/CurrentPos`.
  final String name;
}

/// The nested view model a property belongs to, or `''` when it sits at the
/// root — `Slider/CurrentPos` → `Slider`.
String propertyGroup(String path) {
  final index = path.lastIndexOf('/');
  return index < 0 ? '' : path.substring(0, index);
}

/// The property's leaf name — `Slider/CurrentPos` → `CurrentPos`.
String propertyLabel(String path) {
  final index = path.lastIndexOf('/');
  return index < 0 ? path : path.substring(index + 1);
}

/// Splits [properties] into group headers and rows, in order.
List<({String? header, BoundProperty? property})> groupProperties(
  List<BoundProperty> properties,
) {
  final rows = <({String? header, BoundProperty? property})>[];
  var group = '';
  for (final property in properties) {
    final next = propertyGroup(property.name);
    if (next != group) {
      group = next;
      if (group.isNotEmpty) rows.add((header: group, property: null));
    }
    rows.add((header: null, property: property));
  }
  return rows;
}

/// Current value of [bound], formatted for display.
String describeValue(BoundProperty bound) => switch (bound) {
  BoundNumber() => bound.property.value.toStringAsFixed(2),
  BoundBoolean() => '${bound.property.value}',
  BoundString() => '"${bound.property.value}"',
  BoundEnum() => bound.property.value,
  BoundColor() =>
    '#${bound.property.value.toARGB32().toRadixString(16).padLeft(8, '0')}',
  // Triggers are momentary: they carry no readable state.
  BoundTrigger() => '—',
};

class BoundNumber extends BoundProperty {
  const BoundNumber(super.name, this.property);
  final rive.ViewModelInstanceNumber property;
}

class BoundBoolean extends BoundProperty {
  const BoundBoolean(super.name, this.property);
  final rive.ViewModelInstanceBoolean property;
}

class BoundString extends BoundProperty {
  const BoundString(super.name, this.property);
  final rive.ViewModelInstanceString property;
}

class BoundTrigger extends BoundProperty {
  const BoundTrigger(super.name, this.property);
  final rive.ViewModelInstanceTrigger property;
}

class BoundEnum extends BoundProperty {
  const BoundEnum(super.name, this.property);
  final rive.ViewModelInstanceEnum property;
}

class BoundColor extends BoundProperty {
  const BoundColor(super.name, this.property);
  final rive.ViewModelInstanceColor property;
}

/// Auto-generated controls for the bound view model.
///
/// Several marketplace files (mood-interaction among them) expose no
/// hit-testable elements — the whole interaction is driven by data binding, so
/// without these controls there is nothing to interact with and nothing to log.
class RiveControlsView extends StatefulWidget {
  const RiveControlsView({
    super.key,
    required this.properties,
    required this.rangeFor,
    required this.onChanged,
  });

  final List<BoundProperty> properties;

  /// Slider bounds for a number property, looked up by its full path.
  final ({double min, double max}) Function(String path) rangeFor;

  /// Called after a control writes to a property, so the host can rebuild.
  final VoidCallback onChanged;

  @override
  State<RiveControlsView> createState() => _RiveControlsViewState();
}

class _RiveControlsViewState extends State<RiveControlsView> {
  final _textControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _textControllerFor(BoundString bound) =>
      _textControllers.putIfAbsent(
        bound.name,
        () => TextEditingController(text: bound.property.value),
      );

  void _write(VoidCallback change) {
    change();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.properties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'This animation has no data-bound properties.\n'
            'Interact with it directly above.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Nested view models produce paths like `Slider/CurrentPos`; group the
    // controls by that prefix and label each row with the leaf name.
    final rows = groupProperties(widget.properties);

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
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }
        final bound = row.property!;
        final label = propertyLabel(bound.name);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: switch (bound) {
            BoundNumber() => _numberControl(bound, label, theme),
            BoundBoolean() => _booleanControl(bound, label),
            BoundTrigger() => _triggerControl(bound, label),
            BoundString() => _stringControl(bound, label),
            BoundEnum() => _readOnly(label, bound.property.value, theme),
            BoundColor() => _readOnly(
              label,
              '#${bound.property.value.toARGB32().toRadixString(16).padLeft(8, '0')}',
              theme,
            ),
          },
        );
      },
    );
  }


  Widget _numberControl(BoundNumber bound, String label, ThemeData theme) {
    final range = widget.rangeFor(bound.name);
    final value = bound.property.value.clamp(range.min, range.max);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: range.min,
            max: range.max,
            onChanged: (next) => _write(() => bound.property.value = next),
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _booleanControl(BoundBoolean bound, String label) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: bound.property.value,
    onChanged: (next) => _write(() => bound.property.value = next),
  );

  Widget _triggerControl(BoundTrigger bound, String label) => Row(
    children: [
      Expanded(child: Text(label)),
      FilledButton.tonal(
        onPressed: () => _write(bound.property.trigger),
        child: const Text('Fire'),
      ),
    ],
  );

  Widget _stringControl(BoundString bound, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextField(
      controller: _textControllerFor(bound),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (next) => _write(() => bound.property.value = next),
    ),
  );

  Widget _readOnly(String name, String value, ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(name, style: theme.textTheme.bodySmall)),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    ),
  );
}
