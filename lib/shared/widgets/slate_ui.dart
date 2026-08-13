import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';

class SlateTheme {
  const SlateTheme._();

  static WorkloopThemeTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<WorkloopThemeTokens>() ??
        (theme.brightness == Brightness.light
            ? WorkloopThemeTokens.light
            : WorkloopThemeTokens.dark);
  }
}

/// Pops a routed detail screen when possible and otherwise returns to the
/// authenticated home route. This keeps top-level deep links from leaving a
/// back control that silently does nothing.
void workloopGoBack(BuildContext context, {String fallbackLocation = '/home'}) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  context.go(fallbackLocation);
}

class SlateHaptics {
  const SlateHaptics._();

  static void _safe(Future<void> Function() feedback) {
    unawaited(
      Future<void>.sync(feedback).catchError((Object _, StackTrace _) {}),
    );
  }

  static void selection() => _safe(HapticFeedback.selectionClick);
  static void light() => _safe(HapticFeedback.lightImpact);
  static void success() => _safe(HapticFeedback.mediumImpact);
  static void warning() => _safe(HapticFeedback.heavyImpact);
  static void destructive() => _safe(HapticFeedback.heavyImpact);

  // Compatibility aliases keep existing interactions routed through this one
  // restrained service while call sites migrate to semantic names.
  static void tap() => selection();
  static void action() => light();
  static void confirm() => success();
}

enum WorkloopDraftDecision { stay, discard, save }

