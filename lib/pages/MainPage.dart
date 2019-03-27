import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jxt/api/Api.dart';
import 'package:jxt/constants/Constants.dart';
import 'package:jxt/events/ChangeBrightnessEvent.dart';
import 'package:jxt/events/ChangeThemeEvent.dart';
import 'package:jxt/events/LoginEvent.dart';
import 'package:jxt/events/LogoutEvent.dart';
import 'package:jxt/utils/DataUtils.dart';
import 'package:jxt/utils/ThemeUtils.dart';
import 'package:jxt/utils/ToastUtils.dart';
import 'package:jxt/pages/LoginPage.dart';
import 'package:jxt/pages/NewsListPage.dart';
import 'package:jxt/pages/WeiboListPage.dart';
import 'package:jxt/pages/AppCenterPage.dart';
import 'package:jxt/pages/DiscoveryPage.dart';
import 'package:jxt/pages/MyInfoPage.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new MainPageState();
}

class MainPageState extends State<MainPage> {
  final appBarTitles = ['首页', '新闻', '应用中心', '消息', '我的'];
  TextStyle tabTextStyleSelected = new TextStyle(color: ThemeUtils.currentColorTheme);
  final tabTextStyleNormal = new TextStyle(color: Colors.grey);
  Brightness currentBrightness = Brightness.light;

  Color themeColor = ThemeUtils.currentColorTheme;
  int _tabIndex = 0;

  var _body;
  var pages;
  var userAvatar;

  bool isUserLogin = false;

  @override
  void initState() {
    super.initState();
    DataUtils.isLogin().then((isLogin) {
      setState(() {
        this.isUserLogin = isLogin;
      });
    });
    DataUtils.getBrightness().then((isDark) {
      if (isDark == null) {
        DataUtils.setBrightness(false).then((whatever) {
          setState(() {
            currentBrightness = Brightness.light;
          });
        });
      } else {
        if (isDark) {
          setState(() {
            currentBrightness = Brightness.dark;
          });
        } else {
          setState(() {
            currentBrightness = Brightness.light;
          });
        }
      }
    });
    Constants.eventBus.on<LoginEvent>().listen((event) {
      setState(() {
        this.isUserLogin = true;
      });
    });
    Constants.eventBus.on<LogoutEvent>().listen((event) {
      Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (context) {
        return new LoginPage();
      },));
    });
    DataUtils.getColorThemeIndex().then((index) {
      if (index != null) {
        ThemeUtils.currentColorTheme = ThemeUtils.supportColors[index];
        Constants.eventBus.fire(new ChangeThemeEvent(ThemeUtils.supportColors[index]));
      }
    });
    Constants.eventBus.on<ChangeThemeEvent>().listen((event) {
      setState(() {
        tabTextStyleSelected = new TextStyle(color: event.color);
        themeColor = event.color;
      });
    });
    Constants.eventBus.on<ChangeBrightnessEvent>().listen((event) {
      setState(() {
        currentBrightness = event.brightness;
      });
    });
    pages = <Widget>[
      WeiboListPage(),
      NewsListPage(),
      AppCenterPage(),
      DiscoveryPage(),
      MyInfoPage()
    ];
  }

  Image getTabImage(path) {
    return new Image.asset(path, width: 20.0, height: 20.0);
  }

  TextStyle getTabTextStyle(int curIndex) {
    if (curIndex == _tabIndex) {
      return tabTextStyleSelected;
    }
    return tabTextStyleNormal;
  }

  Text getTabTitle(int curIndex) {
    return new Text(appBarTitles[curIndex], style: getTabTextStyle(curIndex));
  }

  @override
  Widget build(BuildContext context) {
    return mainPage(context);
  }

  int last = 0;
  Future<bool> doubleClickBack() {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - last > 800) {
      showShortToast("再按一次退出应用");
      last = DateTime.now().millisecondsSinceEpoch;
      return Future.value(false);
    } else {
      cancelToast();
      return Future.value(true);
    }
  }

