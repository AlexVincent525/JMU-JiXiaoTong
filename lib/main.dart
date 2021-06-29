import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide SizeExtension;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/constants.dart' hide PageRouteType;
import 'openjmu_route.dart';
import 'pages/no_network_page.dart';
import 'pages/no_route_page.dart';
import 'pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In order to compare the default avatar locally, here I decide to compare
  // the data of the avatar with a local one.
  rootBundle.load(R.ASSETS_AVATAR_PLACEHOLDER_152_PNG).then((ByteData bd) {
    Instances.defaultAvatarData = bd.buffer.asUint8List().toString();
  });

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: Colors.transparent,
  ));

  await Hive.initFlutter();
  await HiveBoxes.openBoxes();
  await Future.wait(
    <Future<void>>[
      DeviceUtils.initDeviceInfo(),
      PackageUtils.initPackageInfo(),
      /// 加载Mock数据
      NetUtils.loadMockSources(),
      NetUtils.initConfig(),
    ],
    eagerError: true,
  );
  NotificationUtils.initSettings();
  _customizeErrorWidget();

  runApp(OpenJMUApp());
}

class OpenJMUApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => OpenJMUAppState();
}

class OpenJMUAppState extends State<OpenJMUApp> with WidgetsBindingObserver {
  StreamSubscription<ConnectivityResult> connectivitySubscription;

  Brightness get _platformBrightness =>
      Screens.mediaQuery.platformBrightness ?? Brightness.light;

  ToastFuture connectivityToastFuture;