Future<DateTime?> showWorkloopDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Choose date',
  TransitionBuilder? builder,
}) async {
  var selected = initialDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Builder(
              builder: (context) {
                final calendar = CalendarDatePicker(
                  initialDate: selected,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onDateChanged: (value) {
                    SlateHaptics.selection();
                    setSheetState(() => selected = value);
                  },
                );
                return builder?.call(context, calendar) ?? calendar;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: WorkloopPrimaryButton(
                    label: 'Cancel',
                    secondary: true,
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: WorkloopPrimaryButton(
                    label: 'Use date',
                    onPressed: () {
                      SlateHaptics.success();
                      Navigator.pop(sheetContext, selected);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<TimeOfDay?> showWorkloopTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String title = 'Choose time',
}) async {
  var selected = initialTime;
  final initialDateTime = DateTime(
    2000,
    1,
    1,
    initialTime.hour,
    initialTime.minute,
  );
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (sheetContext) => SlateSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 190,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: initialDateTime,
              use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
              onDateTimeChanged: (value) {
                selected = TimeOfDay(hour: value.hour, minute: value.minute);
                SlateHaptics.selection();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: WorkloopPrimaryButton(
                  label: 'Cancel',
                  secondary: true,
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: WorkloopPrimaryButton(
                  label: 'Use time',
                  onPressed: () {
                    SlateHaptics.success();
                    Navigator.pop(sheetContext, selected);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<WorkloopDraftDecision> showWorkloopDraftConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String saveLabel = 'Save changes',
  bool canSave = true,
}) async {
  final result = await showModalBottomSheet<WorkloopDraftDecision>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (sheetContext) => SlateSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SlateButton(
            label: saveLabel,
            icon: LucideIcons.check,
            onPressed: canSave
                ? () => Navigator.pop(sheetContext, WorkloopDraftDecision.save)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          SlateButton(
            label: 'Keep editing',
            secondary: true,
            onPressed: () =>
                Navigator.pop(sheetContext, WorkloopDraftDecision.stay),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.pop(sheetContext, WorkloopDraftDecision.discard),
              child: const Text(
                'Discard changes',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? WorkloopDraftDecision.stay;
}

Future<bool> showWorkloopOutsideHoursConfirmation(
  BuildContext context, {
  required String detail,
  bool repeating = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: SlateTheme.of(context).scrim,
    builder: (sheetContext) => SlateSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outside working hours',
            style: TextStyle(
              color: AppColors.t1,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            repeating
                ? '$detail At least one booking in this repeat schedule is outside your saved hours. You can still create it.'
                : '$detail You can still create this booking.',
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SlateButton(
            label: 'Book anyway',
            icon: LucideIcons.calendarCheck,
            onPressed: () => Navigator.pop(sheetContext, true),
          ),
          const SizedBox(height: AppSpacing.sm),
          SlateButton(
            label: 'Go back',
            secondary: true,
            onPressed: () => Navigator.pop(sheetContext, false),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Applies Workloop's tap-away keyboard behaviour to every editable field.
///
/// Flutter intentionally keeps the keyboard open for touch taps outside an
/// [EditableText] on mobile. Overriding the standard intent here preserves the
/// field's own tap region while making the rest of the app dismiss focus.
class WorkloopKeyboardDismissRegion extends StatelessWidget {
  final Widget child;

  const WorkloopKeyboardDismissRegion({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: (intent) {
                intent.focusNode.unfocus();
                return null;
              },
            ),
      },
      child: child,
    );
  }
}

/// Tracks the route currently presented by Workloop's root navigator.
///
/// [WorkloopNavigationAssistRegion] uses route identity to target only the
/// visible screen and to avoid a second pop when Flutter's native iOS gesture
/// has already completed.
class WorkloopNavigationObserver extends NavigatorObserver {
  Route<dynamic>? topRoute;

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    this.topRoute = topRoute;
    super.didChangeTop(topRoute, previousTopRoute);
  }
}

/// Ensures every vertical [Scrollable] participates in Workloop's app-wide
/// navigation shortcuts, including scroll views that own an implicit
/// controller rather than inheriting a [PrimaryScrollController].
class WorkloopScrollBehavior extends MaterialScrollBehavior {
  const WorkloopScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final decorated = super.buildScrollbar(context, child, details);
    final controller = details.controller;
    if (axisDirectionToAxis(details.direction) != Axis.vertical ||
        controller == null) {
      return decorated;
    }
    return _WorkloopScrollRegistration(
      controller: controller,
      child: decorated,
    );
  }
}

/// Identifies retained shell destinations that share the same modal route.
///
/// Main-shell tabs live in an [IndexedStack], so route identity alone cannot
/// distinguish the visible tab from an offstage tab when choosing which scroll
/// position should return to the top.
class WorkloopNavigationScope extends InheritedWidget {
  final Object id;

  const WorkloopNavigationScope({
    super.key,
    required this.id,
    required super.child,
  });

  static Object? maybeId(BuildContext context) {
    return context.getInheritedWidgetOfExactType<WorkloopNavigationScope>()?.id;
  }

  @override
  bool updateShouldNotify(WorkloopNavigationScope oldWidget) {
    return id != oldWidget.id;
  }
}

/// Adds Workloop's app-wide navigation shortcuts without replacing native
/// platform navigation.
///
/// A short tap in the status/top-edge area returns the visible vertical
/// scrollable to its beginning. On iOS, clean routes first use Flutter's native
/// Cupertino gesture; a deliberate right swipe from the left edge falls back
/// to the route's existing back decision only if that gesture has not changed
/// the route. Draft-protected screens therefore keep their existing
/// Save/Discard/Keep editing prompt.
class WorkloopNavigationAssistRegion extends StatefulWidget {
  final WorkloopNavigationObserver observer;
  final Widget child;

  const WorkloopNavigationAssistRegion({
    super.key,
    required this.observer,
    required this.child,
  });

  static void activateScope(
    BuildContext context,
    Object id, {
    ScrollController? controller,
  }) {
    context
        .getInheritedWidgetOfExactType<_WorkloopNavigationAssistScope>()
        ?.state
        .activateScope(id, ModalRoute.of(context), controller);
  }

  static void registerScrollController(
    BuildContext context,
    ScrollController controller,
  ) {
    final state = context
        .getInheritedWidgetOfExactType<_WorkloopNavigationAssistScope>()
        ?.state;
    if (state == null) return;
    state.registerScrollController(
      controller,
      ModalRoute.of(context),
      WorkloopNavigationScope.maybeId(context),
    );
  }

  static void registerBackAction(
    BuildContext context,
    Object registration,
    VoidCallback action,
  ) {
    context
        .getInheritedWidgetOfExactType<_WorkloopNavigationAssistScope>()
        ?.state
        .registerBackAction(registration, action, ModalRoute.of(context));
  }

  static void unregisterBackAction(BuildContext context, Object registration) {
    context
        .getInheritedWidgetOfExactType<_WorkloopNavigationAssistScope>()
        ?.state
        .unregisterBackAction(registration);
  }

  @override
  State<WorkloopNavigationAssistRegion> createState() =>
      _WorkloopNavigationAssistRegionState();
}

class _WorkloopNavigationAssistRegionState
    extends State<WorkloopNavigationAssistRegion> {
  static const _nativeNavigationChannel = MethodChannel(
    'com.ismaeel.workloop/navigation',
  );
  final Map<Route<dynamic>, Set<ScrollController>> _routeControllers = {};
  final Map<Object, Set<ScrollController>> _scopedControllers = {};
  final Map<Object, _WorkloopScrollTarget> _scrollRegistrations = {};
  final Map<Object, _WorkloopBackAction> _backActions = {};
  Object? _activeScope;
  Route<dynamic>? _activeScopeRoute;
  int? _pointer;
  Offset? _pointerDown;
  DateTime? _pointerDownAt;
  Route<dynamic>? _backSwipeRoute;

  @override
  void initState() {
    super.initState();
    _nativeNavigationChannel.setMethodCallHandler(_handleNativeNavigation);
  }

  @override
  void dispose() {
    _nativeNavigationChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleNativeNavigation(MethodCall call) async {
    if (call.method == 'scrollToTop' && mounted) {
      _scrollVisiblePositionsToTop();
    }
  }

  void activateScope(
    Object id,
    Route<dynamic>? route,
    ScrollController? controller,
  ) {
    _activeScope = id;
    _activeScopeRoute = route;
    if (controller != null) {
      _scopedControllers.putIfAbsent(id, () => {}).add(controller);
    }
  }

  void registerScrollController(
    ScrollController controller,
    Route<dynamic>? route,
    Object? scopeId,
  ) {
    if (route == null) return;
    if (scopeId == null) {
      _routeControllers.putIfAbsent(route, () => {}).add(controller);
    } else {
      _scopedControllers.putIfAbsent(scopeId, () => {}).add(controller);
    }
  }

  void registerScrollable(
    Object registration,
    ScrollController controller,
    Route<dynamic>? route,
    Object? scopeId,
    bool Function() isVisible,
  ) {
    unregisterScrollable(registration);
    if (route == null) return;
    _scrollRegistrations[registration] = _WorkloopScrollTarget(
      controller: controller,
      route: route,
      scopeId: scopeId,
      isVisible: isVisible,
    );
    registerScrollController(controller, route, scopeId);
  }

  void unregisterScrollable(Object registration) {
    final target = _scrollRegistrations.remove(registration);
    if (target == null) return;
    final controllers = target.scopeId == null
        ? _routeControllers[target.route]
        : _scopedControllers[target.scopeId];
    final stillRegistered = _scrollRegistrations.values.any(
      (candidate) =>
          identical(candidate.controller, target.controller) &&
          identical(candidate.route, target.route) &&
          candidate.scopeId == target.scopeId,
    );
    if (!stillRegistered) controllers?.remove(target.controller);
    if (controllers?.isEmpty ?? false) {
      if (target.scopeId == null) {
        _routeControllers.remove(target.route);
      } else {
        _scopedControllers.remove(target.scopeId);
      }
    }
  }

  void registerBackAction(
    Object registration,
    VoidCallback action,
    Route<dynamic>? route,
  ) {
    if (route == null) return;
    _backActions[registration] = _WorkloopBackAction(
      route: route,
      action: action,
    );
  }

  void unregisterBackAction(Object registration) {
    _backActions.remove(registration);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _pointerDown = event.position;
    _pointerDownAt = DateTime.now();

    final route = widget.observer.topRoute;
    final iosBackCandidate =
        Theme.of(context).platform == TargetPlatform.iOS &&
        event.position.dx <= AppSpacing.minTouch &&
        route is PageRoute<dynamic> &&
        !route.popGestureEnabled &&
        (_backActionFor(route) != null ||
            widget.observer.navigator?.canPop() == true);
    _backSwipeRoute = iosBackCandidate ? route : null;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // Clean routes are owned by Flutter's native Cupertino gesture. Fallback
    // routes deliberately wait for pointer-up so a cancelled drag never
    // navigates or opens a draft decision while the user's finger is moving.
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final start = _pointerDown;
    final startedAt = _pointerDownAt;
    final swipeRoute = _backSwipeRoute;
    _resetPointer();
    if (start == null || startedAt == null) return;

    final delta = event.position - start;
    final elapsed = DateTime.now().difference(startedAt);
    final backSwipe =
        swipeRoute != null &&
        identical(swipeRoute, widget.observer.topRoute) &&
        _isBackSwipe(delta, elapsed);
    if (backSwipe) {
      unawaited(_completeBackSwipe(swipeRoute));
    }
  }

  bool _isBackSwipe(Offset delta, Duration elapsed) {
    return delta.dx >= 56 &&
        delta.dy.abs() <= 72 &&
        delta.dx > delta.dy.abs() * 1.25 &&
        elapsed <= const Duration(milliseconds: 1300);
  }

  void _handleTopTap(TapUpDetails details) {
    final topTapExtent = MediaQuery.paddingOf(context).top + 72;
    if (details.globalPosition.dy <= topTapExtent) {
      _scrollVisiblePositionsToTop();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _resetPointer();
  }

  void _resetPointer() {
    _pointer = null;
    _pointerDown = null;
    _pointerDownAt = null;
    _backSwipeRoute = null;
  }

  void _scrollVisiblePositionsToTop() {
    final route = widget.observer.topRoute;
    if (route == null) return;
    final activeScope = identical(route, _activeScopeRoute)
        ? _activeScope
        : null;
    final visibleControllers = _scrollRegistrations.values
        .where(
          (target) =>
              identical(target.route, route) &&
              (activeScope == null
                  ? target.scopeId == null
                  : target.scopeId == activeScope) &&
              target.isVisible(),
        )
        .map((target) => target.controller)
        .toSet();
    if (visibleControllers.isEmpty) {
      visibleControllers.addAll(
        activeScope == null
            ? _routeControllers[route] ?? const <ScrollController>{}
            : _scopedControllers[activeScope] ?? const <ScrollController>{},
      );
    }
    if (visibleControllers.isEmpty && route is ModalRoute<dynamic>) {
      final routeContext = route.subtreeContext;
      if (routeContext != null) {
        final primary = PrimaryScrollController.maybeOf(routeContext);
        if (primary != null) visibleControllers.add(primary);
      }
    }
    for (final controller in visibleControllers) {
      if (!controller.hasClients) continue;
      final positions = controller.positions
          .where(
            (position) =>
                position.context.storageContext.mounted &&
                position.hasPixels &&
                position.hasContentDimensions &&
                position.pixels > position.minScrollExtent + 0.5,
          )
          .toList(growable: false);
      for (final position in positions) {
        if (MediaQuery.disableAnimationsOf(context)) {
          position.jumpTo(position.minScrollExtent);
        } else {
          final distance = (position.pixels - position.minScrollExtent).abs();
          final durationMs = (220 + (distance / 12)).round().clamp(220, 600);
          unawaited(
            position
                .animateTo(
                  position.minScrollExtent,
                  duration: Duration(milliseconds: durationMs),
                  curve: AppMotion.curve,
                )
                .catchError((Object _, StackTrace _) {}),
          );
        }
      }
    }
  }

  _WorkloopBackAction? _backActionFor(Route<dynamic> route) {
    for (final action in _backActions.values.toList(growable: false).reversed) {
      if (identical(action.route, route)) return action;
    }
    return null;
  }

  Future<void> _completeBackSwipe(Route<dynamic> route) async {
    final navigator = widget.observer.navigator;
    if (navigator == null) return;

    // Give Flutter's native Cupertino gesture first refusal. If it completes,
    // route identity changes. If it cancels after crossing Workloop's
    // deliberate threshold, continue with the same registered back action.
    await WidgetsBinding.instance.endOfFrame;
    final nativeGestureDeadline = DateTime.now().add(
      const Duration(seconds: 3),
    );
    while (mounted &&
        identical(route, widget.observer.topRoute) &&
        navigator.userGestureInProgress &&
        DateTime.now().isBefore(nativeGestureDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
    if (!mounted ||
        !identical(route, widget.observer.topRoute) ||
        navigator.userGestureInProgress) {
      return;
    }

    SlateHaptics.selection();
    final registeredAction = _backActionFor(route);
    if (registeredAction != null) {
      registeredAction.action();
      return;
    }
    await navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return _WorkloopNavigationAssistScope(
      state: this,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: _handleTopTap,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: widget.child,
        ),
      ),
    );
  }
}

class _WorkloopScrollTarget {
  final ScrollController controller;
  final Route<dynamic> route;
  final Object? scopeId;
  final bool Function() isVisible;

  const _WorkloopScrollTarget({
    required this.controller,
    required this.route,
    required this.scopeId,
    required this.isVisible,
  });
}

class _WorkloopBackAction {
  final Route<dynamic> route;
  final VoidCallback action;

  const _WorkloopBackAction({required this.route, required this.action});
}

class _WorkloopScrollRegistration extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const _WorkloopScrollRegistration({
    required this.controller,
    required this.child,
  });

  @override
  State<_WorkloopScrollRegistration> createState() =>
      _WorkloopScrollRegistrationState();
}

class _WorkloopScrollRegistrationState
    extends State<_WorkloopScrollRegistration> {
  _WorkloopNavigationAssistRegionState? _assist;
  Route<dynamic>? _route;
  Object? _scopeId;
  bool _tickerModeEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _register();
  }

  @override
  void didUpdateWidget(_WorkloopScrollRegistration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) _register();
  }

  void _register() {
    final assist = context
        .getInheritedWidgetOfExactType<_WorkloopNavigationAssistScope>()
        ?.state;
    final route = ModalRoute.of(context);
    final scopeId = WorkloopNavigationScope.maybeId(context);
    if (identical(_assist, assist) &&
        identical(_route, route) &&
        _scopeId == scopeId) {
      assist?.registerScrollable(
        this,
        widget.controller,
        route,
        scopeId,
        _isVisible,
      );
      return;
    }
    _assist?.unregisterScrollable(this);
    _assist = assist;
    _route = route;
    _scopeId = scopeId;
    assist?.registerScrollable(
      this,
      widget.controller,
      route,
      scopeId,
      _isVisible,
    );
  }

  bool _isVisible() {
    if (!mounted || !_tickerModeEnabled) return false;
    final renderObject = context.findRenderObject();
    if (renderObject == null ||
        !renderObject.attached ||
        renderObject.paintBounds.isEmpty) {
      return false;
    }
    final visibleRect = MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      renderObject.paintBounds,
    );
    final screenRect = Offset.zero & MediaQuery.sizeOf(context);
    if (!visibleRect.overlaps(screenRect)) return false;

    final paintedRect = visibleRect.intersect(screenRect);
    final samplePoints = <Offset>[
      paintedRect.center,
      Offset(paintedRect.center.dx, paintedRect.top + 1),
      Offset(paintedRect.center.dx, paintedRect.bottom - 1),
    ];
    return samplePoints.any((point) => _hitTestContains(renderObject, point));
  }

  bool _hitTestContains(RenderObject renderObject, Offset position) {
    final result = HitTestResult();
    RendererBinding.instance.hitTestInView(
      result,
      position,
      View.of(context).viewId,
    );
    for (final entry in result.path) {
      final target = entry.target;
      if (target is! RenderObject) continue;
      RenderObject? candidate = target;
      while (candidate != null) {
        if (identical(candidate, renderObject)) return true;
        final parent = candidate.parent;
        candidate = parent is RenderObject ? parent : null;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _assist?.unregisterScrollable(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    return widget.child;
  }
}

class _WorkloopBackActionRegistration extends StatefulWidget {
  final VoidCallback action;
  final Widget child;

  const _WorkloopBackActionRegistration({
    required this.action,
    required this.child,
  });

  @override
  State<_WorkloopBackActionRegistration> createState() =>
      _WorkloopBackActionRegistrationState();
}

class _WorkloopBackActionRegistrationState
    extends State<_WorkloopBackActionRegistration> {
  _WorkloopNavigationAssistRegionState? _assist;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _register();
  }

  @override
  void didUpdateWidget(_WorkloopBackActionRegistration oldWidget) {
    super.didUpdateWidget(oldWidget);
    _register();
  }

  void _register() {
    final assist = context
        .getInheritedWidgetOfExactType<_WorkloopNavigationAssistScope>()
        ?.state;
    if (!identical(_assist, assist)) {
      _assist?.unregisterBackAction(this);
      _assist = assist;
    }
    assist?.registerBackAction(this, widget.action, ModalRoute.of(context));
  }

  @override
  void dispose() {
    _assist?.unregisterBackAction(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _WorkloopNavigationAssistScope extends InheritedWidget {
  final _WorkloopNavigationAssistRegionState state;

  const _WorkloopNavigationAssistScope({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_WorkloopNavigationAssistScope oldWidget) {
    return !identical(state, oldWidget.state);
  }
}

class WorkloopPage extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool safeArea;
  final bool scrollable;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;

  const WorkloopPage({
    super.key,
    required this.child,
    this.padding,
    this.safeArea = true,
    this.scrollable = true,
    this.controller,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final resolvedPadding =
        padding ??
        const EdgeInsets.fromLTRB(
          AppSpacing.pageX,
          AppSpacing.screenTop,
          AppSpacing.pageX,
          AppSpacing.pageX,
        );
    Widget content = scrollable
        ? ListView(
            controller: controller,
            padding: resolvedPadding,
            children: [child],
          )
        : Padding(padding: resolvedPadding, child: child);

    if (onRefresh != null) {
      content = RefreshIndicator(
        color: tokens.accentInk,
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: tokens.background,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          Positioned.fill(child: safeArea ? SafeArea(child: content) : content),
        ],
      ),
    );
  }
}

/// The shared Workloop Studio canvas.
///
/// A pair of soft orientation fields and one curved path establish the new
/// identity without turning routine forms into illustrated screens.
class WorkloopTexturedBackdrop extends StatelessWidget {
  const WorkloopTexturedBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WorkloopTexturePainter(
            background: tokens.background,
            raised: tokens.surfaceRaised,
            accent: tokens.accent,
            secondary: AppColors.modClients,
            dark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class _WorkloopTexturePainter extends CustomPainter {
  final Color background;
  final Color raised;
  final Color accent;
  final Color secondary;
  final bool dark;

  const _WorkloopTexturePainter({
    required this.background,
    required this.raised,
    required this.accent,
    required this.secondary,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    canvas.drawCircle(
      Offset(size.width * 0.9, -20),
      size.width * 0.42,
      Paint()..color = accent.withValues(alpha: dark ? 0.035 : 0.055),
    );
    canvas.drawCircle(
      Offset(-size.width * 0.12, size.height * 0.42),
      size.width * 0.3,
      Paint()..color = secondary.withValues(alpha: dark ? 0.022 : 0.028),
    );
    final path = Path()
      ..moveTo(size.width * 0.58, 0)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.08,
        size.width * 0.78,
        size.height * 0.18,
        size.width,
        size.height * 0.2,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = raised.withValues(alpha: dark ? 0.20 : 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _WorkloopTexturePainter oldDelegate) {
    return background != oldDelegate.background ||
        raised != oldDelegate.raised ||
        accent != oldDelegate.accent ||
        secondary != oldDelegate.secondary ||
        dark != oldDelegate.dark;
  }
}

class WorkloopSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final VoidCallback? onTap;

  const WorkloopSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      padding: padding,
      color: color,
      borderColor: borderColor,
      radius: radius,
      elevated: elevated,
      onTap: onTap,
      child: child,
    );
  }
}

class WorkloopPageHeader extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final List<Widget> metrics;

  const WorkloopPageHeader({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    this.metrics = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SlateFeatureHeader(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      trailing: trailing,
      stats: metrics,
    );
  }
}

/// A retained, Cupertino-style workspace stack for destinations that live
/// inside the main shell rather than on the root [Navigator].
///
/// The active workspace follows the user's finger from the left edge while
/// the remembered workspace is revealed with restrained parallax. Releasing
/// early restores the current workspace; sufficient distance or velocity
/// completes exactly one back action.
class WorkloopInteractiveWorkspaceStack extends StatefulWidget {
  final List<Widget> children;
  final int index;
  final int? previousIndex;
  final VoidCallback onBack;

  const WorkloopInteractiveWorkspaceStack({
    super.key,
    required this.children,
    required this.index,
    required this.previousIndex,
    required this.onBack,
  });

  @override
  State<WorkloopInteractiveWorkspaceStack> createState() =>
      _WorkloopInteractiveWorkspaceStackState();
}

class _WorkloopInteractiveWorkspaceStackState
    extends State<WorkloopInteractiveWorkspaceStack>
    with TickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: AppMotion.navigation,
  );
  late final AnimationController _destinationProgress = AnimationController(
    vsync: this,
    duration: AppMotion.navigation,
    value: 1,
  )..addStatusListener(_handleDestinationStatus);
  double _availableWidth = 1;
  bool _settling = false;
  int? _outgoingIndex;
  double _destinationDirection = 1;

  bool get _canGoBack =>
      widget.previousIndex != null &&
      widget.previousIndex != widget.index &&
      widget.previousIndex! >= 0 &&
      widget.previousIndex! < widget.children.length;

  @override
  void didUpdateWidget(WorkloopInteractiveWorkspaceStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.previousIndex != widget.previousIndex) {
      final completedInteractiveBack = _settling && _progress.value >= 1;
      _progress.value = 0;
      _settling = false;
      if (oldWidget.index != widget.index && !completedInteractiveBack) {
        _outgoingIndex = oldWidget.index;
        _destinationDirection = widget.previousIndex == oldWidget.index
            ? 1
            : widget.index > oldWidget.index
            ? 1
            : -1;
        if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
          _destinationProgress.value = 1;
          _outgoingIndex = null;
        } else {
          _destinationProgress.forward(from: 0);
        }
      } else {
        _destinationProgress.value = 1;
        _outgoingIndex = null;
      }
    }
  }

  void _handleDestinationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _outgoingIndex == null) return;
    if (!mounted) return;
    setState(() => _outgoingIndex = null);
  }

  @override
  void dispose() {
    _progress.dispose();
    _destinationProgress
      ..removeStatusListener(_handleDestinationStatus)
      ..dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!_canGoBack || _settling) return;
    _progress.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_canGoBack || _settling) return;
    final delta = details.primaryDelta ?? 0;
    _progress.value = (_progress.value + (delta / _availableWidth)).clamp(
      0.0,
      1.0,
    );
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (!_canGoBack || _settling) return;
    final velocity = details.primaryVelocity ?? 0;
    final complete = _progress.value >= 0.32 || velocity >= 650;
    await _settle(complete);
  }

  Future<void> _handleDragCancel() => _settle(false);

  Future<void> _settle(bool complete) async {
    if (!_canGoBack || _settling) return;
    _settling = true;
    final target = complete ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _progress.value = target;
    } else {
      final remaining = (target - _progress.value).abs();
      await _progress.animateTo(
        target,
        duration: Duration(milliseconds: (140 + (remaining * 120)).round()),
        curve: complete ? Curves.easeOutCubic : Curves.easeOutQuart,
      );
    }
    if (!mounted) return;
    if (complete) {
      SlateHaptics.selection();
      widget.onBack();
    } else {
      _settling = false;
    }
  }

  Widget _workspaceLayer({
    required int index,
    required bool visible,
    required bool interactive,
    required bool includeSemantics,
    required bool tickerEnabled,
    double horizontalOffset = 0,
    double scale = 1,
    double opacity = 1,
    double overlayOpacity = 0,
    bool showLeadingShadow = false,
  }) {
    return Positioned.fill(
      key: ValueKey('workloop-workspace-layer-$index'),
      child: Offstage(
        offstage: !visible,
        child: TickerMode(
          enabled: tickerEnabled,
          child: ExcludeSemantics(
            excluding: !includeSemantics,
            child: IgnorePointer(
              ignoring: !interactive,
              child: Transform.translate(
                key: ValueKey('workloop-workspace-transform-$index'),
                offset: Offset(horizontalOffset, 0),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: showLeadingShadow
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 24,
                                  offset: const Offset(-8, 0),
                                ),
                              ]
                            : const [],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          widget.children[index],
                          IgnorePointer(
                            child: ColoredBox(
                              color: Colors.black.withValues(
                                alpha: overlayOpacity.clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _availableWidth = constraints.maxWidth <= 0 ? 1 : constraints.maxWidth;
        final previousIndex = _canGoBack ? widget.previousIndex : null;

        return AnimatedBuilder(
          animation: Listenable.merge([_progress, _destinationProgress]),
          builder: (context, _) {
            final outgoingIndex = _outgoingIndex;
            final changingDestination =
                outgoingIndex != null &&
                outgoingIndex != widget.index &&
                outgoingIndex >= 0 &&
                outgoingIndex < widget.children.length &&
                _destinationProgress.value < 1;
            if (changingDestination) {
              final progress = _destinationProgress.value;
              final curved = AppMotion.curve.transform(progress);
              final outgoingOpacity =
                  1 -
                  const Interval(
                    0,
                    0.55,
                    curve: Curves.easeOut,
                  ).transform(progress);
              final incomingOpacity = const Interval(
                0.12,
                1,
                curve: Curves.easeOutCubic,
              ).transform(progress);
              final layers = <Widget>[
                for (var index = 0; index < widget.children.length; index++)
                  if (index != widget.index && index != outgoingIndex)
                    _workspaceLayer(
                      index: index,
                      visible: false,
                      interactive: false,
                      includeSemantics: false,
                      tickerEnabled: false,
                    ),
                _workspaceLayer(
                  index: outgoingIndex,
                  visible: true,
                  interactive: false,
                  includeSemantics: false,
                  tickerEnabled: true,
                  horizontalOffset:
                      -_destinationDirection *
                      AppMotion.destinationOffset *
                      0.55 *
                      curved,
                  scale: 1 - (0.008 * curved),
                  opacity: outgoingOpacity,
                ),
                _workspaceLayer(
                  index: widget.index,
                  visible: true,
                  interactive: false,
                  includeSemantics: true,
                  tickerEnabled: true,
                  horizontalOffset:
                      _destinationDirection *
                      AppMotion.destinationOffset *
                      (1 - curved),
                  scale: 0.992 + (0.008 * curved),
                  opacity: incomingOpacity,
                ),
              ];
              return ClipRect(
                child: IgnorePointer(
                  ignoring: true,
                  child: ColoredBox(
                    color: SlateTheme.of(context).background,
                    child: Stack(children: layers),
                  ),
                ),
              );
            }

            final value = _progress.value;
            final layers = <Widget>[
              for (var index = 0; index < widget.children.length; index++)
                if (index != widget.index && index != previousIndex)
                  _workspaceLayer(
                    index: index,
                    visible: false,
                    interactive: false,
                    includeSemantics: false,
                    tickerEnabled: false,
                  ),
            ];

            if (previousIndex != null) {
              layers.add(
                _workspaceLayer(
                  index: previousIndex,
                  visible: true,
                  interactive: false,
                  includeSemantics: false,
                  tickerEnabled: value > 0,
                  horizontalOffset: -_availableWidth * 0.18 * (1 - value),
                  overlayOpacity: 0.16 * (1 - value),
                ),
              );
            }

            layers.add(
              _workspaceLayer(
                index: widget.index,
                visible: true,
                interactive: true,
                includeSemantics: true,
                tickerEnabled: true,
                horizontalOffset: _availableWidth * value,
                showLeadingShadow: value > 0,
              ),
            );

            if (_canGoBack) {
              layers.add(
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: AppSpacing.minTouch,
                  child: GestureDetector(
                    key: const ValueKey('workloop-workspace-back-edge'),
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: _handleDragStart,
                    onHorizontalDragUpdate: _handleDragUpdate,
                    onHorizontalDragEnd: _handleDragEnd,
                    onHorizontalDragCancel: _handleDragCancel,
                  ),
                ),
              );
            }

            return ClipRect(
              child: IgnorePointer(
                ignoring: false,
                child: ColoredBox(
                  color: SlateTheme.of(context).background,
                  child: Stack(children: layers),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Registers an in-place workspace transition with the same app-wide iOS
/// edge-swipe system used by pushed routes.
///
/// This is intentionally separate from [Navigator] history for retained shell
/// destinations such as Money, Tasks, and Notes.
class WorkloopBackSwipeScope extends StatelessWidget {
  final VoidCallback onBack;
  final Widget child;

  const WorkloopBackSwipeScope({
    super.key,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _WorkloopBackActionRegistration(action: onBack, child: child);
  }
}

/// Canonical header for pushed routes outside the four-tab shell.
class WorkloopRouteHeader extends StatelessWidget {
  final String title;
  final String backSemanticLabel;
  final VoidCallback? onBack;
  final Widget? trailing;

  const WorkloopRouteHeader({
    super.key,
    required this.title,
    this.backSemanticLabel = 'Back',
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final backAction = onBack ?? () => workloopGoBack(context);
    final titleWidget = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.t1,
        fontSize: 22,
        height: 1.18,
        fontWeight: FontWeight.w700,
      ),
    );
    final backButton = WorkloopIconButton(
      icon: LucideIcons.chevronLeft,
      semanticLabel: backSemanticLabel,
      color: tokens.textPrimary,
      backgroundColor: tokens.surfaceSubtle,
      onTap: backAction,
    );

    return _WorkloopBackActionRegistration(
      action: backAction,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackTrailing =
              trailing != null &&
              (constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(16) > 21);
          final titleRow = Row(
            children: [
              backButton,
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: titleWidget),
            ],
          );
          final content = stackTrailing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleRow,
                    const SizedBox(height: AppSpacing.xxs),
                    Align(alignment: Alignment.centerRight, child: trailing),
                  ],
                )
              : Row(
                  children: [
                    backButton,
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: titleWidget),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      trailing!,
                    ],
                  ],
                );
          return content;
        },
      ),
    );
  }
}

class WorkloopMetricRow extends StatelessWidget {
  final List<Widget> children;

  const WorkloopMetricRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: tokens.divider.withValues(alpha: 0.62)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1)
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  color: tokens.divider.withValues(alpha: 0.62),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkloopMetricItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const WorkloopMetricItem({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SlateHeaderStat(value: value, label: label, color: color);
  }
}

class WorkloopSectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool quiet;

  const WorkloopSectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: quiet
                ? Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tokens.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )
                : Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    height: 24 / 19,
                  ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpacing.xs),
          WorkloopTextButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    );
  }
}

class WorkloopDivider extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const WorkloopDivider({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Padding(
      padding: margin,
      child: Divider(
        height: 1,
        thickness: 1,
        color: tokens.divider.withValues(alpha: 0.66),
      ),
    );
  }
}

class WorkloopListRow extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showDivider;
  final bool flat;

  const WorkloopListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.pageX,
      vertical: 12,
    ),
    this.showDivider = true,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    return SlateListRow(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      padding: padding,
      showDivider: showDivider,
      flat: flat,
    );
  }
}

/// A shared flat launcher for the Money, Tasks, and Notes workspaces.
///
/// Use inside one grouped surface so these modules keep the same visual and
/// interaction language wherever they appear.
class WorkloopModuleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;
  final String? semanticLabel;

  const WorkloopModuleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.showDivider = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Semantics(
      button: true,
      label: semanticLabel ?? 'Open $title workspace',
      hint: subtitle,
      onTap: onTap,
      child: ExcludeSemantics(
        child: WorkloopListRow(
          flat: true,
          showDivider: showDivider,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: tokens.divider),
            ),
            child: Icon(icon, color: tokens.accentInk, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          trailing: Icon(
            LucideIcons.chevronRight,
            color: tokens.textTertiary,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class WorkloopEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool contained;

  const WorkloopEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.contained = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: tokens.accent, size: 24),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        ),
        if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
      ],
    );

    if (!contained) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: content,
      );
    }
    return WorkloopSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: content,
    );
  }
}

class WorkloopPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;
  final bool secondary;

  const WorkloopPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SlateButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      destructive: destructive,
      secondary: secondary,
    );
  }
}

class WorkloopTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  const WorkloopTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              SlateHaptics.tap();
              onPressed!();
            },
      style: TextButton.styleFrom(
        foregroundColor: destructive ? AppColors.error : AppColors.t2,
        minimumSize: const Size(AppSpacing.minTouch, AppSpacing.minTouch),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class WorkloopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final Widget? badge;
  final String? semanticLabel;

  const WorkloopIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size = 36,
    this.badge,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SlateIconButton(
      icon: icon,
      onTap: onTap,
      color: color,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      size: size,
      badge: badge,
      semanticLabel: semanticLabel,
    );
  }
}

/// The one unmistakable create action in a feature header.
///
/// The visible treatment is intentionally the universal plus symbol. [label]
/// remains required so assistive technology receives the specific action.
class WorkloopTopAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final String? semanticLabel;

  const WorkloopTopAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = LucideIcons.plus,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return WorkloopIconButton(
      icon: icon,
      onTap: onTap,
      color: tokens.onPrimaryAction,
      backgroundColor: tokens.primaryAction,
      borderColor: tokens.primaryAction,
      size: 46,
      semanticLabel: semanticLabel ?? label,
    );
  }
}

class WorkloopPickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;

  const WorkloopPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
  });
}

/// Canonical search field used by list and picker surfaces.
class WorkloopSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;
  final String semanticLabel;

  const WorkloopSearchField({
    super.key,
    this.controller,
    required this.onChanged,
    this.hintText = 'Search',
    this.autofocus = false,
    this.semanticLabel = 'Search',
  });

  @override
  State<WorkloopSearchField> createState() => _WorkloopSearchFieldState();
}

class _WorkloopSearchFieldState extends State<WorkloopSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _clear() {
    SlateHaptics.selection();
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onChanged: widget.onChanged,
        style: TextStyle(color: tokens.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Icon(
            LucideIcons.search,
            color: tokens.textTertiary,
            size: 18,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clear,
                  icon: Icon(
                    LucideIcons.x,
                    color: tokens.textTertiary,
                    size: 17,
                  ),
                ),
          filled: true,
          fillColor: tokens.surfaceRaised,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: tokens.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: tokens.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: tokens.accentInk, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}

/// A mobile-first alternative to Flutter's desktop-style dropdown menu.
///
/// Long lists become searchable automatically and every picker uses the same
/// rounded, keyboard-safe sheet and selection treatment.
class WorkloopPickerField<T> extends StatelessWidget {
  final T? value;
  final List<WorkloopPickerOption<T>> options;
  final ValueChanged<T> onChanged;
  final String title;
  final String hint;
  final String searchHint;
  final IconData? leadingIcon;
  final bool searchable;
  final bool enabled;
  final Color accentColor;

