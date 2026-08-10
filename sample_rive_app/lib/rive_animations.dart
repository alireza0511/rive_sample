import 'rive_controls.dart';

/// Inclusive slider bounds for a data-bound number property.
typedef NumberRange = ({double min, double max});

/// A single Rive animation entry shown in the list.
class RiveAnimationItem {
  const RiveAnimationItem({
    required this.title,
    required this.asset,
    this.description,
    this.numberRange = defaultNumberRange,
    this.numberRanges = const {},
  });

  final String title;
  final String asset;
  final String? description;

  /// Fallback slider range for this file's data-bound number properties. Rive
  /// does not expose a property's range at runtime, so it is declared here.
  final NumberRange numberRange;

  /// Per-property slider ranges, keyed by the property's full path (e.g.
  /// `Slider/CurrentPos`). Takes precedence over [numberRange].
  final Map<String, NumberRange> numberRanges;

  NumberRange rangeFor(String path) => numberRanges[path] ?? numberRange;
}

/// Add new animations here — drop the `.riv` file in `assets/`, register it in
/// `pubspec.yaml`, then add an entry below.
const riveAnimations = <RiveAnimationItem>[
  RiveAnimationItem(
    title: 'X Repost Redesign',
    asset: 'assets/x-repost-redesign.riv',
    description: 'Repost button interaction',
  ),

  RiveAnimationItem(
    title: 'Auto Wrapping Pill Menu',
    asset: 'assets/auto-wrapping-pill-menu.riv',
    description: 'Menu with auto-wrapping pills',
  ),
  RiveAnimationItem(
    title: 'Mood Interaction',
    asset: 'assets/mood-interaction.riv',
    description: 'Mood driven by the bound "Number 1" property',
  ),
  RiveAnimationItem(
    title: 'UI Starter Kit',
    asset: 'assets/ui-starter-kit.riv',
    description: 'A collection of UI components',
    // The kit's slider component reports MinPos 8 / MaxPos 192.
    numberRanges: {'Slider/CurrentPos': (min: 8, max: 192)},
  ),
];
