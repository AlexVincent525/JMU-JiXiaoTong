// GENERATED CODE - DO NOT MODIFY MANUALLY
// **************************************************************************
// Auto generated by https://github.com/fluttercandies/ff_annotation_route
// **************************************************************************

import 'package:ff_annotation_route/ff_annotation_route.dart';
import 'package:flutter/widgets.dart';
import 'package:openjmu/pages/notification/notifications_page.dart';
import 'model/models.dart';
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
import 'pages/settings/changelog_page.dart';
import 'pages/settings/font_scale_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/settings/switch_start_up_page.dart';
import 'pages/splash_page.dart';
import 'pages/user/backpack_page.dart';
import 'pages/user/user_list_page.dart';
import 'pages/user/user_page.dart';
import 'pages/user/user_qrcode_page.dart';
import 'providers/providers.dart';
import 'widgets/dialogs/edit_signature_dialog.dart';
import 'widgets/image/image_crop_page.dart';
import 'widgets/image/image_viewer.dart';

RouteResult getRouteResult({String name, Map<String, dynamic> arguments}) {
  arguments = arguments ?? const <String, dynamic>{};
  switch (name) {
    case 'openjmu://app-center-page':
      return RouteResult(
        name: name,
        widget: AppCenterPage(
          key: arguments['key'] as Key,
        ),
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
          app: arguments['app'] as WebApp,
          key: arguments['key'] as Key,
        ),
        routeName: '应用消息页',
      );
    case 'openjmu://edit-avatar-page':
      return RouteResult(
        name: name,
        widget: EditAvatarPage(
          key: arguments['key'] as Key,
        ),
        routeName: '修改头像',
      );
    case 'openjmu://edit-signature-dialog':
      return RouteResult(
        name: name,
        widget: EditSignatureDialog(
          key: arguments['key'] as Key,
        ),
        routeName: '编辑个性签名',
        pageRouteType: PageRouteType.transparent,
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
          key: arguments['key'] as Key,
          initAction: arguments['initAction'] as int,
        ),
        routeName: '首页',
      );
    case 'openjmu://image-viewer':
      return RouteResult(
        name: name,
        widget: ImageViewer(
          index: arguments['index'] as int,
          pics: arguments['pics'] as List<ImageBean>,
          heroPrefix: arguments['heroPrefix'] as String,
          needsClear: arguments['needsClear'] as bool ?? false,
          post: arguments['post'] as Post,
        ),
        routeName: '图片浏览',
        pageRouteType: PageRouteType.transparent,
      );
    case 'openjmu://login':
      return RouteResult(
        name: name,
        widget: LoginPage(
          key: arguments['key'] as Key,
          initAction: arguments['initAction'] as int,
        ),
        routeName: '登录页',
      );
    case 'openjmu://news-detail':
      return RouteResult(
        name: name,
        widget: NewsDetailPage(
          key: arguments['key'] as Key,
          news: arguments['news'] as News,
        ),
        routeName: '新闻详情页',
      );
    case 'openjmu://notifications-page':
      return RouteResult(
        name: name,
        widget: NotificationsPage(
          key: arguments['key'] as Key,
          pageType: arguments['pageType'] as NotificationPageType,
        ),
        routeName: '通知页',
        pageRouteType: PageRouteType.transparent,
      );
    case 'openjmu://post-detail':
      return RouteResult(
        name: name,
        widget: PostDetailPage(
          post: arguments['post'] as Post,
          index: arguments['index'] as int,
          fromPage: arguments['fromPage'] as String,
          parentContext: arguments['parentContext'] as BuildContext,
        ),
        routeName: '动态详情页',
      );
    case 'openjmu://publish-post':
      return RouteResult(
        name: name,
        widget: PublishPostPage(
          key: arguments['key'] as Key,
        ),
        routeName: '发布动态',
      );
    case 'openjmu://publish-team-post':
      return RouteResult(
        name: name,
        widget: PublishTeamPostPage(
          key: arguments['key'] as Key,
        ),
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
          content: arguments['content'] as String,
        ),
        routeName: '搜索页',
      );
    case 'openjmu://settings':
      return RouteResult(
        name: name,
        widget: SettingsPage(
          key: arguments['key'] as Key,
        ),
        routeName: '设置页',
      );
    case 'openjmu://splash':
      return RouteResult(
        name: name,
        widget: SplashPage(
          key: arguments['key'] as Key,
          initAction: arguments['initAction'] as int,
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
          key: arguments['key'] as Key,
          type: arguments['type'] as TeamPostType,
          provider: arguments['provider'] as TeamPostProvider,
          postId: arguments['postId'] as int,
          shouldReload: arguments['shouldReload'] as bool ?? false,
        ),
        routeName: '小组动态详情页',
      );
    case 'openjmu://user-list-page':
      return RouteResult(
        name: name,
        widget: UserListPage(
          key: arguments['key'] as Key,
          user: arguments['user'] as UserInfo,
          type: arguments['type'] as int,
        ),
        routeName: '用户列表页',
      );
    case 'openjmu://user-page':
      return RouteResult(
        name: name,
        widget: UserPage(
          key: arguments['key'] as Key,
          uid: arguments['uid'] as String,
        ),
        routeName: '用户页',
      );
    case 'openjmu://user-qr-code':
      return RouteResult(
        name: name,
        widget: UserQrCodePage(
          key: arguments['key'] as Key,
        ),
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
