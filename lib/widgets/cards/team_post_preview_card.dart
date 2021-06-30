///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-11-17 06:15
///
import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:like_button/like_button.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/controller/extended_typed_network_image_provider.dart';

class TeamPostPreviewCard extends StatelessWidget {
  const TeamPostPreviewCard({@required Key key}) : super(key: key);

  Future<void> confirmDelete(BuildContext context) async {
    final bool confirm = await ConfirmationDialog.show(
      context,
      title: '删除动态',
      content: '是否删除该条动态?',
      showConfirm: true,
    );
    if (confirm) {
      delete(context);
    }
  }

  void delete(BuildContext context) {
    final TeamPostProvider provider =
        Provider.of<TeamPostProvider>(context, listen: false);
    final TeamPost post = provider.post;
    TeamPostAPI.deletePost(postId: post.tid, postType: 7).then((dynamic _) {
      showToast('删除成功');
      Instances.eventBus.fire(TeamPostDeletedEvent(postId: post.tid));
    });
  }

  void confirmAction(BuildContext context) {
    final TeamPostProvider provider =
        Provider.of<TeamPostProvider>(context, listen: false);
    final TeamPost post = provider.post;
    ConfirmationBottomSheet.show(
      context,
      actions: <ConfirmationBottomSheetAction>[
        ConfirmationBottomSheetAction(
          text: '${UserAPI.blacklist.contains(
            BlacklistUser(uid: post.uid, username: post.nickname),
          ) ? '移出' : '加入'}黑名单',
          onTap: () => UserAPI.confirmBlock(
            context,
            BlacklistUser(uid: post.uid, username: post.nickname),
          ),
        ),
        ConfirmationBottomSheetAction(
          text: '举报动态',
          onTap: () => confirmReport(context),
        ),
      ],
    );
  }

  Future<void> confirmReport(BuildContext context) async {
    final TeamPostProvider provider =
        Provider.of<TeamPostProvider>(context, listen: false);
    final TeamPost post = provider.post;
    final bool confirm = await ConfirmationDialog.show(
      context,
      title: '举报动态',
      content: '您正在举报一条动态，请确认操作',
      showConfirm: true,
    );
    if (confirm) {
      TeamPostAPI.reportPost(post);
      showToast('举报成功');
    }
  }

  Widget deleteButton(BuildContext context) {
    return Tapper(
      onTap: () => confirmDelete(context),
      child: Container(
        width: 48.w,
        height: 48.w,
        alignment: AlignmentDirectional.topEnd,
        child: SizedBox.fromSize(
          size: Size.square(24.w),
          child: AspectRatio(
            aspectRatio: 1,
            child: SvgPicture.asset(
              R.ASSETS_ICONS_POST_ACTIONS_DELETE_SVG,
              color: context.iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget postActionButton(BuildContext context) {
    return Tapper(
      onTap: () => confirmAction(context),
      child: Container(
        width: 48.w,
        height: 48.w,
        alignment: AlignmentDirectional.topEnd,
        child: SizedBox.fromSize(
          size: Size.square(24.w),
          child: AspectRatio(
            aspectRatio: 1,
            child: SvgPicture.asset(
              R.ASSETS_ICONS_POST_ACTIONS_MORE_SVG,
              color: context.iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, TeamPost post) {
    return Container(
      height: 70.w,
      padding: EdgeInsets.symmetric(vertical: 6.w),
      child: Row(
        children: <Widget>[
          UserAvatar(
            uid: post.uid,
            isSysAvatar: post.userInfo.sysAvatar,
          ),
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
                      style: context.textTheme.bodyText2.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (Constants.developerList.contains(post.uid))
                      Padding(
                        padding: EdgeInsets.only(left: 6.w),
                        child: const DeveloperTag(),
                      ),
                  ],
                ),
                _postTime(context, post),
              ],
            ),
          ),
          if (post.uid == currentUser.uid)
            deleteButton(context)
          else
            postActionButton(context),
        ],
      ),
    );
  }

  Widget _postTime(BuildContext context, TeamPost post) {
    return Text(
      TeamPostAPI.timeConverter(post),
      style: TextStyle(
        color: context.textTheme.caption.color,
        fontSize: 16.sp,
      ),
    );
  }

  Widget _content(TeamPost post) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: ExtendedText(
          post.content ?? '',
          style: TextStyle(fontSize: 19.sp),
          onSpecialTextTap: specialTextTapRecognizer,
          maxLines: 8,
          overflowWidget: contentOverflowWidget,
          specialTextSpanBuilder: StackSpecialTextSpanBuilder(),
        ),
      );

  Widget _postInfo(BuildContext context, TeamPostProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.post.postInfo.length,
        itemBuilder: (_, int index) {
          final Map<String, dynamic> _post =
              provider.post.postInfo[index].cast<String, dynamic>();
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 4.h,
            ),
            child: ExtendedText(
              _post['content'] as String ?? '',
              specialTextSpanBuilder: StackSpecialTextSpanBuilder(
                prefixSpans: <InlineSpan>[
                  TextSpan(
                    text: '@${_post['user_info']['nickname']}',
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        navigatorState.pushNamed(
                          Routes.openjmuUserPage.name,
                          arguments: Routes.openjmuUserPage.d(
                            uid: _post['user_info']['uid'] as String,
                          ),
                        );
                      },
                  ),
                  if (_post['user_info']['uid'] as String == provider.post.uid)
                    const TextSpan(text: '(楼主)'),
                  const TextSpan(
                    text: ': ',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              style: context.textTheme.caption.copyWith(
                fontSize: 17.sp,
              ),
              onSpecialTextTap: specialTextTapRecognizer,
              maxLines: 3,
              overflowWidget: const TextOverflowWidget(
                child: Text('......'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _images(BuildContext context, TeamPost post) {
    final List<Widget> imagesWidget = <Widget>[];
    for (int i = 0; i < post.pics.length; i++) {
      final int imageId = (post.pics[i]['fid'] as String).toInt();
      // final String imageUrl = API.teamFile(fid: imageId);
      final String imageUrl = (post.pics[i]['image_mock'] as String)+ '?timestamp=${Random().nextInt(500)}';
      final ExtendedTypedNetworkImageProvider provider =
          ExtendedTypedNetworkImageProvider(imageUrl);
      Widget _exImage = ExtendedImage(
        image: provider,
        fit: BoxFit.cover,
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
                  num200: 200.sp,
                  num400: 400.sp,
                  provider: provider,
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
              index: i,
              pics: post.pics.map((Map<dynamic, dynamic> pic) {
                final int id = (pic['fid'] as String).toInt();
                // final String imageUrl = API.teamFile(fid: id);
                final String imageUrl = (pic['image_mock'] as String)+ '?timestamp=${Random().nextInt(500)}';
                return ImageBean(
                  id: id,
                  imageUrl: imageUrl,
                  imageThumbUrl: imageUrl,
                  postId: post.tid,
                );
              }).toList(),
              heroPrefix: 'team-post-preview-image-',
            ),
          );
        },
        child: _exImage,
      );
      _exImage = Hero(
        tag: 'team-post-preview-image-${post.tid}-$imageId',
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
        mainAxisSpacing: 12.w,
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        children: imagesWidget,
      );
    }
    _image = Padding(
      padding: EdgeInsets.only(top: 12.w),
      child: _image,
    );
    return _image;
  }

  Widget _actions(BuildContext context, TeamPostProvider p) {
    return Container(
      margin: EdgeInsets.only(top: 6.w),
      height: 50.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          LikeButton(
            padding: EdgeInsets.symmetric(vertical: 6.w),
            size: 40.w,
            bubblesColor: BubblesColor(
              dotPrimaryColor: currentThemeColor,
              dotSecondaryColor: currentThemeColor,
            ),
            circleColor: CircleColor(
              start: currentThemeColor,
              end: currentThemeColor,
            ),
            countBuilder: (int count, bool isLiked, String text) => Container(
              constraints: BoxConstraints(minWidth: 30.w),
              alignment: Alignment.center,
              child: Text(
                count > 0 ? text : '赞',
                style: TextStyle(
                  color: isLiked ? currentThemeColor : context.iconTheme.color,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            isLiked: p.post.isLike,
            likeBuilder: (bool isLiked) => Center(
              child: SvgPicture.asset(
                R.ASSETS_ICONS_POST_ACTIONS_PRAISE_FILL_SVG,
                color: isLiked ? currentThemeColor : context.iconTheme.color,
                width: 26.w,
              ),
            ),
            likeCount: p.post.isLike
                ? moreThanOne(p.post.praisesCount)
                : moreThanZero(p.post.praisesCount),
            likeCountAnimationType: LikeCountAnimationType.none,
            likeCountPadding: EdgeInsets.only(right: 6.w),
            onTap: (bool isLiked) => onLikeButtonTap(isLiked, p),
          ),
          _actionButton(
            context: context,
            icon: SvgPicture.asset(
              R.ASSETS_ICONS_POST_ACTIONS_COMMENT_FILL_SVG,
              color: context.iconTheme.color,
              width: 26.w,
            ),
            text: '评论',
            value: p.post.repliesCount,
            onTap: () {
              navigatorState.pushNamed(
                Routes.openjmuTeamPostDetail.name,
                arguments: Routes.openjmuTeamPostDetail.d(
                  provider: p,
                  type: TeamPostType.post,
                  toComment: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    BuildContext context,
    Widget icon,
    String text,
    int value,
    VoidCallback onTap,
  }) {
    final String _content = value == 0
        ? text ?? ''
        : value > 999
            ? '999+'
            : '$value';
    return Tapper(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            Gap(6.w),
            Container(
              constraints: BoxConstraints(minWidth: 30.w),
              alignment: Alignment.center,
              child: Text(
                _content,
                style: TextStyle(
                  color: context.iconTheme.color,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<bool> onLikeButtonTap(bool isLiked, TeamPostProvider provider) {
    final Completer<bool> completer = Completer<bool>();

    !isLiked ? provider.praised() : provider.unPraised();
    completer.complete(!isLiked);

    TeamPraiseAPI.requestPraise(provider.post.tid, !isLiked)
        .catchError((dynamic e) {
      isLiked ? provider.praised() : provider.unPraised();
      completer.complete(isLiked);
    });

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamPostProvider>(
      builder: (_, TeamPostProvider p, __) {
        return Tapper(
          onTap: () {
            navigatorState.pushNamed(
              Routes.openjmuTeamPostDetail.name,
              arguments: Routes.openjmuTeamPostDetail.d(
                provider: p,
                type: TeamPostType.post,
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.w,
            ),
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
                _header(context, p.post),
                _content(p.post),
                if (p.post.pics != null && p.post.pics.isNotEmpty)
                  _images(context, p.post),
                if (p.post.postInfo != null && p.post.postInfo.isNotEmpty)
                  _postInfo(context, p),
                Padding(
                  padding: EdgeInsets.only(top: 12.w),
                  child: const LineDivider(),
                ),
                _actions(context, p),
              ],
            ),
          ),
        );
      },
    );
  }
}
