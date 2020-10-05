// GENERATED CODE - DO NOT MODIFY MANUALLY
// **************************************************************************
// Auto generated by https://github.com/fluttercandies/ff_annotation_route
// **************************************************************************
// ignore_for_file: argument_type_not_assignable

import 'package:flutter/widgets.dart';

import 'pages/chat/chat_app_message_page.dart';
import 'pages/home/app_center_page.dart';
import 'pages/home/scan_qr_code_page.dart';
import 'pages/home/search_page.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'pages/news/news_detail_page.dart';
import 'pages/notification/notifications_page.dart';
import 'pages/post/post_detail_page.dart';
import 'pages/post/publish_post_page.dart';
import 'pages/post/publish_team_post_page.dart';
import 'pages/post/team_post_detail_page.dart';
import 'pages/settings/about_page.dart';
import 'pages/settings/change_theme_page.dart';
import 'pages/settings/changelog_page.dart';
import 'pages/settings/font_scale_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/settings/switch_start_up_page.dart';
import 'pages/splash_page.dart';
import 'pages/user/backpack_page.dart';
import 'pages/user/edit_profile_page.dart';
import 'pages/user/user_list_page.dart';
import 'pages/user/user_page.dart';
import 'pages/user/user_qrcode_page.dart';
import 'widgets/dialogs/comment_positioned.dart';
import 'widgets/dialogs/forward_positioned.dart';
import 'widgets/image/image_crop_page.dart';
import 'widgets/image/image_viewer.dart';
import 'widgets/webview/in_app_webview.dart';

