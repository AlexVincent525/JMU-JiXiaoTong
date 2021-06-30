///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-11-18 11:47
///
import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/pages/post/team_post_detail_page.dart';

class TeamPostCard extends StatefulWidget {
  const TeamPostCard({
    Key key,
    @required this.post,
    @required this.detailPageState,
  }) : super(key: key);

  final TeamPost post;
  final TeamPostDetailPageState detailPageState;

  @override
  _TeamPostCardState createState() => _TeamPostCardState();
}

class _TeamPostCardState extends State<TeamPostCard> {
  TeamPost post;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    TeamPostAPI.getPostDetail(id: widget.post.tid).then(
      (Response<Map<String, dynamic>> response) {
        final TeamPost _post = TeamPost.fromJson(response.data);
        post = _post;
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 70.w,
      padding: EdgeInsets.symmetric(vertical: 6.w),
      child: Row(
        children: <Widget>[
          UserAvatar(uid: post.uid, isSysAvatar: post.userInfo.sysAvatar),
          Gap(16.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      post.nickname ?? post.uid.toString(),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (Constants.developerList.contains(post.uid))
                      Padding(
                        padding: EdgeInsets.only(left: 6.w),
                        child: const DeveloperTag(),
                      ),
                  ],
                ),
                _postTime(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postTime(BuildContext context) {
    return Text(
      TeamPostAPI.timeConverter(post),
      style: context.textTheme.caption.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget get _content => Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: ExtendedText(
          post.article ?? post.content ?? '',
          style: TextStyle(fontSize: 19.sp),
          onSpecialTextTap: specialTextTapRecognizer,
          specialTextSpanBuilder: StackSpecialTextSpanBuilder(),
        ),
      );

  Widget _images(BuildContext context) {
    final List<Widget> imagesWidget = <Widget>[];
    for (int index = 0; index < post.pics.length; index++) {
      final int imageId = (post.pics[index]['fid'] as String).toInt();
      // final String imageUrl = API.teamFile(fid: imageId);
      final String imageUrl = (post.pics[index]['image_mock'] as String)+ '?timestamp=${Random().nextInt(500)}';
      Widget _exImage = ExtendedImage.network(
        imageUrl,
        fit: BoxFit.cover,
        cache: true,
        color: currentIsDark ? Colors.black.withAlpha(50) : null,
        colorBlendMode: currentIsDark ? BlendMode.darken : BlendMode.srcIn,
        loadStateChanged: (ExtendedImageState state) {
          Widget loader;
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              loader = DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.w),
                  color: context.theme.dividerColor,
                ),
              );
              break;
            case LoadState.completed:
              final ImageInfo info = state.extendedImageInfo;
              if (info != null) {
                loader = ScaledImage(
                  image: info.image,
                  length: post.pics.length,
                  num200: 200.w,
                  num400: 400.w,
                );
              }
              break;
            case LoadState.failed:
              break;
          }
          return loader;
        },
      );
      _exImage = Tapper(
        onTap: () {
          navigatorState.pushNamed(
            Routes.openjmuImageViewer.name,
            arguments: Routes.openjmuImageViewer.d(
              index: index,
              pics: post.pics.map<ImageBean>((Map<dynamic, dynamic> f) {
                // final int imageId = f['fid'].toString().toInt();
                // final String imageUrl = API.teamFile(fid: imageId);
                final String imageUrl = (f['image_mock'] as String)+ '?timestamp=${Random().nextInt(500)}';
                return ImageBean(
                  id: f['fid'].toString().toInt(),
                  imageUrl: imageUrl,
                  imageThumbUrl: imageUrl,
                  postId: post.tid,
                );
              }).toList(),
              heroPrefix: 'team-post-image-',
            ),
          );
        },
        child: _exImage,
      );
      _exImage = Hero(
        tag: 'team-post-image-${post.tid}-$imageId',
        child: _exImage,
        placeholderBuilder: (_, __, Widget child) => child,
      );
      imagesWidget.add(_exImage);
    }
    Widget _image;
    if (post.pics.length == 1) {
      _image = Align(
        alignment: Alignment.topLeft,
        child: imagesWidget[0],
      );
    } else if (post.pics.length > 1) {
      _image = GridView.count(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        primary: false,
        mainAxisSpacing: 10.sp,
        crossAxisCount: 3,
        crossAxisSpacing: 10.sp,
        children: imagesWidget,
      );
    }
    _image = Padding(
      padding: EdgeInsets.symmetric(vertical: 10.w),
      child: _image,
    );
    return _image;
  }

  Widget get _praisors {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
      decoration: BoxDecoration(
        border: Border(
          top: dividerBS(context),
        ),
        color: context.surfaceColor,
      ),
      child: Row(
        children: <Widget>[
          SvgPicture.asset(
            R.ASSETS_ICONS_POST_ACTIONS_PRAISE_FILL_SVG,
            width: 24.w,
            color: currentThemeColor,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: context.textTheme.caption.copyWith(
                        height: 1.2,
                        fontSize: 16.sp,
                      ),
                      child: Text(
                        <String>[
                          ...post.praisor
                              .sublist(0, math.min(post.praisor.length, 3))
                              .map((PostUser user) => user.nickname)
                              .toList()
                        ].join('、'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Text(
                    '觉得很赞',
                    style: context.textTheme.caption.copyWith(
                      height: 1.2,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 40.w,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(post.praisor.length, 3),
              itemBuilder: (_, int index) => UserAvatar(
                uid: post.praisor[index].uid,
                size: 40,
                isSysAvatar: post.praisor[index].sysAvatar,
              ),
              separatorBuilder: (_, __) => Gap(10.w),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tapper(
      onTap: widget.detailPageState.setReplyToTop,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 8.w,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.w),
              color: context.surfaceColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(context),
                _content,
                if (post.pics?.isNotEmpty ?? false) _images(context),
              ],
            ),
          ),
          if (post.praisor?.isNotEmpty == true) _praisors,
        ],
      ),
    );
  }
}
