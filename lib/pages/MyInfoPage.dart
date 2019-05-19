import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:OpenJMU/constants/Constants.dart';
import 'package:OpenJMU/events/Events.dart';
//import 'package:OpenJMU/pages/Test.dart';
import 'package:OpenJMU/utils/DataUtils.dart';
import 'package:OpenJMU/utils/OTAUtils.dart';
import 'package:OpenJMU/utils/ThemeUtils.dart';
import 'package:OpenJMU/widgets/CommonWebPage.dart';
import 'package:OpenJMU/widgets/dialogs/SelectSplashDialog.dart';


class MyInfoPage extends StatefulWidget {
    @override
    State<StatefulWidget> createState() => MyInfoPageState();
}

class MyInfoPageState extends State<MyInfoPage> {
    Color themeColor = ThemeUtils.currentColorTheme;

    List<String> titles = ["夜间模式", "切换主题", "启动页", "退出登录", if (Platform.isAndroid) "检查更新"];
    List<IconData> icons = [
        Platform.isAndroid ? Icons.brightness_medium : Ionicons.getIconData("ios-moon"),
        Platform.isAndroid ? Icons.color_lens : Ionicons.getIconData("ios-color-palette"),
        Platform.isAndroid ? Ionicons.getIconData("md-today") : Ionicons.getIconData("ios-today"),
        Platform.isAndroid ? Icons.exit_to_app : Ionicons.getIconData("ios-exit"),
        if (Platform.isAndroid) Icons.system_update
    ];

    TextStyle titleTextStyle = TextStyle(fontSize: 16.0);
    String currentVersion;

    bool isLogin = false;
    bool isDark = false;

    /// For test page.
    bool isTest = false;

    @override
    void initState() {
        super.initState();
        if (this.isTest) {
            titles.add("测试页");
            icons.add(Icons.dialpad);
        }
        OTAUtils.getCurrentVersion().then((version) {
            setState(() {
                currentVersion = version;
            });
        });
        DataUtils.getBrightnessDark().then((isDark) {
            setState(() {
                if (isDark != null) {
                    this.isDark = isDark;
                } else {
                    this.isDark = false;
                }
            });
        });
        Constants.eventBus.on<ChangeThemeEvent>().listen((event) {
            if (this.mounted) {
                setState(() {
                    themeColor = event.color;
                });
            }
        });
        Constants.eventBus.on<ChangeBrightnessEvent>().listen((event) {
            if (this.mounted) {
                setState(() {
                    isDark = event.isDarkState;
                });
            }
        });
    }