RouteResult getRouteResult({String name, Map<String, dynamic> arguments}) {
  arguments = arguments ?? const <String, dynamic>{};
  switch (name) {
    case 'openjmu://about':
      return RouteResult(
        name: name,
        widget: AboutPage(),
        routeName: '关于页',
      );
    case 'openjmu://add-comment':
      return RouteResult(
        name: name,
        widget: CommentPositioned(
          post: arguments['post'],
          comment: arguments['comment'],
        ),
        routeName: '新增评论',
        pageRouteType: PageRouteType.transparent,
      );
    case 'openjmu://add-forward':
      return RouteResult(
        name: name,
        widget: ForwardPositioned(
          post: arguments['post'],
        ),
        routeName: '新增转发',
        pageRouteType: PageRouteType.transparent,
      );
    case 'openjmu://app-center-page':
      return RouteResult(
        name: name,
        widget: AppCenterPage(),
        routeName: '应用中心',
      );
    case 'openjmu://backpack':
      return RouteResult(
        name: name,
        widget: BackpackPage(),
        routeName: '背包页',
      );
    case 'openjmu://changelog-page':
      return RouteResult(
        name: name,
        widget: ChangeLogPage(),
        routeName: '版本履历',
      );
    case 'openjmu://chat-app-message-page':
      return RouteResult(
        name: name,
        widget: ChatAppMessagePage(
          app: arguments['app'],
        ),
        routeName: '应用消息页',
      );
    case 'openjmu://edit-profile-page':
      return RouteResult(
        name: name,
        widget: EditProfilePage(),
        routeName: '编辑资料页',
      );
    case 'openjmu://font-scale':
      return RouteResult(
        name: name,
        widget: FontScalePage(),
        routeName: '更改字号页',
      );
    case 'openjmu://home':
      return RouteResult(
        name: name,
        widget: MainPage(
          initAction: arguments['initAction'],
        ),
        routeName: '首页',
      );
    case 'openjmu://image-crop':
      return RouteResult(
        name: name,
        widget: ImageCropPage(),
        routeName: '图片裁剪',
      );
    case 'openjmu://image-viewer':
      return RouteResult(
        name: name,
        widget: ImageViewer(
          index: arguments['index'],
          pics: arguments['pics'],
          needsClear: arguments['needsClear'],
          post: arguments['post'],
          heroPrefix: arguments['heroPrefix'],
        ),
        routeName: '图片浏览',
        pageRouteType: PageRouteType.transparent,
      );
    case 'openjmu://in-app-webview':
      return RouteResult(
        name: name,
        widget: InAppWebViewPage(
          url: arguments['url'],
          title: arguments['title'],
          app: arguments['app'],
          withCookie: arguments['withCookie'],
          withAppBar: arguments['withAppBar'],
          withAction: arguments['withAction'],
          withScaffold: arguments['withScaffold'],
          keepAlive: arguments['keepAlive'],
        ),
        routeName: '网页浏览',
      );
    case 'openjmu://login':
      return RouteResult(
        name: name,
        widget: LoginPage(),
        routeName: '登录页',
      );
    case 'openjmu://news-detail':
      return RouteResult(
        name: name,
        widget: NewsDetailPage(
          news: arguments['news'],
        ),
        routeName: '新闻详情页',
      );
    case 'openjmu://notifications':
      return RouteResult(
        name: name,
        widget: NotificationsPage(
          initialPage: arguments['initialPage'],
        ),
        routeName: '通知页',
        pageRouteType: PageRouteType.transparent,
      );
    case 'openjmu://post-detail':
      return RouteResult(
        name: name,
        widget: PostDetailPage(
          post: arguments['post'],
          index: arguments['index'],
          fromPage: arguments['fromPage'],
          parentContext: arguments['parentContext'],
        ),
        routeName: '动态详情页',
      );
    case 'openjmu://publish-post':
      return RouteResult(
        name: name,
        widget: PublishPostPage(),
        routeName: '发布动态',
      );
    case 'openjmu://publish-team-post':
      return RouteResult(
        name: name,
        widget: PublishTeamPostPage(),
        routeName: '发布小组动态',
      );
    case 'openjmu://scan-qr-code':
      return RouteResult(
        name: name,
        widget: ScanQrCodePage(),
        routeName: '扫描二维码',
      );
    case 'openjmu://search':
      return RouteResult(
        name: name,
        widget: SearchPage(
          content: arguments['content'],
        ),
        routeName: '搜索页',
      );
    case 'openjmu://settings':
      return RouteResult(
        name: name,
        widget: SettingsPage(),
        routeName: '设置页',
      );
    case 'openjmu://splash':
      return RouteResult(
        name: name,
        widget: SplashPage(
          initAction: arguments['initAction'],
        ),
        routeName: '启动页',
      );
    case 'openjmu://switch-startup':
      return RouteResult(
        name: name,
        widget: SwitchStartUpPage(),
        routeName: '切换启动页',
      );
    case 'openjmu://team-post-detail':
      return RouteResult(
        name: name,
        widget: TeamPostDetailPage(
          provider: arguments['provider'],
          type: arguments['type'],
          postId: arguments['postId'],
        ),
        routeName: '小组动态详情页',
      );
    case 'openjmu://theme':
      return RouteResult(
        name: name,
        widget: ChangeThemePage(),
        routeName: '更改主题',
      );
    case 'openjmu://user-list-page':
      return RouteResult(
        name: name,
        widget: UserListPage(
          user: arguments['user'],
          type: arguments['type'],
        ),
        routeName: '用户列表页',
      );
    case 'openjmu://user-page':
      return RouteResult(
        name: name,
        widget: UserPage(
          uid: arguments['uid'],
        ),
        routeName: '用户页',
      );
    case 'openjmu://user-qr-code':
      return RouteResult(
        name: name,
        widget: UserQrCodePage(),
        routeName: '用户二维码页',
        pageRouteType: PageRouteType.transparent,
      );
    default:
      return const RouteResult(name: 'flutterCandies://notfound');
  }
}

class RouteResult {
  const RouteResult({
    @required this.name,
    this.widget,
    this.showStatusBar = true,
    this.routeName = '',
    this.pageRouteType,
    this.description = '',
    this.exts,
  });

  /// The name of the route (e.g., "/settings").
  ///
  /// If null, the route is anonymous.
  final String name;

  /// The Widget return base on route
  final Widget widget;

  /// Whether show this route with status bar.
  final bool showStatusBar;

  /// The route name to track page
  final String routeName;

  /// The type of page route
  final PageRouteType pageRouteType;

  /// The description of route
  final String description;

  /// The extend arguments
  final Map<String, dynamic> exts;
}

enum PageRouteType {
  material,
  cupertino,
  transparent,
}
