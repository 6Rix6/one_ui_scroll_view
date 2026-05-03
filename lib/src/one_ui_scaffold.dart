import 'package:flutter/material.dart';
import 'package:one_ui_scroll_view/src/one_ui_scroll_view.dart';

class OneUiScaffold extends StatefulWidget {
  const OneUiScaffold({
    super.key,
    required this.expandedTitle,
    required this.collapsedTitle,
    this.actions,
    this.children = const [],
    this.childrenPadding = EdgeInsets.zero,
    this.bottomDivider,
    this.expandedHeight,
    this.toolbarHeight = kToolbarHeight,
    this.actionSpacing = 0,
    this.backgroundColor,
    this.elevation = 0.0,
    this.listRadius,
    this.initiallyCollapsed = false,
    this.automaticallyImplyLeading = true,
    this.collapsedTitleAlignment = Alignment.bottomLeft,
    this.actionsAlignment = Alignment.bottomRight,
    this.globalKey,
  });

  final Widget expandedTitle;
  final Widget collapsedTitle;
  final List<Widget>? actions;
  final List<Widget> children;
  final EdgeInsetsGeometry childrenPadding;
  final Divider? bottomDivider;
  final double? expandedHeight;
  final double toolbarHeight;
  final double actionSpacing;
  final Color? backgroundColor;
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
  State<OneUiScaffold> createState() => _OneUiScaffoldState();
}

class _OneUiScaffoldState extends State<OneUiScaffold> {
  @override
  Widget build(BuildContext context) {
    final color =
        widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: color,
      body: OneUiScrollView(
        expandedTitle: widget.expandedTitle,
        collapsedTitle: widget.collapsedTitle,
        actions: widget.actions,
        childrenPadding: widget.childrenPadding,
        bottomDivider: widget.bottomDivider,
        expandedHeight: widget.expandedHeight,
        toolbarHeight: widget.toolbarHeight,
        actionSpacing: widget.actionSpacing,
        backgroundColor: color,
        elevation: widget.elevation,
        globalKey: widget.globalKey,
        listRadius: widget.listRadius,
        initiallyCollapsed: widget.initiallyCollapsed,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        collapsedTitleAlignment: widget.collapsedTitleAlignment,
        actionsAlignment: widget.actionsAlignment,
        children: widget.children,
      ),
    );
  }
}
