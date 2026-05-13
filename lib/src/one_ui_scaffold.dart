import 'package:flutter/material.dart';
import 'package:one_ui_scroll_view/src/one_ui_scroll_view.dart';

class OneUiScaffold extends StatefulWidget {
  const OneUiScaffold({
    super.key,
    this.globalKey,
    this.childrenPadding = EdgeInsets.zero,
    this.listRadius,
    this.backgroundColor,
    required this.appBar,
    this.slivers = const [],
  });

  final GlobalKey<NestedScrollViewState>? globalKey;

  final EdgeInsetsGeometry childrenPadding;
  final Radius? listRadius;
  final Color? backgroundColor;
  final OneUiAppBar appBar;
  final List<Widget> slivers;

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
        childrenPadding: widget.childrenPadding,
        backgroundColor: color,
        globalKey: widget.globalKey,
        listRadius: widget.listRadius,
        slivers: widget.slivers,
        appBar: widget.appBar,
      ),
    );
  }
}