//  AppBar pageAppBar() {
//    if (appBarTitles[_tabIndex] == "首页") {
//      return new AppBar(
//          title: new Center(
//              child: new Text(
//                  appBarTitles[_tabIndex],
//                  style: new TextStyle(color: Colors.white)
//              )
//          ),
//          actions: <Widget>[
//            new IconButton(
//                icon: new Icon(
//                  Icons.add_circle,
//                  color: Colors.white
//                ),
//                onPressed: null
//            )
//          ],
//          iconTheme: new IconThemeData(color: Colors.white),
//          backgroundColor: ThemeUtils.currentColorTheme
//      );
//    }
//    return new AppBar(
//        title: new Center(
//            child: new Text(
//                appBarTitles[_tabIndex],
//                style: new TextStyle(color: Colors.white)
//            )
//        ),
//        iconTheme: new IconThemeData(color: Colors.white),
//        backgroundColor: ThemeUtils.currentColorTheme
//    );
//  }

  Widget searchBar() {
    return new Padding(
      padding: EdgeInsets.all(4.0),
      child: new Row(
        children: <Widget>[
          new Container(
            width: 40.0,
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              image: new DecorationImage(
                  image: new NetworkImage(Api.userFace+"?uid=null&size=f100"),
                  fit: BoxFit.contain
              ),
              border: new Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
          ),
          new Text(
              appBarTitles[_tabIndex],
              style: new TextStyle(color: themeColor)
          )
        ]
      )
    );
  }

  WillPopScope mainPage(context) {
    _body = new IndexedStack(
      children: pages,
      index: _tabIndex,
    );
    return new WillPopScope(
        onWillPop: doubleClickBack,
        child: new Scaffold(
//          appBar: new AppBar(
//            title: new Center(
//                child: new Text(
//                    appBarTitles[_tabIndex],
//                    style: new TextStyle(color: themeColor)
//                )
//            ),
//            iconTheme: new IconThemeData(color: themeColor),
//            brightness: currentBrightness,
//          ),
          appBar: new PreferredSize(
            preferredSize: Size.fromHeight(48.0),
            child: new Container(
              color: ThemeUtils.currentPrimaryColor,
              child: SafeArea(
                  child: searchBar()
              )
            )
//            title: new Center(
//                child: new Text(
//                    appBarTitles[_tabIndex],
//                    style: new TextStyle(color: themeColor)
//                )
//            ),
//            iconTheme: new IconThemeData(color: themeColor),
//            brightness: currentBrightness,
          ),
          body: _body,
          //Tabbarview:new TabBarView(

          bottomNavigationBar: new BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[

              BottomNavigationBarItem(
                  activeIcon: Icon(Icons.home, color: themeColor),
                  icon: Icon(Icons.home, color: Colors.grey),
                  title: getTabTitle(0)
              ),
              BottomNavigationBarItem(
                  activeIcon: Icon(Icons.fiber_new, color: themeColor),
                  icon: Icon(Icons.fiber_new, color: Colors.grey),
                  title: getTabTitle(1)
              ),
              BottomNavigationBarItem(
                  activeIcon: Icon(Icons.apps, color: themeColor),
                  icon: Icon(Icons.apps, color: Colors.grey),
                  title: getTabTitle(2)
              ),
              BottomNavigationBarItem(
                  activeIcon: Icon(Icons.chat, color: themeColor),
                  icon: Icon(Icons.chat, color: Colors.grey),
                  title: getTabTitle(3)
              ),
              BottomNavigationBarItem(
                  activeIcon: Icon(Icons.account_circle, color: themeColor),
                  icon: Icon(Icons.account_circle, color: Colors.grey),
                  title: getTabTitle(4)
              )
            ],
            currentIndex: _tabIndex,
            onTap: (index) {
              setState((){
                _tabIndex = index;
              });
            },
          ),
        )
    );
  }
}
