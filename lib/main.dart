import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oktoast/oktoast.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:OpenJMU/constants/Constants.dart';
import 'package:OpenJMU/events/Events.dart';
import 'package:OpenJMU/localications/cupertino_zh.dart';
import 'package:OpenJMU/pages/SplashPage.dart';
import 'package:OpenJMU/utils/DataUtils.dart';
import 'package:OpenJMU/utils/NetUtils.dart';
import 'package:OpenJMU/utils/ThemeUtils.dart';
import 'package:OpenJMU/utils/RouteUtils.dart';
import 'package:OpenJMU/widgets/NoScaleTextWidget.dart';


void main() {
    runApp(JMUAppClient());
}

class JMUAppClient extends StatefulWidget {
    @override
    State<StatefulWidget> createState() => JMUAppClientState();
}

class JMUAppClientState extends State<JMUAppClient> {
    StreamSubscription<ConnectivityResult> connectivitySubscription;
    bool isUserLogin = false;
    int initIndex;

    Color currentThemeColor = ThemeUtils.currentThemeColor;

    @override
    void initState() {
        super.initState();
        SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
        ]);
        connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
            Constants.eventBus.fire(ConnectivityChangeEvent(result));
            debugPrint("Current connectivity: $result");
        });
        DataUtils.getColorThemeIndex().then((index) {
            if (this.mounted && index != null) {
                setState(() {
                    currentThemeColor = ThemeUtils.supportColors[index];
                });
                ThemeUtils.currentThemeColor = ThemeUtils.supportColors[index];
                Constants.eventBus.fire(ChangeThemeEvent(ThemeUtils.supportColors[index]));
            }
        });
        DataUtils.getHomeSplashIndex().then((index) {
            Constants.homeSplashIndex = index ?? 0;
        });
        DataUtils.getHomeStartUpIndex().then((indexList) {
            Constants.homeStartUpIndex = indexList ?? [0, 0, 0];
        });
        Constants.eventBus
            ..on<ChangeThemeEvent>().listen((event) {
                if (this.mounted) {
                    setState(() {
                        currentThemeColor = event.color;
                    });
                }
            })
            ..on<LogoutEvent>().listen((event) async {
                setState(() {
                    currentThemeColor = ThemeUtils.defaultColor;
                });
                await DataUtils.logout();
            })
            ..on<ActionsEvent>().listen((event) {
                if (event.type == "action_home") {
                    initIndex = 0;
                } else if (event.type == "action_apps") {
                    initIndex = 1;
                } else if (event.type == "action_message") {
                    initIndex = 2;
                } else if (event.type == "action_mine") {
                    initIndex = 3;
                }
            })
            ..on<ChangeBrightnessEvent>().listen((event) {
                setState(() {
                    ThemeUtils.isDark = event.isDarkState;
                });
            })
        ;
        listenToBrightness();
        NetUtils.initConfig();
        initQuickActions();
        debugPrint("Android: ${Platform.isAndroid} | iOS: ${Platform.isIOS}");
    }

    @override
    void dispose() {
        super.dispose();
        connectivitySubscription?.cancel();
        debugPrint("Main dart disposed.");
    }

    void initQuickActions() {
        final QuickActions quickActions = QuickActions();
        quickActions.initialize((String shortcutType) {
            debugPrint("QuickActions triggered: $shortcutType");
            Constants.eventBus.fire(ActionsEvent(shortcutType));
        });
        quickActions.setShortcutItems(<ShortcutItem>[
            const ShortcutItem(type: 'action_home', localizedTitle: '首页', icon: 'actions_home'),
            const ShortcutItem(type: 'action_apps', localizedTitle: '应用', icon: 'actions_apps'),
            const ShortcutItem(type: 'action_message', localizedTitle: '消息', icon: 'actions_message'),
            const ShortcutItem(type: 'action_mine', localizedTitle: '我的', icon: 'actions_mine'),
        ]);
    }

    void listenToBrightness() {
        DataUtils.getBrightnessDark().then((isDark) {
            if (isDark == null) {
                DataUtils.setBrightnessDark(false).then((whatever) {
                    setState(() {
                        ThemeUtils.isDark = false;
                    });
                });
            } else {
                if (isDark) {
                    setState(() {
                        ThemeUtils.isDark = true;
                    });
                } else {
                    setState(() {
                        ThemeUtils.isDark = false;
                    });
                }
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        return Theme(
            data: ThemeUtils.isDark ? ThemeUtils.darkTheme() : ThemeUtils.lightTheme(),
            child: OKToast(
                child: MaterialApp(
                    builder: (BuildContext c, Widget w) => NoScaleTextWidget(child: w),
                    debugShowCheckedModeBanner: false,
                    routes: RouteUtils.routes,
                    title: "OpenJMU",
                    theme: ThemeUtils.isDark ? ThemeUtils.darkTheme() : ThemeUtils.lightTheme(),
                    home: SplashPage(initIndex: initIndex),
                    localizationsDelegates: [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        ChineseCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: [
                        const Locale('zh'),
                        const Locale('en'),
                    ],
                ),
            ),
        );
    }
}
