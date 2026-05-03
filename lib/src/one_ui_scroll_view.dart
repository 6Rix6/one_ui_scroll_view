import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'physics/one_ui_scroll_physics.dart';

const double _kExpendedAppBarHeightRatio = 3 / 8;

class OneUiScrollView extends StatefulWidget {
  const OneUiScrollView({
    super.key,
    required this.expandedTitle,
    required this.collapsedTitle,
    this.leading,
    this.actions,
    this.children = const [],
    this.childrenPadding = EdgeInsets.zero,
    this.bottomDivider,
    this.expandedHeight,
    this.toolbarHeight = kToolbarHeight,
    this.actionSpacing = 0,
    required this.backgroundColor,
    this.elevation = 0,
    this.listRadius,
    this.initiallyCollapsed = false,
    this.globalKey,
    this.automaticallyImplyLeading = true,
    this.collapsedTitleAlignment = Alignment.bottomLeft,
    this.actionsAlignment = Alignment.bottomRight,
  });

  final Widget expandedTitle;
  final Widget collapsedTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final List<Widget> children;
  final EdgeInsetsGeometry childrenPadding;
  final Divider? bottomDivider;
  final double? expandedHeight;
  final double toolbarHeight;
  final double actionSpacing;
  final Color backgroundColor;
  final double elevation;
  final Radius? listRadius;
  final bool initiallyCollapsed;
  final bool automaticallyImplyLeading;
  final AlignmentGeometry collapsedTitleAlignment;
  final AlignmentGeometry actionsAlignment;

  /// The globalKey that is used to get innerScrollController
  /// of [NestedScrollViewState].
  final GlobalKey<NestedScrollViewState>? globalKey;

  @override
  State<OneUiScrollView> createState() => _OneUiScrollViewState();
}

class _OneUiScrollViewState extends State<OneUiScrollView>
    with SingleTickerProviderStateMixin {
  late final GlobalKey<NestedScrollViewState> _nestedScrollViewStateKey;
  late double _calculatedExpandedHeight;

  final ValueNotifier<double> _appBarHeightNotifier = ValueNotifier(0);
  final ScrollController _scrollController = ScrollController();

  Future<void>? _scrollAnimate;

  double? _savedOuterOffset;
  bool _isCollapsed = false;
  bool _hasRestoredOrInitialized = false;

  @override
  void initState() {
    super.initState();
    _nestedScrollViewStateKey =
        widget.globalKey ?? GlobalKey<NestedScrollViewState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOuterControllerListener();
    });
  }

  @override
  void dispose() {
    _appBarHeightNotifier.dispose();
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
      _savedOuterOffset = outerController.offset;
      _isCollapsed =
          outerController.offset >=
          (_calculatedExpandedHeight - widget.toolbarHeight);

      final currentHeight =
          _calculatedExpandedHeight - outerController.offset + topPadding;
      _appBarHeightNotifier.value = currentHeight.clamp(
        widget.toolbarHeight + topPadding,
        double.infinity,
      );
    });

    if (_savedOuterOffset != null) {
      _restoreOuterOffset();
    } else if (widget.initiallyCollapsed) {
      final maxOffset = _calculatedExpandedHeight - widget.toolbarHeight;
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

    final maxOffset = _calculatedExpandedHeight - widget.toolbarHeight;
    final clampedOffset = savedOffset.clamp(0.0, maxOffset);
    final targetOffset = _isCollapsed ? maxOffset : clampedOffset;

    if ((outerController.offset - targetOffset).abs() > 1.0) {
      outerController.jumpTo(targetOffset);
    }
  }

  void _snapAppBar(ScrollController controller, double snapOffset) async {
    // Current animation check using the future
    if (_scrollAnimate != null) await _scrollAnimate;

    _scrollAnimate = controller.animateTo(
      snapOffset,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 150),
    );
  }

  bool _onNotification(ScrollEndNotification notification) {
    final scrollViewState = _nestedScrollViewStateKey.currentState;
    if (scrollViewState == null) return false;

    final outerController = scrollViewState.outerController;
    final innerController = scrollViewState.innerController;

    // Check if inner scroll is at top and outer is not at edge
    if (innerController.position.pixels == 0 &&
        !outerController.position.atEdge) {
      final range = _calculatedExpandedHeight - widget.toolbarHeight;
      final snapOffset = (outerController.offset / range) > 0.5 ? range : 0.0;

      Future.microtask(() => _snapAppBar(outerController, snapOffset));
    }
    return false;
  }

  double _calculateExpandRatio(BoxConstraints constraints) {
    var expandRatio =
        (constraints.maxHeight - widget.toolbarHeight) /
        (_calculatedExpandedHeight - widget.toolbarHeight);

    return expandRatio.clamp(0.0, 1.0);
  }

  Widget _extendedTitle(Animation<double> animation) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
        ),
      ),
      child: Center(child: widget.expandedTitle),
    );
  }

  Widget _collapsedTitle(
    BuildContext context,
    Animation<double> animation,
    Widget? leading,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Align(
        alignment: widget.collapsedTitleAlignment,
        child: Container(
          padding: const EdgeInsets.only(left: 16),
          height: widget.toolbarHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?leading,
              FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: widget.collapsedTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final actions = widget.actions;
    if (actions == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Align(
        alignment: widget.actionsAlignment,
        child: Container(
          padding: EdgeInsets.only(right: widget.actionSpacing),
          height: widget.toolbarHeight,
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
    Widget? leading = widget.leading;
    if (leading == null && widget.automaticallyImplyLeading) {
      leading = ModalRoute.of(context)?.canPop == true
          ? const BackButton()
          : null;
    }

    return [
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: SliverAppBar(
          backgroundColor: widget.backgroundColor,
          pinned: true,
          automaticallyImplyLeading: false,
          expandedHeight: _calculatedExpandedHeight,
          toolbarHeight: widget.toolbarHeight,
          elevation: widget.elevation,
          flexibleSpace: LayoutBuilder(
            builder: (context, constraints) {
              final expandRatio = _calculateExpandRatio(constraints);
              final animation = AlwaysStoppedAnimation<double>(expandRatio);

              return Stack(
                fit: StackFit.expand,
                children: [
                  _extendedTitle(animation),
                  _collapsedTitle(context, animation, leading),
                  _actions(context),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: widget.bottomDivider,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _calculatedExpandedHeight =
        widget.expandedHeight ??
        (MediaQuery.of(context).size.height * _kExpendedAppBarHeightRatio);

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          NotificationListener<ScrollEndNotification>(
            onNotification: _onNotification,
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
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => widget.children[i],
                          childCount: widget.children.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          ValueListenableBuilder<double>(
            valueListenable: _appBarHeightNotifier,
            builder: (context, appBarHeight, _) {
              return Positioned.fill(
                top: appBarHeight,
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
      ..addRRect(RRect.fromLTRBR(0, 0, size.width, size.height, radius));

    final masked = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(masked, paint);
  }

  @override
  bool shouldRepaint(_RoundedMaskPainter old) => old.color != color;
}
