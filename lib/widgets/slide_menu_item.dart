///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-12-07 19:17
///
import 'package:flutter/material.dart';

import 'package:openjmu/constants/constants.dart';

class SlideMenuItem extends StatelessWidget {
  const SlideMenuItem({
    Key key,
    @required this.child,
    @required this.onTap,
    this.color,
    this.height,
  })  : assert(child != null),
        super(key: key);

  final Widget child;
  final double height;
  final Color color;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
      color: color,
      width: Screens.width / 5,
      height: height,
    );
  }
}

class SlideItem extends StatelessWidget {
  SlideItem({
    @required this.child,
    @required this.menu,
    @required this.height,
    this.onTap,
  }) {
    children
      ..add(GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap != null
            ? () {
                if (_controller.offset != 0) {
                  dismiss();
                } else {
                  onTap();
                }
              }
            : null,
        child: SizedBox(width: Screens.width, child: child),
      ))
      ..addAll(
        menu
            .map((SlideMenuItem item) => GestureDetector(
                  child: item,
                  onTap: () {
                    item.onTap();
                    dismiss();
                  },
                ))
            .toList(),
      );
  }

  final ScrollController _controller = ScrollController();
  final Widget child;
  final List<SlideMenuItem> menu;
  final double height;
  final GestureTapCallback onTap;

  final List<Widget> children = <Widget>[];

  void dismiss() {
    _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (_) {
        if (_controller.offset < (Screens.width / 5) * menu.length / 4) {
          _controller.animateTo(
            0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        } else {
          _controller.animateTo(
            menu.length * (Screens.width / 5),
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      },
      child: ScrollConfiguration(
        behavior: const NoGlowScrollBehavior(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          controller: _controller,
          child: SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
