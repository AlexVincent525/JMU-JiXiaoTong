import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:OpenJMU/constants/Constants.dart';
import 'package:OpenJMU/events/Events.dart';

class FABBottomAppBarItem {
    FABBottomAppBarItem({this.iconData, this.text});
    IconData iconData;
    String text;
}

class FABBottomAppBar extends StatefulWidget {
    FABBottomAppBar({
        this.items,
        this.centerItemText,
        this.height: 60.0,
        this.iconSize: 24.0,
        this.backgroundColor,
        this.color,
        this.selectedColor,
        this.notchedShape,
        this.onTabSelected,
    }) {
        assert(this.items.length == 2 || this.items.length == 4);
    }
    final List<FABBottomAppBarItem> items;
    final String centerItemText;
    final double height;
    final double iconSize;
    final Color backgroundColor;
    final Color color;
    final Color selectedColor;
    final NotchedShape notchedShape;
    final ValueChanged<int> onTabSelected;

    @override
    State<StatefulWidget> createState() => FABBottomAppBarState();
}

class FABBottomAppBarState extends State<FABBottomAppBar> {
    int _selectedIndex = Constants.homeSplashIndex;

    _updateIndex(int index) {
        widget.onTabSelected(index);
        setState(() {
            _selectedIndex = index;
        });
    }

    @override
    void initState() {
        super.initState();
        Constants.eventBus.on<ActionsEvent>().listen((event) {
            setState(() {
                if (event.type == "action_home") {
                    _selectedIndex = 0;
                } else if (event.type == "action_apps") {
                    _selectedIndex = 1;
                } else if (event.type == "action_discover") {
                    _selectedIndex = 2;
                } else if (event.type == "action_user") {
                    _selectedIndex = 3;
                }
            });
        });
    }

    @override
    Widget build(BuildContext context) {
        List<Widget> items = List.generate(widget.items.length, (int index) {
            return _buildTabItem(
                item: widget.items[index],
                index: index,
                onPressed: _updateIndex,
            );
        });
        items.insert(items.length >> 1, _buildMiddleTabItem());

        Widget appBar = Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items,
        );
        Color _color = widget.backgroundColor;
        if (Platform.isIOS) {
            appBar = ClipRect(
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border(top: BorderSide(
                                color: Color.fromARGB(255, 169, 169, 169),
                            )),
                        ),
                        child: appBar,
                    ),
                ),
            );
            _color = Color(widget.backgroundColor.value - int.parse("22000000", radix: 16));
        }

        return BottomAppBar(
            color: _color,
            shape: widget.notchedShape,
            child: appBar,
        );
    }

    Widget _buildMiddleTabItem() {
        return Expanded(
            child: SizedBox(
                height: widget.height,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        SizedBox(height: widget.iconSize),
                        Text(
                            widget.centerItemText ?? '',
                            style: TextStyle(color: widget.color),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildTabItem({
        FABBottomAppBarItem item,
        int index,
        ValueChanged<int> onPressed,
    }) {
        Color color = _selectedIndex == index ? widget.selectedColor : widget.color;
        return Expanded(
            child: SizedBox(
                height: widget.height,
                child: Material(
                    type: MaterialType.transparency,
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onPressed(index),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                                Icon(item.iconData, color: color, size: widget.iconSize),
                                Text(
                                    item.text,
                                    style: TextStyle(color: color),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}