  const WorkloopPickerField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.title,
    required this.hint,
    this.searchHint = 'Search',
    this.leadingIcon,
    this.searchable = false,
    this.enabled = true,
    this.accentColor = AppColors.accentPrimary,
  });

  WorkloopPickerOption<T>? get _selectedOption {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _showPicker(BuildContext context) async {
    if (!enabled || options.isEmpty) return;
    SlateHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: SlateTheme.of(context).scrim,
      builder: (sheetContext) => _WorkloopPickerSheet<T>(
        title: title,
        searchHint: searchHint,
        selected: value,
        options: options,
        searchable: searchable || options.length > 8,
        accentColor: accentColor,
        onSelected: (selected) {
          Navigator.pop(sheetContext);
          SlateHaptics.tap();
          onChanged(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final selected = _selectedOption;
    return Semantics(
      button: true,
      enabled: enabled && options.isNotEmpty,
      label: title,
      value: selected?.label ?? hint,
      hint: enabled && options.isNotEmpty ? 'Double tap to choose' : null,
      onTap: enabled && options.isNotEmpty ? () => _showPicker(context) : null,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _showPicker(context) : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Ink(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: tokens.divider),
              ),
              child: Row(
                children: [
                  if (selected?.leading != null || leadingIcon != null) ...[
                    selected?.leading ??
                        Icon(leadingIcon, color: tokens.textTertiary, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      selected?.label ?? hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected == null
                            ? tokens.textTertiary
                            : tokens.textPrimary,
                        fontSize: 15,
                        fontWeight: selected == null
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: enabled ? tokens.textTertiary : tokens.textDisabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkloopPickerSheet<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final T? selected;
  final List<WorkloopPickerOption<T>> options;
  final bool searchable;
  final Color accentColor;
  final ValueChanged<T> onSelected;

  const _WorkloopPickerSheet({
    required this.title,
    required this.searchHint,
    required this.selected,
    required this.options,
    required this.searchable,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  State<_WorkloopPickerSheet<T>> createState() =>
      _WorkloopPickerSheetState<T>();
}

class _WorkloopPickerSheetState<T> extends State<_WorkloopPickerSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorkloopPickerOption<T>> get _filteredOptions {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options.where((option) {
      return option.label.toLowerCase().contains(query) ||
          (option.subtitle?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.options.length > 6 ? 0.78 : 0.55,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        final filtered = _filteredOptions;
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border.all(color: tokens.divider.withValues(alpha: 0.62)),
            boxShadow: AppShadows.glass,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.textPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.capsule),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.08,
                        ),
                      ),
                    ),
                    WorkloopIconButton(
                      icon: LucideIcons.x,
                      semanticLabel: 'Close ${widget.title}',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (widget.searchable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(LucideIcons.x, size: 17),
                            ),
                      filled: true,
                      fillColor: tokens.textPrimary.withValues(alpha: 0.035),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: tokens.divider.withValues(alpha: 0.62),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: tokens.divider.withValues(alpha: 0.62),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: tokens.accentInk),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(
                            color: tokens.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          final selected = option.value == widget.selected;
                          return _WorkloopPickerRow<T>(
                            option: option,
                            selected: selected,
                            accentColor: widget.accentColor,
                            onTap: () => widget.onSelected(option.value),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkloopPickerRow<T> extends StatelessWidget {
  final WorkloopPickerOption<T> option;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _WorkloopPickerRow({
    required this.option,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      value: option.subtitle,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? tokens.surfaceSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (option.leading != null) ...[
                    option.leading!,
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w600,
                          ),
                        ),
                        if (option.subtitle?.isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            option.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tokens.accentStrong,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tokens.accentBorder,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.check,
                        color: tokens.onAccent,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkloopSegment<T> {
  final T value;
  final String label;
  final String? badge;

  const WorkloopSegment({required this.value, required this.label, this.badge});
}

class WorkloopSegmentedControl<T> extends StatelessWidget {
  final List<WorkloopSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool compact;
  final bool quiet;

  const WorkloopSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    return WorkloopNavigationControl<T>(
      segments: segments,
      selected: selected,
      onChanged: onChanged,
      compact: compact,
      emphasized: !quiet,
    );
  }
}

/// A draggable contained navigation shared by Studio workspaces.
class WorkloopNavigationControl<T> extends StatelessWidget {
  final List<WorkloopSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color color;
  final bool emphasized;
  final bool compact;

  const WorkloopNavigationControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.color = AppColors.accentPrimary,
    this.emphasized = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final selectedIndex = segments.indexWhere(
      (segment) => segment.value == selected,
    );
    return SizedBox(
      height: compact ? AppSpacing.minTouch : 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / segments.length;

          void select(T value) {
            if (value == selected) return;
            SlateHaptics.tap();
            onChanged(value);
          }

          void handleDrag(double dx) {
            final index = (dx / itemWidth).floor().clamp(
              0,
              segments.length - 1,
            );
            select(segments[index].value);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              handleDrag(details.localPosition.dx);
            },
            onHorizontalDragUpdate: (details) {
              handleDrag(details.localPosition.dx);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  duration: AppMotion.responsive(context, AppMotion.standard),
                  curve: AppMotion.curve,
                  left:
                      (selectedIndex < 0 ? 0 : selectedIndex) * itemWidth + 12,
                  bottom: 0,
                  height: 2,
                  width: itemWidth - 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.accentInk,
                      borderRadius: BorderRadius.circular(AppRadius.capsule),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final segment in segments)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: segment.value == selected,
                          inMutuallyExclusiveGroup: true,
                          label: segment.label,
                          value: segment.badge,
                          onTap: () => select(segment.value),
                          child: ExcludeSemantics(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => select(segment.value),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  key: ValueKey(Theme.of(context).brightness),
                                  duration: AppMotion.responsive(
                                    context,
                                    AppMotion.standard,
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    color: segment.value == selected
                                        ? tokens.textPrimary
                                        : tokens.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          segment.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (segment.badge != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                          ),
                                          height: 18,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: segment.value == selected
                                                ? tokens.accent.withValues(
                                                    alpha: 0.12,
                                                  )
                                                : tokens.accent.withValues(
                                                    alpha: 0.07,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.capsule,
                                            ),
                                          ),
                                          child: Text(
                                            segment.badge!,
                                            style: TextStyle(
                                              color: segment.value == selected
                                                  ? tokens.accentInk
                                                  : tokens.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WorkloopFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const WorkloopFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlateFilterChip(label: label, selected: selected, onTap: onTap);
  }
}

class WorkloopNavItem {
  final String label;
  final IconData icon;
  final Color color;

  const WorkloopNavItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class WorkloopBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<WorkloopNavItem> items;
  final ValueChanged<int> onTap;

  const WorkloopBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final tabCount = items.length;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        AppSpacing.bottomNavOffset,
      ),
      child: Container(
        height: AppSpacing.bottomNavHeight,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: tokens.divider),
          boxShadow: AppShadows.soft,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / tabCount;

            int indexForPosition(double dx) {
              return (dx / tabWidth).floor().clamp(0, tabCount - 1);
            }

            void handleDrag(double dx) {
              final index = indexForPosition(dx);
              if (index != currentIndex) {
                SlateHaptics.tap();
                onTap(index);
              }
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) =>
                  handleDrag(details.localPosition.dx),
              onHorizontalDragUpdate: (details) =>
                  handleDrag(details.localPosition.dx),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppMotion.responsive(
                      context,
                      AppMotion.navigation,
                    ),
                    curve: AppMotion.curve,
                    left: currentIndex * tabWidth + 14,
                    top: 0,
                    height: 2,
                    width: tabWidth - 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.accentInk,
                        borderRadius: BorderRadius.circular(AppRadius.capsule),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      tabCount,
                      (index) => Expanded(child: _buildTab(context, index)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final tokens = SlateTheme.of(context);
    final tab = items[index];
    final active = index == currentIndex;

    void handleTap() {
      if (index != currentIndex) SlateHaptics.tap();
      onTap(index);
    }

    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      onTap: handleTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: handleTap,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: active ? 1.04 : 1,
                  duration: AppMotion.responsive(context, AppMotion.standard),
                  curve: AppMotion.curve,
                  child: Icon(
                    tab.icon,
                    color: active ? tokens.accentInk : tokens.textSecondary,
                    size: 20,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: active ? tokens.textPrimary : tokens.textSecondary,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkloopFAB extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;

  const WorkloopFAB({
    super.key,
    required this.onTap,
    this.icon = LucideIcons.plus,
  });

  @override
  State<WorkloopFAB> createState() => _WorkloopFABState();
}

class _WorkloopFABState extends State<WorkloopFAB> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return SlateGlassSurface(
      radius: AppRadius.md,
      blur: 0,
      color: tokens.primaryAction,
      borderColor: tokens.primaryAction,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          SlateHaptics.confirm();
          widget.onTap();
        },
        child: AnimatedScale(
          duration: AppMotion.responsive(context, AppMotion.fast),
          curve: AppMotion.curve,
          scale: _pressed ? 0.96 : 1,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(widget.icon, color: tokens.onPrimaryAction, size: 23),
          ),
        ),
      ),
    );
  }
}

class SlateSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final VoidCallback? onTap;

  const SlateSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final content = AnimatedContainer(
      key: ValueKey(Theme.of(context).brightness),
      duration: AppMotion.responsive(context, AppMotion.standard),
      curve: AppMotion.curve,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? tokens.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ??
              tokens.divider.withValues(
                alpha: Theme.of(context).brightness == Brightness.light
                    ? 0.78
                    : 1,
              ),
        ),
        boxShadow: elevated ? AppShadows.soft : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () {
          SlateHaptics.tap();
          onTap!();
        },
        child: content,
      ),
    );
  }
}

class SlateGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? color;
  final Color? borderColor;

  const SlateGlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = AppRadius.lg,
    this.blur = 24,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? tokens.surfaceRaised.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? tokens.divider),
            boxShadow: AppShadows.glass,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SlateIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final Widget? badge;
  final String? semanticLabel;

  const SlateIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size = AppSpacing.minTouch,
    this.badge,
    this.semanticLabel,
  });

  @override
  State<SlateIconButton> createState() => _SlateIconButtonState();
}

class _SlateIconButtonState extends State<SlateIconButton> {
  bool _pressed = false;

  void _handleTap() {
    SlateHaptics.action();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: _handleTap,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouch,
            minHeight: AppSpacing.minTouch,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: _handleTap,
            child: AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: AppMotion.responsive(context, AppMotion.fast),
              curve: AppMotion.curve,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ?? tokens.surfaceSubtle,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.borderColor ?? tokens.divider,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color ?? tokens.textSecondary,
                        size: 19,
                      ),
                    ),
                    if (widget.badge != null) widget.badge!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SlateSectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SlateSectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: tokens.textSecondary,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: TextButton(
              onPressed: onAction == null
                  ? null
                  : () {
                      SlateHaptics.tap();
                      onAction!();
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentPrimary,
                minimumSize: const Size(0, AppSpacing.minTouch),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: Text(
                actionLabel!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SlateFeatureHeader extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final List<Widget> stats;

  const SlateFeatureHeader({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    Widget titleContent() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: tokens.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );

    Widget headingRow() => Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(child: titleContent()),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stackTrailing =
                trailing != null &&
                (constraints.maxWidth < 290 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.25);
            if (stackTrailing) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headingRow(),
                  const SizedBox(height: AppSpacing.xs),
                  Align(alignment: Alignment.centerRight, child: trailing!),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: headingRow()),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            );
          },
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: tokens.divider),
            ),
            child: Row(
              children: [
                for (var index = 0; index < stats.length; index++) ...[
                  Expanded(child: stats[index]),
                  if (index != stats.length - 1)
                    Container(
                      width: 1,
                      height: 34,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      color: tokens.divider,
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class SlateHeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const SlateHeaderStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              height: 1.05,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SlateEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SlateEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    return SlateSurface(
      color: tokens.surface,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: AppMotion.responsive(context, AppMotion.deliberate),
        curve: AppMotion.curve,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tokens.accentInk, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SlateListRow extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showDivider;
  final bool flat;

  const SlateListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.pageX,
      vertical: 12,
    ),
    this.showDivider = true,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final row = Container(
      margin: EdgeInsets.only(
        bottom: flat ? 0 : (showDivider ? AppSpacing.xs : 0),
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: flat ? Colors.transparent : tokens.surface,
        borderRadius: flat ? null : BorderRadius.circular(AppRadius.lg),
        border: flat
            ? (showDivider
                  ? Border(
                      bottom: BorderSide(
                        color: tokens.divider.withValues(alpha: 0.8),
                      ),
                    )
                  : null)
            : Border.all(color: tokens.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (subtitle != null) ...[const SizedBox(height: 3), subtitle!],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(flat ? AppRadius.sm : AppRadius.lg),
      onTap: () {
        SlateHaptics.tap();
        onTap!();
      },
      child: row,
    );
  }
}

class SlateFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SlateFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    void handleTap() {
      SlateHaptics.tap();
      onTap();
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: handleTap,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: handleTap,
            child: AnimatedContainer(
              key: ValueKey(Theme.of(context).brightness),
              duration: AppMotion.responsive(context, AppMotion.fast),
              curve: AppMotion.curve,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? tokens.accent.withValues(alpha: 0.12)
                    : tokens.surface,
                borderRadius: BorderRadius.circular(AppRadius.capsule),
                border: Border.all(
                  color: selected ? tokens.accent : tokens.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.responsive(context, AppMotion.fast),
                    width: selected ? 5 : 0,
                    height: selected ? 5 : 0,
                    margin: EdgeInsets.only(right: selected ? 7 : 0),
                    decoration: BoxDecoration(
                      color: tokens.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? tokens.accent : tokens.textSecondary,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SlateLoadingBlock extends StatelessWidget {
  final double height;
  final double radius;

  const SlateLoadingBlock({
    super.key,
    this.height = 80,
    this.radius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.70),
      duration: AppMotion.responsive(
        context,
        const Duration(milliseconds: 900),
      ),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.t1.withValues(alpha: value * 0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.t1.withValues(alpha: 0.04)),
          ),
        );
      },
    );
  }
}

class SlateErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const SlateErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      color: AppColors.errorDim,
      borderColor: AppColors.error.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label: message,
            child: ExcludeSemantics(
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.t2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: WorkloopTextButton(label: retryLabel, onPressed: onRetry),
            ),
          ],
        ],
      ),
    );
  }
}

class SlateDisclosure extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final EdgeInsetsGeometry childPadding;

  const SlateDisclosure({
    super.key,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.subtitle,
    this.childPadding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    void handleToggle() {
      SlateHaptics.tap();
      onToggle();
    }

    return SlateSurface(
      padding: EdgeInsets.zero,
      radius: AppRadius.lg,
      child: Column(
        children: [
          Semantics(
            button: true,
            label: title,
            value: expanded ? 'Expanded' : 'Collapsed',
            hint: expanded ? 'Collapse section' : 'Expand section',
            onTap: handleToggle,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: handleToggle,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.t1.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(icon, size: 17, color: AppColors.t2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.t1,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.t3,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: AppMotion.responsive(context, AppMotion.fast),
                        curve: AppMotion.curve,
                        child: const Icon(
                          LucideIcons.chevronDown,
                          color: AppColors.t3,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (AppMotion.responsive(context, AppMotion.standard) ==
              Duration.zero) ...[
            if (expanded) Padding(padding: childPadding, child: child),
          ] else
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(padding: childPadding, child: child),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppMotion.responsive(context, AppMotion.standard),
              firstCurve: AppMotion.curve,
              secondCurve: AppMotion.curve,
              sizeCurve: AppMotion.curve,
            ),
        ],
      ),
    );
  }
}

class SlateButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;
  final bool secondary;

  const SlateButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.secondary = false,
  });

  @override
  State<SlateButton> createState() => _SlateButtonState();
}

class _SlateButtonState extends State<SlateButton> {
  bool _pressed = false;

  void _handleTap() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    if (widget.destructive) {
      SlateHaptics.warning();
    } else if (widget.secondary) {
      SlateHaptics.tap();
    } else {
      SlateHaptics.confirm();
    }
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SlateTheme.of(context);
    final enabled = widget.onPressed != null;
    final bg = widget.destructive
        ? AppColors.error
        : widget.secondary
        ? AppColors.bgCard
        : tokens.primaryAction;
    final fg = widget.destructive
        ? AppColors.bg
        : widget.secondary
        ? AppColors.t2
        : tokens.onPrimaryAction;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? _handleTap : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: enabled ? _handleTap : null,
          child: AnimatedScale(
            scale: _pressed ? AppMotion.pressedScale : 1,
            duration: AppMotion.responsive(context, AppMotion.fast),
            curve: AppMotion.curve,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.48,
              duration: AppMotion.responsive(context, AppMotion.fast),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: widget.secondary
                        ? AppColors.border
                        : widget.destructive
                        ? tokens.error
                        : tokens.primaryAction,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fg, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SlateSheetFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SlateSheetFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: padding,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.96, end: 1),
          duration: AppMotion.responsive(context, AppMotion.standard),
          curve: AppMotion.curve,
          builder: (context, value, sheet) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: value,
                alignment: Alignment.bottomCenter,
                child: sheet,
              ),
            );
          },
          child: SlateSurface(
            color: AppColors.bgCard,
            borderColor: AppColors.border,
            radius: AppRadius.xl,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            elevated: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.t1.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.capsule),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
