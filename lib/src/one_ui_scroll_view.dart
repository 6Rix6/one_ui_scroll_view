import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'physics/one_ui_scroll_physics.dart';

const double _kExpendedAppBarHeightRatio = 3 / 8;

class OneUiScrollView extends StatefulWidget {
  const OneUiScrollView({
    super.key,
    this.globalKey,
    this.childrenPadding = EdgeInsets.zero,
    this.listRadius,
    required this.backgroundColor,
    required this.appBar,
    this.slivers = const [],
  });

  /// The globalKey that is used to get innerScrollController
  /// of [NestedScrollViewState].
  final GlobalKey<NestedScrollViewState>? globalKey;

  final EdgeInsetsGeometry childrenPadding;
  final Radius? listRadius;
  final Color backgroundColor;
  final OneUiAppBar appBar;
  final List<Widget> slivers;

  @override
  State<OneUiScrollView> createState() => _OneUiScrollViewState();
}

class _OneUiScrollViewState extends State<OneUiScrollView>
    with SingleTickerProviderStateMixin {
  late final GlobalKey<NestedScrollViewState> _nestedScrollViewStateKey;
  late double _calculatedExpandedHeight;

  final ValueNotifier<double> _appBarHeightNotifier = ValueNotifier(0);
  final ScrollController _scrollController = ScrollController();

  double? _savedOuterOffset;
  bool _isCollapsed = false;
  bool _hasRestoredOrInitialized = false;
  bool _isSnapping = false;

  final ValueNotifier<double> _stretchNotifier = ValueNotifier(0.0);
  AnimationController? _stretchBackController;
  Animation<double>? _stretchBackAnimation;

  OneUiAppBar get _appBar => widget.appBar;

  @override
  void initState() {
    super.initState();
    _nestedScrollViewStateKey =
        widget.globalKey ?? GlobalKey<NestedScrollViewState>();

    _stretchBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOuterControllerListener();
    });
  }

  @override
  void dispose() {
    _stretchBackAnimation?.removeListener(_onStretchAnimationTick);
    _appBarHeightNotifier.dispose();
    _stretchNotifier.dispose();
    _stretchBackController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasRestoredOrInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreOuterOffset();
    });
  }

  void _initOuterControllerListener() {
    final state = _nestedScrollViewStateKey.currentState;
    if (state == null) return;

    final outerController = state.outerController;
    final topPadding = MediaQuery.of(context).padding.top;

    _appBarHeightNotifier.value = _calculatedExpandedHeight + topPadding;

    outerController.addListener(() {
      _isCollapsed =
          outerController.offset >=
          (_calculatedExpandedHeight - _appBar.toolbarHeight);

      final currentHeight =
          _calculatedExpandedHeight - outerController.offset + topPadding;

      _appBarHeightNotifier.value = currentHeight.clamp(
        _appBar.toolbarHeight + topPadding,
        double.infinity,
      );

      _savedOuterOffset = outerController.offset;
    });

    if (_savedOuterOffset != null) {
      _restoreOuterOffset();
    } else if (_appBar.initiallyCollapsed) {
      final maxOffset = _calculatedExpandedHeight - _appBar.toolbarHeight;
      outerController.jumpTo(maxOffset);
      _isCollapsed = true;
    }
    _hasRestoredOrInitialized = true;
  }

  void _restoreOuterOffset() {
    final savedOffset = _savedOuterOffset;
    if (savedOffset == null) return;

    final state = _nestedScrollViewStateKey.currentState;
    if (state == null) return;

    final outerController = state.outerController;
    if (!outerController.hasClients) return;

    final maxOffset = _calculatedExpandedHeight - _appBar.toolbarHeight;
    final clampedOffset = savedOffset.clamp(0.0, maxOffset);
    final targetOffset = _isCollapsed ? maxOffset : clampedOffset;

    if ((outerController.offset - targetOffset).abs() > 1.0) {
      outerController.jumpTo(targetOffset);
    }
  }

  void _snapAppBar(ScrollController controller, double snapOffset) async {
    if (_isSnapping) return;
    _isSnapping = true;

    try {
      await controller.animateTo(
        snapOffset,
        curve: Curves.ease,
        duration: const Duration(milliseconds: 150),
      );
    } catch (_) {
    } finally {
      _isSnapping = false;
    }
  }

  bool _onScrollEndNotification(ScrollEndNotification notification) {
    if (_isSnapping) return false;

    final scrollViewState = _nestedScrollViewStateKey.currentState;
    if (scrollViewState == null) return false;

    final outerController = scrollViewState.outerController;
    final innerController = scrollViewState.innerController;

    // Check if inner scroll is at top and outer is not at edge
    if (innerController.position.pixels == 0 &&
        !outerController.position.atEdge) {
      final range = _calculatedExpandedHeight - _appBar.toolbarHeight;
      final snapOffset = (outerController.offset / range) > 0.5 ? range : 0.0;

      Future.microtask(() => _snapAppBar(outerController, snapOffset));
    }

    if (_stretchNotifier.value > 0 && !_isCollapsed) {
      _springBackStretch();
    }

    return false;
  }

  bool _onOverscrollNotification(OverscrollNotification notification) {
    if (_isCollapsed || !_appBar.stretch) return false;

    final scrollViewState = _nestedScrollViewStateKey.currentState;
    if (scrollViewState == null) return false;

    final innerController = scrollViewState.innerController;

    final isInnerAtTop =
        innerController.hasClients && innerController.position.pixels <= 0;

    if (!isInnerAtTop) return false;

    final overscroll = -notification.overscroll;
    if (overscroll <= 0) return false;

    _stretchBackController?.stop();

    final currentStretch = _stretchNotifier.value;
    final dampingFactor = 1.0 / (1.0 + currentStretch * 0.05);
    final newStretch = currentStretch + overscroll * dampingFactor;

    _stretchNotifier.value = newStretch;

    return false;
  }

  bool _onOverscrollIndicatorNotification(
    OverscrollIndicatorNotification notification,
  ) {
    if (!_appBar.stretch) return false;

    final scrollViewState = _nestedScrollViewStateKey.currentState;
    if (scrollViewState == null) return false;

    final innerController = scrollViewState.innerController;
    final isInnerAtTop =
        innerController.hasClients && innerController.position.pixels <= 0;

    if (isInnerAtTop) {
      notification.disallowIndicator();
    }

    return true;
  }

  bool _onScrollUpdateNotification(ScrollUpdateNotification notification) {
    if (_stretchNotifier.value > 0 &&
        notification.scrollDelta != null &&
        notification.scrollDelta! > 0) {
      // Stop the spring back animation if it's running
      _stretchBackController?.stop();

      // Decrease the stretch amount when scrolling up
      final currentStretch = _stretchNotifier.value;
      final newStretch = currentStretch - notification.scrollDelta!;

      _stretchNotifier.value = newStretch.clamp(0.0, double.infinity);
    }
    return false;
  }

  void _springBackStretch() {
    final controller = _stretchBackController;
    if (controller == null) return;

    _stretchBackAnimation?.removeListener(_onStretchAnimationTick);

    final startValue = _stretchNotifier.value;

    _stretchBackAnimation = Tween<double>(
      begin: startValue,
      end: 0.0,
    ).animate(CurvedAnimation(parent: controller, curve: _appBar.stretchCurve));

    _stretchBackAnimation!.addListener(_onStretchAnimationTick);

    controller.forward(from: 0.0);
  }

  void _onStretchAnimationTick() {
    _stretchNotifier.value = (_stretchBackAnimation?.value ?? 0.0).clamp(
      0.0,
      double.infinity,
    );
  }

  double _calculateExpandRatio(BoxConstraints constraints) {
    final topPadding = MediaQuery.of(context).padding.top;

    var expandRatio =
        (constraints.maxHeight - _appBar.toolbarHeight - topPadding) /
        (_calculatedExpandedHeight - _appBar.toolbarHeight);

    return expandRatio.clamp(0.0, double.infinity);
  }

  Widget _extendedTitle(Animation<double> animation, double expandRatio) {
    final child = Center(
      child:
          _appBar.expandedTitleBuilder?.call(expandRatio) ??
          _appBar.expandedTitle,
    );

    if (_appBar.expandedTitleTransitionBuilder != null) {
      return _appBar.expandedTitleTransitionBuilder!.call(
        animation,
        expandRatio,
        child,
      );
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: Curves.easeIn),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _collapsedTitle(
    BuildContext context,
    Animation<double> animation,
    Widget? leading,
  ) {
    Widget child = Align(
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.titleLarge!,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        child: _appBar.collapsedTitle,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Align(
        alignment: _appBar.collapsedTitleAlignment,
        child: SizedBox(
          height: _appBar.toolbarHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null)
                SizedBox(width: kToolbarHeight, child: leading),
              SizedBox(width: NavigationToolbar.kMiddleSpacing),

              if (_appBar.collapsedTitleTransitionBuilder != null)
                _appBar.collapsedTitleTransitionBuilder!.call(animation, child)
              else
                FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final actions = _appBar.actions;
    if (actions == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Align(
        alignment: _appBar.actionsAlignment,
        child: Container(
          padding: EdgeInsets.only(right: _appBar.actionSpacing),
          height: _appBar.toolbarHeight,
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _headerSliverBuilder(
    BuildContext context,
    bool innerBoxIsScrolled,
  ) {
    Widget? leading = _appBar.leading;
    if (leading == null && _appBar.automaticallyImplyLeading) {
      leading = ModalRoute.of(context)?.canPop == true
          ? const BackButton()
          : null;
    }

    return [
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: ValueListenableBuilder<double>(
          valueListenable: _stretchNotifier,
          builder: (context, stretchAmount, _) {
            return SliverAppBar(
              backgroundColor: widget.backgroundColor,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: _calculatedExpandedHeight + stretchAmount,
              toolbarHeight: _appBar.toolbarHeight,
              elevation: _appBar.elevation,
              bottom: _appBar.bottom,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final expandRatio = _calculateExpandRatio(constraints);
                  final animation = AlwaysStoppedAnimation<double>(
                    expandRatio.clamp(0.0, 1.0),
                  );

                  final bottomPadding = _appBar.bottom != null
                      ? EdgeInsets.only(
                          bottom: _appBar.bottom!.preferredSize.height,
                        )
                      : EdgeInsets.zero;

                  return Padding(
                    padding: bottomPadding,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _extendedTitle(animation, expandRatio),
                        _collapsedTitle(context, animation, leading),
                        _actions(context),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _calculatedExpandedHeight =
        _appBar.expandedHeight ??
        (MediaQuery.of(context).size.height * _kExpendedAppBarHeightRatio);

    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Stack(
        children: [
          NotificationListener<Notification>(
            onNotification: (notification) {
              bool result = false;

              if (notification is OverscrollIndicatorNotification) {
                result = _onOverscrollIndicatorNotification(notification);
              } else if (notification is OverscrollNotification) {
                result = _onOverscrollNotification(notification);
              } else if (notification is ScrollEndNotification) {
                result = _onScrollEndNotification(notification);
              } else if (notification is ScrollUpdateNotification) {
                result = _onScrollUpdateNotification(notification);
              }

              return result;
            },
            child: NestedScrollView(
              key: _nestedScrollViewStateKey,
              controller: _scrollController,
              physics: OneUiScrollPhysics(_calculatedExpandedHeight),
              scrollBehavior: CupertinoScrollBehavior(),
              headerSliverBuilder: _headerSliverBuilder,
              body: Builder(
                builder: (context) => CustomScrollView(
                  slivers: <Widget>[
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    SliverPadding(
                      padding: widget.childrenPadding,
                      sliver: SliverMainAxisGroup(slivers: widget.slivers),
                    ),
                  ],
                ),
              ),
            ),
          ),

          ListenableBuilder(
            listenable: Listenable.merge([
              _appBarHeightNotifier,
              _stretchNotifier,
            ]),
            builder: (context, _) {
              final state = _nestedScrollViewStateKey.currentState;
              final outerOffset = state?.outerController.hasClients == true
                  ? state!.outerController.offset
                  : 0.0;
              final topPadding = MediaQuery.of(context).padding.top;

              final currentHeight =
                  _calculatedExpandedHeight +
                  _stretchNotifier.value -
                  outerOffset +
                  topPadding;

              final totalHeight = currentHeight.clamp(
                _appBar.toolbarHeight + topPadding,
                double.infinity,
              );

              return Positioned.fill(
                top: totalHeight - 1,
                child: IgnorePointer(
                  child: Padding(
                    padding: widget.childrenPadding,
                    child: CustomPaint(
                      painter: _RoundedMaskPainter(
                        color: widget.backgroundColor,
                        radius: widget.listRadius,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class OneUiAppBar {
  const OneUiAppBar({
    required this.collapsedTitle,
    this.expandedTitle,
    this.expandedTitleBuilder,
    this.collapsedTitleTransitionBuilder,
    this.expandedTitleTransitionBuilder,
    this.leading,
    this.actions,
    this.actionSpacing = 0.0,
    this.bottom,
    this.expandedHeight,
    this.toolbarHeight = kToolbarHeight,
    this.elevation = 0.0,
    this.initiallyCollapsed = false,
    this.automaticallyImplyLeading = true,
    this.stretch = false,
    this.stretchCurve = Curves.easeOut,
    this.collapsedTitleAlignment = Alignment.bottomLeft,
    this.actionsAlignment = Alignment.bottomRight,
  });

  final Widget collapsedTitle;
  final Widget? expandedTitle;
  final Widget Function(double expandRatio)? expandedTitleBuilder;
  final Widget Function(
    Animation<double> animation,
    double expandRatio,
    Widget? child,
  )?
  expandedTitleTransitionBuilder;
  final Widget Function(Animation<double> animation, Widget? child)?
  collapsedTitleTransitionBuilder;
  final Widget? leading;
  final List<Widget>? actions;
  final double actionSpacing;
  final PreferredSizeWidget? bottom;
  final double? expandedHeight;
  final double toolbarHeight;
  final double elevation;
  final bool initiallyCollapsed;
  final bool automaticallyImplyLeading;
  final bool stretch;
  final Curve stretchCurve;
  final AlignmentGeometry collapsedTitleAlignment;
  final AlignmentGeometry actionsAlignment;
}

class _RoundedMaskPainter extends CustomPainter {
  final Color color;
  final Radius? radius;

  _RoundedMaskPainter({required this.color, this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = this.radius ?? Radius.circular(24);

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holePath = Path()
      ..addRRect(RRect.fromLTRBR(0, 1, size.width, size.height, radius));

    final masked = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(masked, paint);
  }

  @override
  bool shouldRepaint(_RoundedMaskPainter old) => old.color != color;
}