    Widget renderRow(i) {
        String title = titles[i];
        Widget listItemContent = Padding(
            padding: title == "夜间模式"
                    ? EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0)
                    : EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0)
            ,
            child: Row(
                children: <Widget>[
                    Container(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(icons[i]),
                    ),
                    Expanded(
                        child: Container(
                            padding: EdgeInsets.only(left: 10.0),
                            child: PlatformText(
                                title,
                                style: titleTextStyle,
                            ),
                        ),
                    ),
                    title == "夜间模式"
                            ? PlatformSwitch(
                        activeColor: themeColor,
                        value: isDark,
                        onChanged: (isDark) {
                            setDarkMode(isDark);
                        },
                    )
                            : Icon(Platform.isAndroid ? Icons.keyboard_arrow_right : FontAwesome.getIconData("angle-right"))
                    ,
                ],
            ),
        );
        return InkWell(
            child: listItemContent,
            onTap: () {
                _handleListItemClick(context, title);
            },
        );
    }

    void setDarkMode(isDark) {
        DataUtils.setBrightnessDark(isDark);
        Constants.eventBus.fire(new ChangeBrightnessEvent(isDark));
    }

    void _handleListItemClick(context, String title) {
        switch (title) {
            case "测试页":
//                showDialog(context: context, builder: (_) => TestPage());
                Navigator.pushNamed(context, "/test");
//                Navigator.pushNamed(context, "/notificationTest");
                break;
            case "夜间模式":
                setDarkMode(!isDark);
                break;
            case "切换主题":
                Navigator.pushNamed(context, "/changeTheme");
                break;
            case "启动页":
                showSelectSplashDialog(context);
                break;
            case "退出登录":
                showLogoutDialog(context);
                break;
            case "检查更新":
                OTAUtils.checkUpdate();
                break;
            default:
                break;
        }
    }

    void showSelectSplashDialog(BuildContext context) {
        showDialog(
            context: context,
            builder: (_) => SelectSplashDialog(),
        );
    }

    void showLogoutDialog(BuildContext context) {
        showPlatformDialog(
                context: context,
                builder: (_) => PlatformAlertDialog(
                    title: Text("注销"),
                    content: Text("是否确认注销？"),
                    actions: <Widget>[
                        PlatformButton(
                            android: (BuildContext context) => MaterialRaisedButtonData(
                                color: ThemeUtils.currentColorTheme,
                                elevation: 0,
                                disabledElevation: 0.0,
                                highlightElevation: 0.0,
                                child: Text('取消', style: TextStyle(color: Colors.white)),
                            ),
                            ios: (BuildContext context) => CupertinoButtonData(
                                child: Text("取消", style: TextStyle(color: ThemeUtils.currentColorTheme)),
                            ),
                            onPressed: () {
                                Navigator.of(context).pop();
                            },
                        ),
                        PlatformButton(
                            android: (BuildContext context) => MaterialRaisedButtonData(
                                color: Theme.of(context).dialogBackgroundColor,
                                elevation: 0,
                                disabledElevation: 0.0,
                                highlightElevation: 0.0,
                                child: Text("确认", style: TextStyle(color: ThemeUtils.currentColorTheme)),
                            ),
                            ios: (BuildContext context) => CupertinoButtonData(
                                child: Text("确认", style: TextStyle(
                                    color: ThemeUtils.currentColorTheme,
                                    fontWeight: FontWeight.bold,
                                )),
                            ),
                            onPressed: () {
                                DataUtils.doLogout();
                            },
                        ),
                    ],
                )
        );
    }

    Widget about() {
        return Container(
            padding: EdgeInsets.all(20.0),
            child: Center(
                child: Column(
                    children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(bottom: 12.0),
                            child: Image.asset(
                                "images/ic_jmu_logo_trans.png",
                                color: ThemeUtils.currentColorTheme,
                                width: 80.0,
                                height: 80.0,
                            ),
                            decoration: BoxDecoration(shape: BoxShape.circle),
                        ),
                        Container(
                            margin: EdgeInsets.only(bottom: 12.0),
                            child: RichText(text: TextSpan(children: <TextSpan>[
                                TextSpan(text: "OpenJmu", style: new TextStyle(fontFamily: 'chocolate',color:ThemeUtils.currentColorTheme,fontSize: 35.0)),
                                TextSpan(text: "　v$currentVersion", style: Theme.of(context).textTheme.subtitle),
                            ])),
                        ),
                        RichText(text: TextSpan(
                            children: <TextSpan>[
                                TextSpan(text: "Developed By ", style: TextStyle(color: Theme.of(context).textTheme.body1.color)),
                                TextSpan(
                                    recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                            return CommonWebPage.jump(context, "https://blog.alexv525.com/", "Alex Vincent");
                                        },
                                    text: "Alex Vincent",
                                    style: TextStyle(color: Colors.lightBlue,fontFamily: 'chocolate'),
                                ),
                                TextSpan(text: " And ", style: TextStyle(color: Theme.of(context).textTheme.body1.color)),
                                TextSpan(
                                    recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                            return CommonWebPage.jump(context, "https://135792468.xyz/", "Evsio0n");
                                        },
                                    text: "Evsio0n",
                                    style: TextStyle(color: Colors.lightBlue,fontFamily: 'chocolate'),
                                ),
                                TextSpan(text: ".", style: TextStyle(color: Theme.of(context).textTheme.body1.color)),
                            ],
                        )),
                    ],
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    about(),
                    Container(
                        color: Theme.of(context).dividerColor,
                        height: 1.0,
                    ),
                    ListView.separated(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        separatorBuilder: (context, index) => Container(
                            color: Theme.of(context).dividerColor,
                            height: 1.0,
                        ),
                        itemCount: titles.length,
                        itemBuilder: (context, i) => renderRow(i),
                    ),
                ],
            )
        );
    }

}