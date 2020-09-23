///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2020-03-10 14:44
///
import 'package:flutter/material.dart';

import 'package:openjmu/constants/constants.dart';

class PostSquarePage extends StatelessWidget {
  const PostSquarePage({Key key}) : super(key: key);

  Widget publishButton(BuildContext context) => MaterialButton(
        color: currentThemeColor,
        minWidth: suSetWidth(120.0),
        height: suSetHeight(50.0),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(suSetWidth(13.0)),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: suSetWidth(6.0)),
              child: SvgPicture.asset(
                R.ASSETS_ICONS_SEND_SVG,
                height: suSetHeight(22.0),
                color: Colors.white,
              ),
            ),
            Text(
              '发动态',
              style: TextStyle(
                color: Colors.white,
                fontSize: suSetSp(20.0),
                height: 1.24,
              ),
            ),
          ],
        ),
        onPressed: () {
          Navigator.of(context).pushNamed(Routes.openjmuPublishPost);
        },
      );

  Widget get notificationButton => Consumer<NotificationProvider>(
        builder: (_, provider, __) {
          return SizedBox(
            width: suSetWidth(60.0),
            child: Stack(
              overflow: Overflow.visible,
              children: <Widget>[
                Positioned(
                  top: suSetHeight(kToolbarHeight / 5),
                  right: suSetWidth(2.0),
                  child: Visibility(
                    visible: provider.showNotification,
                    child: ClipRRect(
                      borderRadius: maxBorderRadius,
                      child: Container(
                        width: suSetWidth(12.0),
                        height: suSetWidth(12.0),
                        color: currentThemeColor,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  alignment: Alignment.centerRight,
                  icon: SvgPicture.asset(
                    R.ASSETS_ICONS_LIUYAN_LINE_SVG,
                    color: currentTheme.iconTheme.color,
                    width: suSetWidth(32.0),
                    height: suSetWidth(32.0),
                  ),
                  onPressed: () async {
                    provider.stopNotification();
                    await navigatorState.pushNamed(
                      Routes.openjmuNotifications,
                      arguments: <String, dynamic>{'initialPage': '广场'},
                    );
                    provider.initNotification();
                  },
                ),
              ],
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return FixedAppBarWrapper(
      appBar: FixedAppBar(
        automaticallyImplyLeading: false,
        elevation: 1.0,
        title: Padding(
          padding: EdgeInsets.only(right: 20.0.w),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: Instances.mainPageScaffoldKey.currentState.openDrawer,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 12.0.w, right: 10.0.w),
                      child: SvgPicture.asset(
                        R.ASSETS_ICONS_SELF_PAGE_AVATAR_CORNER_SVG,
                        color: currentTheme.iconTheme.color,
                        width: 8.0.w,
                        height: 20.0.w,
                      ),
                    ),
                    UserAvatar(size: 54.0, canJump: false)
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          notificationButton,
          publishButton(context),
        ],
        actionsPadding: EdgeInsets.only(right: 20.0.w),
      ),
      body: Container(
        color: Theme.of(context).canvasColor,
        child: PostList(
          PostController(
            postType: 'square',
            isFollowed: false,
            isMore: false,
            lastValue: (int id) => id,
          ),
          needRefreshIndicator: true,
          scrollController: ScrollController(),
        ),
      ),
    );
  }
}
