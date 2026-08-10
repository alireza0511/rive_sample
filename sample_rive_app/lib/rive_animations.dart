import 'rive_controls.dart';

/// A single Rive animation entry shown in the list.
class RiveAnimationItem {
  const RiveAnimationItem({
    required this.title,
    required this.asset,
    this.description,
    this.numberRange = defaultNumberRange,
  });

  final String title;
  final String asset;
  final String? description;

  /// Slider range used for this file's data-bound number properties. Rive does
  /// not expose a property's range at runtime, so it is declared here.
  final ({double min, double max}) numberRange;
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
];
