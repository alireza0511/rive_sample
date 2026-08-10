import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'interaction_log.dart';
import 'rive_animations.dart';
import 'rive_controls.dart';
import 'rive_values.dart';

/// Newest entries are kept at index 0; older ones are dropped past this cap.
const _maxLogEntries = 200;

class AnimationDetailScreen extends StatefulWidget {
  const AnimationDetailScreen({super.key, required this.item, this.riveFactory});

  final RiveAnimationItem item;

  /// Defaults to the Rive renderer. Widget tests override this with
  /// [rive.Factory.flutter]; the Rive renderer cannot initialise in the
  /// headless test shell.
  final rive.Factory? riveFactory;

  @override
  State<AnimationDetailScreen> createState() => _AnimationDetailScreenState();
}

class _AnimationDetailScreenState extends State<AnimationDetailScreen> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModelInstance;
  Object? _error;

  /// Data-bound properties exposed as controls, and the listeners that log
  /// their changes.
  final _boundProperties = <BoundProperty>[];
  final _propertyListenerRemovers = <VoidCallback>[];

  final _log = <LogEntry>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await rive.File.asset(
        widget.item.asset,
        riveFactory: widget.riveFactory ?? rive.Factory.rive,
      );
      if (file == null) {
        throw StateError('Could not load ${widget.item.asset}');
      }
      if (!mounted) {
        file.dispose();
        return;
      }
      final controller = rive.RiveWidgetController(file);
      controller.stateMachine.addEventListener(_onRiveEvent);

      // Not every file exposes a view model (x-repost-redesign does not), so a
      // failed auto-bind is expected rather than fatal.
      rive.ViewModelInstance? viewModelInstance;
      String? bindError;
      try {
        viewModelInstance = controller.dataBind(rive.DataBind.auto());
      } on rive.RiveException catch (error) {
        bindError = error.message;
      }

      setState(() {
        _file = file;
        _controller = controller;
        _viewModelInstance = viewModelInstance;
      });

      _add(
        LogKind.info,
        'Loaded ${widget.item.title}',
        details:
            'artboard "${controller.artboard.name}" · '
            'state machine "${controller.stateMachine.name}"',
      );

      if (viewModelInstance != null) {
        _bindProperties(viewModelInstance);
      } else {
        _add(
          LogKind.info,
          'No data binding',
          details: bindError ?? 'This file exposes no view model.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Rive failed to load ${widget.item.asset}: $error');
      debugPrint('$stackTrace');
      if (mounted) setState(() => _error = error);
    }
  }

  /// Collects every observable property on the bound view model, logs each
  /// value change, and exposes it as a control in the Controls tab.
  ///
  /// Nested view models are walked recursively — the UI Starter Kit's root view
  /// model holds nothing but nested components, so a flat pass would find no
  /// properties at all. Leaves are resolved from [root] by their full
  /// slash-separated path, which is also how they are labelled.
  void _bindProperties(rive.ViewModelInstance root) {
    void listen<T>(
      String path,
      rive.ViewModelInstanceObservableValue<T>? property,
      String Function(T value) format,
      BoundProperty Function() bind,
    ) {
      if (property == null) return;
      void listener(T value) => _add(
        LogKind.dataBind,
        path,
        details: format(value),
        coalesceKey: 'property:$path',
      );
      property.addListener(listener);
      _propertyListenerRemovers.add(() => property.removeListener(listener));
      _boundProperties.add(bind());
    }

    void walk(rive.ViewModelInstance instance, String prefix, int depth) {
      // Guards against a view model that (directly or indirectly) contains
      // itself.
      if (depth > 5) return;

      for (final property in instance.properties) {
        final path = '$prefix${property.name}';
        switch (property.type) {
          case rive.DataType.viewModel:
            final nested = instance.viewModel(property.name);
            if (nested != null) walk(nested, '$path/', depth + 1);
          case rive.DataType.number:
            final p = root.number(path);
            listen(path, p, (v) => v.toStringAsFixed(2), () => BoundNumber(path, p!));
          case rive.DataType.boolean:
            final p = root.boolean(path);
            listen(path, p, (v) => '$v', () => BoundBoolean(path, p!));
          case rive.DataType.string:
            final p = root.string(path);
            listen(path, p, (v) => '"$v"', () => BoundString(path, p!));
          case rive.DataType.enumType:
            final p = root.enumerator(path);
            listen(path, p, (v) => v, () => BoundEnum(path, p!));
          case rive.DataType.color:
            final p = root.color(path);
            listen(
              path,
              p,
              (v) => '#${v.toARGB32().toRadixString(16).padLeft(8, '0')}',
              () => BoundColor(path, p!),
            );
          case rive.DataType.trigger:
            final p = root.trigger(path);
            listen(path, p, (_) => 'fired', () => BoundTrigger(path, p!));
          default:
            // Lists, images, artboards: not logged.
            break;
        }
      }
    }

    walk(root, '', 0);

    final count = _boundProperties.length;
    _add(
      LogKind.info,
      'Watching $count bound propert${count == 1 ? 'y' : 'ies'}',
      details: count == 0
          ? null
          : _boundProperties.map((p) => p.name).join(', '),
    );
  }

  @override
  void dispose() {
    for (final remove in _propertyListenerRemovers) {
      remove();
    }
    _controller?.stateMachine.removeEventListener(_onRiveEvent);
    _viewModelInstance?.dispose();
    // The controller owns and disposes the artboard and state machine.
    _controller?.dispose();
    _file?.dispose();
    super.dispose();
  }

  void _add(
    LogKind kind,
    String message, {
    String? details,
    String? coalesceKey,
  }) {
    if (!mounted) return;
    setState(() {
      final newest = _log.isEmpty ? null : _log.first;
      if (coalesceKey != null && newest?.coalesceKey == coalesceKey) {
        _log[0] = LogEntry(
          kind: kind,
          message: message,
          details: details,
          coalesceKey: coalesceKey,
          count: newest!.count + 1,
        );
        return;
      }
      _log.insert(
        0,
        LogEntry(
          kind: kind,
          message: message,
          details: details,
          coalesceKey: coalesceKey,
        ),
      );
      if (_log.length > _maxLogEntries) _log.removeLast();
    });
  }

  void _onRiveEvent(rive.Event event) {
    final properties = event.properties.entries
        .map((entry) => '${entry.key}: ${entry.value.value}')
        .join(', ');
    _add(
      LogKind.riveEvent,
      'Rive event "${event.name}"',
      details: [
        'type: ${event.type.name}',
        if (properties.isNotEmpty) properties,
      ].join(' · '),
    );
  }

  Widget _buildAnimation() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $_error', textAlign: TextAlign.center),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return rive.RiveWidget(controller: controller, fit: rive.Fit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.item.title)),
        // Fixed flex split: the animation and the bottom panel each get a share
        // of the available height, so neither can overflow on a short screen.
        body: Column(
          children: [
            Expanded(flex: 3, child: _buildAnimation()),
            const Divider(height: 1),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  TabBar(
                    // Scrollable so three labels never overflow a narrow phone.
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    tabs: [
                      Tab(text: 'Log (${_log.length})'),
                      Tab(text: 'Controls (${_boundProperties.length})'),
                      Tab(text: 'Values (${_boundProperties.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        InteractionLogView(
                          entries: _log,
                          onClear: () => setState(_log.clear),
                        ),
                        RiveControlsView(
                          properties: _boundProperties,
                          rangeFor: widget.item.rangeFor,
                          onChanged: () {},
                        ),
                        RiveValuesView(properties: _boundProperties),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