  @override
  void initState() {
    super.initState();

    LogUtils.d('Current platform is: ${Platform.operatingSystem}');
    WidgetsBinding.instance.addObserver(this);
    tryRecoverLoginInfo();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Connectivity().checkConnectivity().then(connectivityHandler);
    });
    connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(connectivityHandler);

    Instances.eventBus
      ..on<TicketGotEvent>().listen((TicketGotEvent event) {
        MessageUtils.initMessageSocket();
        if (currentUser.isTeacher != true) {
          if (currentUser.isPostgraduate != true) {
            currentContext.read<CoursesProvider>().initCourses();
            currentContext.read<ScoresProvider>().initScore();
          }
        }
        currentContext.read<MessagesProvider>().initMessages();
        currentContext.read<NotificationProvider>().initNotification();
        currentContext.read<ReportRecordsProvider>().initRecords();
//        currentContext.read<SettingsProvider>().getCloudSettings();
        currentContext.read<SignProvider>().getSignStatus();
        currentContext.read<WebAppsProvider>().initApps();
        if (UserAPI.backpackItemTypes.isEmpty) {
          UserAPI.getBackpackItemType();
        }
        UserAPI.initializeBlacklist();
        initPushService();
      })
      ..on<LogoutEvent>().listen((LogoutEvent event) {
        navigatorState.pushNamedAndRemoveUntil(
          Routes.openjmuLogin.name,
          (_) => false,
        );
        if (currentUser.isTeacher != true) {
          if (currentUser.isPostgraduate != true) {
            currentContext.read<CoursesProvider>().unloadCourses();
            currentContext.read<ScoresProvider>().unloadScore();
          }
        }
        currentContext.read<MessagesProvider>().unloadMessages();
        currentContext.read<NotificationProvider>().stopNotification();
        currentContext.read<ReportRecordsProvider>().unloadRecords();
        currentContext.read<SignProvider>().resetSignStatus();
        currentContext.read<WebAppsProvider>().unloadApps();
        UserAPI.backpackItemTypes.clear();
        Future<void>.delayed(250.milliseconds, () {
          currentContext.read<ThemesProvider>().resetTheme();
          currentContext.read<SettingsProvider>().reset();
        });
        DataUtils.logout();
      })
      ..on<FontScaleUpdateEvent>().listen((_) {
        if (mounted) {
          _rebuildAllChildren(context);
        }
      })
      ..on<HasUpdateEvent>().listen(PackageUtils.showUpdateDialog);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    LogUtils.d('AppLifecycleState change to: ${state.toString()}');
    if (state == AppLifecycleState.resumed &&
        Instances.appLifeCycleState != AppLifecycleState.resumed) {
      Future<void>.delayed(
        const Duration(seconds: 1),
        DeviceUtils.setHighestRefreshRate,
      );
      currentContext.read<NotificationProvider>().initNotification();
    } else {
      currentContext.read<NotificationProvider>().stopNotification();
    }
    Instances.appLifeCycleState = state;
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> tryRecoverLoginInfo() async {
    if (DataUtils.isLogin()) {
      DataUtils.recoverLoginInfo();
    } else {
      Instances.eventBus.fire(TicketFailedEvent());
    }
    if (mounted) {
      setState(() {});
    }
  }

  void connectivityHandler(ConnectivityResult result) {
    NetUtils.testClassKit();
    checkIfNoConnectivity(result);
    Instances.eventBus.fire(ConnectivityChangeEvent(result));
    Instances.connectivityResult = result;
    LogUtils.d('Current connectivity: $result');
  }

  void checkIfNoConnectivity(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      connectivityToastFuture ??= showNoNetworkPage(context);
    } else {
      connectivityToastFuture?.dismiss(showAnim: true);
      if (connectivityToastFuture != null) {
        connectivityToastFuture = null;
      }
    }
  }

  void initPushService() {
    try {
      final Map<String, dynamic> data = <String, dynamic>{
        'token': DeviceUtils.devicePushToken,
        'date': DateFormat('yyyy/MM/dd HH:mm:ss', 'en').format(DateTime.now()),
        'uid': currentUser.uid,
        'name': currentUser.name ?? currentUser.uid,
        'workid': currentUser.workId ?? currentUser.uid,
        'buildnumber': PackageUtils.buildNumber,
        'uuid': DeviceUtils.deviceUuid,
        'platform': Platform.isIOS ? 'ios' : 'android',
      };
      LogUtils.d('Push data: $data');
      NetUtils.post<void>(API.pushUpload, data: data).then((dynamic _) {
        LogUtils.d('Push service info upload success.');
      }).catchError((dynamic e) {
        LogUtils.e('Push service upload error: $e', withStackTrace: false);
      });
    } catch (e) {
      LogUtils.e('Push service init error: $e');
    }
  }

  ToastFuture showNoNetworkPage(BuildContext context) {
    return showToastWidget(
      const NoNetworkPage(),
      duration: 999.weeks,
      handleTouch: true,
      position: ToastPosition.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Consumer2<ThemesProvider, SettingsProvider>(
        builder: (
          _,
          ThemesProvider themesProvider,
          SettingsProvider settingsProvider,
          __,
        ) {
          final bool isDark = themesProvider.platformBrightness
              ? _platformBrightness == Brightness.dark
              : themesProvider.dark;
          final ThemeData theme =
              (isDark ? themesProvider.darkTheme : themesProvider.lightTheme)
                  .copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
              },
            ),
          );
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value:
                isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: Theme(
              data: theme,
              child: OKToast(
                position: ToastPosition.bottom,
                textPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 14),
                child: MaterialApp(
                  navigatorKey: Instances.navigatorKey,
                  builder: (BuildContext c, Widget w) {
                    ScreenUtil.init(c, allowFontScaling: true);
                    Widget widget = ScrollConfiguration(
                      behavior: const NoGlowScrollBehavior(),
                      child: NoScaleTextWidget(child: w),
                    );
                    if (Platform.isIOS && Screens.topSafeHeight >= 42) {
                      widget = Stack(
                        children: <Widget>[
                          Positioned.fill(child: widget),
                          const _HiddenLogo(),
                        ],
                      );
                    }
                    return RepaintBoundary(
                      key: Instances.appRepaintBoundaryKey,
                      child: widget,
                    );
                  },
                  title: 'OpenJMU',
                  theme: theme,
                  home: const SplashPage(),
                  navigatorObservers: <NavigatorObserver>[
                    Instances.routeObserver,
                  ],
                  onGenerateRoute: (RouteSettings settings) => onGenerateRoute(
                    settings: settings,
                    getRouteSettings: getRouteSettings,
                    notFoundWidget: NoRoutePage(route: settings.name),
                  ),
                  localizationsDelegates: Constants.localizationsDelegates,
                  supportedLocales: Constants.supportedLocales,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HiddenLogo extends StatelessWidget {
  const _HiddenLogo({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 0,
      end: 0,
      top: 0,
      height: Screens.topSafeHeight,
      child: Center(
        child: SvgPicture.asset(
          R.IMAGES_OPENJMU_LOGO_TEXT_SVG,
          color: defaultLightColor,
          height: Screens.topSafeHeight * 0.3,
        ),
      ),
    );
  }
}

void _rebuildAllChildren(BuildContext context) {
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}

void _customizeErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(30.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.w),
          color: currentTheme.accentColor.withOpacity(0.125),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              R.ASSETS_PLACEHOLDERS_NO_NETWORK_SVG,
              width: 50.w,
              color: currentTheme.iconTheme.color,
            ),
            VGap(20.w),
            Text(
              '出现了不可预料的错误 (>_<)',
              style: TextStyle(
                color: currentTheme.textTheme.caption.color,
                fontSize: 22.sp,
              ),
            ),
            VGap(10.w),
            Text(
              details.exception.toString(),
              style: TextStyle(
                color: currentTheme.textTheme.caption.color,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            VGap(10.w),
            Text(
              details.stack.toString(),
              style: TextStyle(
                color: currentTheme.textTheme.caption.color,
                fontSize: 16.sp,
              ),
              maxLines: 14,
              overflow: TextOverflow.ellipsis,
            ),
            VGap(20.w),
            Tapper(
              onTap: _takeAppScreenshot,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13.w),
                  color: currentTheme.accentColor,
                ),
                child: Text(
                  '保存当前位置错误截图',
                  style: TextStyle(
                    color: adaptiveButtonColor(),
                    fontSize: 20.sp,
                    height: 1.24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  };
}

Future<void> _takeAppScreenshot() async {
  try {
    final ByteData byteData = await obtainScreenshotData(
      Instances.appRepaintBoundaryKey,
    );
    await PhotoManager.editor.saveImage(byteData.buffer.asUint8List());
    showToast('截图保存成功');
  } catch (e) {
    LogUtils.e('Error when taking app\'s screenshot: $e');
    showCenterErrorToast('截图保存失败');
  }
}
