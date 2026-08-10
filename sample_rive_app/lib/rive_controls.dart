import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Rive number properties don't carry a range at runtime, so the sliders use
/// this default. Override per animation with [RiveAnimationItem.numberRange]
/// when a file expects something else.
const defaultNumberRange = (min: 0.0, max: 100.0);

/// A data-bound view model property, paired with the widget that can drive it.
sealed class BoundProperty {
  const BoundProperty(this.name);
  final String name;
}

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
    required this.numberRange,
    required this.onChanged,
  });

  final List<BoundProperty> properties;
  final ({double min, double max}) numberRange;

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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.properties.length,
      itemBuilder: (context, index) {
        final bound = widget.properties[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: switch (bound) {
            BoundNumber() => _numberControl(bound, theme),
            BoundBoolean() => _booleanControl(bound),
            BoundTrigger() => _triggerControl(bound),
            BoundString() => _stringControl(bound),
            BoundEnum() => _readOnly(bound.name, bound.property.value, theme),
            BoundColor() => _readOnly(
              bound.name,
              '#${bound.property.value.toARGB32().toRadixString(16).padLeft(8, '0')}',
              theme,
            ),
          },
        );
      },
    );
  }

  Widget _numberControl(BoundNumber bound, ThemeData theme) {
    final value = bound.property.value.clamp(
      widget.numberRange.min,
      widget.numberRange.max,
    );
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(bound.name, style: theme.textTheme.bodySmall),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: widget.numberRange.min,
            max: widget.numberRange.max,
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

  Widget _booleanControl(BoundBoolean bound) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(bound.name),
    value: bound.property.value,
    onChanged: (next) => _write(() => bound.property.value = next),
  );

  Widget _triggerControl(BoundTrigger bound) => Row(
    children: [
      Expanded(child: Text(bound.name)),
      FilledButton.tonal(
        onPressed: () => _write(bound.property.trigger),
        child: const Text('Fire'),
      ),
    ],
  );

  Widget _stringControl(BoundString bound) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextField(
      controller: _textControllerFor(bound),
      decoration: InputDecoration(
        labelText: bound.name,
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
