///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-03-28 20:24
///
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:extended_text/extended_text.dart';
import 'package:extended_image/extended_image.dart';
import 'package:like_button/like_button.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/controller/extended_typed_network_image_provider.dart';

class PostCard extends StatefulWidget {
  const PostCard(
    this.post, {
    this.isDetail = false,
    this.isRootContent,
    this.fromPage,
    this.index,
    Key key,
  }) : super(key: key);

  final Post post;
  final bool isDetail;
  final bool isRootContent;
  final String fromPage;
  final int index;

  @override
  State createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final double contentPadding = 16.0;

  Post get post => widget.post;

  @override
  void initState() {
    super.initState();
    Instances.eventBus
      ..on<ForwardInPostUpdatedEvent>()
          .listen((ForwardInPostUpdatedEvent event) {
        if (event.postId == widget.post.id) {
          widget.post.forwards = event.count;
        }
        if (mounted) {
          setState(() {});
        }
      })
      ..on<CommentInPostUpdatedEvent>()
          .listen((CommentInPostUpdatedEvent event) {
        if (event.postId == widget.post.id) {
          widget.post.comments = event.count;
        }
        if (mounted) {
          setState(() {});
        }
      })
      ..on<PraiseInPostUpdatedEvent>().listen((PraiseInPostUpdatedEvent event) {
        if (event.postId == widget.post.id) {
          if (event.isLike != null) {
            widget.post.isLike = event.isLike;
          }
          widget.post.praises = event.count;
        }
        if (mounted) {
          setState(() {});
        }
      });
  }

  Future<void> confirmDelete(BuildContext context) async {
    if (await ConfirmationDialog.show(
      context,
      title: '删除动态',
      content: '您正在删除您的动态，请确认操作',
      showConfirm: true,
    )) {
      if (await ConfirmationDialog.show(
        context,
        title: '确认删除动态',
        content: '删除后的动态无法恢复，请确认操作',
        showConfirm: true,
      )) {
        final LoadingDialogController _ldc = LoadingDialogController();
        LoadingDialog.show(
          context,
          controller: _ldc,
          title: '正在删除动态 ...',
          isGlobal: false,
        );
        try {
          await PostAPI.deletePost(widget.post.id);
          _ldc.changeState('success', title: '动态已删除');
          Instances.eventBus.fire(
            PostDeletedEvent(widget.post.id, widget.fromPage, widget.index),
          );
        } catch (e) {
          LogUtils.e(e.toString());
          LogUtils.e(e.response?.toString());
          _ldc.changeState(
            'failed',
            title: '动态删除失败',
            text: '该动态无法删除。可能问题：动态已被删除但未刷新、网络连接较差',
          );
        }
      }
    }
  }

  void postExtraActions(BuildContext context) {
    ConfirmationBottomSheet.show(
      context,
      actions: <ConfirmationBottomSheetAction>[
        ConfirmationBottomSheetAction(
          text: '${UserAPI.blacklist.contains(
            BlacklistUser(uid: widget.post.uid, username: widget.post.nickname),
          ) ? '移出' : '加入'}黑名单',
          onTap: () => UserAPI.confirmBlock(
            context,
            BlacklistUser(uid: widget.post.uid, username: widget.post.nickname),
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
    final bool confirm = await ConfirmationDialog.show(
      context,
      title: '举报动态',
      content: '您正在举报一条动态，请确认操作',
      showConfirm: true,
    );
    if (confirm) {
      final ReportRecordsProvider provider = Provider.of<ReportRecordsProvider>(
        context,
        listen: false,
      );
      final bool canReport = await provider.addRecord(widget.post.id);
      if (canReport) {
        PostAPI.reportPost(widget.post);
        showToast('举报成功');
      }
    }
  }

  void pushToDetail({Post post, int index, bool toComment = false}) {
    navigatorState.pushNamed(
      Routes.openjmuPostDetail.name,
      arguments: Routes.openjmuPostDetail.d(
        post: post ?? widget.post,
        index: index,
        fromPage: widget.fromPage,
        toComment: toComment,
      ),
    );
  }

  void pushToConvention() {
    ConventionDialog.show(context: context, shouldConfirm: false);
  }

  Widget getPostNickname(BuildContext context, Post post) {
    return Row(
      children: <Widget>[
        Text(
          post.nickname ?? post.uid,
          style: context.textTheme.bodyText2.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.left,
        ),
        if (Constants.developerList.contains(post.uid))
          Padding(
            padding: EdgeInsets.only(left: 6.w),
            child: const DeveloperTag(),
          ),
      ],
    );
  }

  Widget getPostInfo(Post post) {
    return Text(
      '${PostAPI.postTimeConverter(post.postTime)}  '
      '来自${post.from}客户端',
      style: TextStyle(
        color: context.textTheme.caption.color,
        fontSize: 16.sp,
      ),
    );
  }

  Widget getPostContent(BuildContext context, Post post) {
    return Container(
      width: Screens.width,
      margin: EdgeInsets.symmetric(vertical: 6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          getExtendedText(post.content),
          if (post.rootTopic != null) getRootPost(context, post.rootTopic),
        ],
      ),
    );
  }

  Widget getRootPost(BuildContext context, Map<String, dynamic> rootTopic) {
    if (rootTopic['topic'] is List && rootTopic['exists'] == 0) {
      rootTopic['topic'] = null;
    }
    final Map<String, dynamic> content =
        rootTopic['topic'] as Map<String, dynamic>;
    if (rootTopic['exists'] == 1) {
      if (content['article'] == '此微博已经被屏蔽' ||
          content['content'] == '此微博已经被屏蔽') {
        return Padding(
          padding: EdgeInsets.only(top: 12.w),
          child: getPostBanned('shield', isRoot: true),
        );
      } else {
        final Post _post = Post.fromJson(content);
        String topic =
            '<M ${content['user']['uid']}>@${content['user']['nickname'] ?? content['user']['uid']}<\/M>: ';
        topic += (content['article'] ?? content['content']).toString();
        return Padding(
          padding: EdgeInsets.only(top: 10.w, bottom: 4.w),
          child: Tapper(
            onTap: () {
              pushToDetail(post: _post);
            },
            child: Container(
              width: Screens.width,
              margin: EdgeInsets.only(top: 6.w),
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding - 6.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.w),
                color: context.theme.canvasColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  getExtendedText(topic, isRoot: true),
                  if (rootTopic['topic']['image'] != null &&
                      !post.shouldFoldRootTopic)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: getRootPostImages(
                        context,
                        rootTopic['topic'] as Map<String, dynamic>,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      return Padding(
        padding: EdgeInsets.only(top: 10.w),
        child: getPostBanned('delete', isRoot: true),
      );
    }
  }

  Widget getPostImages(BuildContext context, Post post) {
    return getImages(context, post.pics);
  }

  Widget getRootPostImages(
    BuildContext context,
    Map<String, dynamic> rootTopic,
  ) {
    return getImages(
      context,
      rootTopic['image'] as List<dynamic>,
      isInRootPost: true,
    );
  }

  Widget getImages(
    BuildContext context,
    List<dynamic> data, {
    bool isInRootPost = false,
  }) {
    if (data != null) {
      final List<Widget> imagesWidget = <Widget>[];
      for (int index = 0; index < data.length; index++) {
        final int imageId = data[index]['id'].toString().toInt();
        final String imageUrl = (data[index]['image_middle'] as String)+ '?timestamp=${Random().nextInt(500)}';
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
                    length: data.length,
                    num200: 200.w,
                    num400: 400.w,
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
                index: index,
                pics: data.map<ImageBean>((dynamic f) {
                  return ImageBean(
                    id: imageId,
                    imageUrl: (f['image_original'] as String)+ '?timestamp=${Random().nextInt(500)}',
                    imageThumbUrl: (f['image_original'] as String)+ '?timestamp=${Random().nextInt(500)}',
                    postId: widget.post.id,
                  );
                }).toList(),
                post: widget.post,
                heroPrefix: 'square-post-image-hero-'
                    '${widget.isDetail ? 'isDetail-' : ''}',
              ),
            );
          },
          child: _exImage,
        );
        _exImage = Hero(
          tag: 'square-post-image-hero-'
              '${widget.isDetail ? 'isDetail-' : ''}'
              '${widget.post.id}-$imageId',
          child: _exImage,
          placeholderBuilder: (_, __, Widget child) => child,
        );
        imagesWidget.add(_exImage);
      }
      Widget _image;
      if (data.length == 1) {
        _image = Container(
          padding: EdgeInsets.only(top: 4.h),
          child: Align(alignment: Alignment.topLeft, child: imagesWidget[0]),
        );
      } else if (data.length == 4) {
        _image = GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          primary: false,
          mainAxisSpacing: 10.w,
          crossAxisCount: 4,
          crossAxisSpacing: 10.h,
          children: imagesWidget,
        );
      } else if (data.length > 1) {
        _image = GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          primary: false,
          mainAxisSpacing: 10.w,
          crossAxisCount: 3,
          crossAxisSpacing: 10.h,
          children: imagesWidget,
        );
      }
      return Padding(
        padding: EdgeInsets.only(
          top: isInRootPost ? 5.w : 10.w,
          bottom: isInRootPost ? 5.w : 10.w,
        ),
        child: _image,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _action(int value, {String text, Color color}) {
    return Container(
      constraints: BoxConstraints(minWidth: 30.w),
      alignment: Alignment.center,
      child: Text(
        value == 0
            ? text ?? ''
            : value > 999
                ? '999+'
                : '$value',
        style: TextStyle(
          color: color ?? context.iconTheme.color,
          fontSize: 18.sp,
        ),
        maxLines: 1,
      ),
    );
  }

  Widget postActions(BuildContext context) {
    final int forwards = widget.post.forwards;
    final int comments = widget.post.comments;
    final int praises = widget.post.praises;

    return Row(
      children: <Widget>[
        LikeButton(
          padding: EdgeInsets.symmetric(vertical: 6.w),
          size: 40.w,
          circleColor: CircleColor(
            start: currentThemeColor,
            end: currentThemeColor,
          ),
          countBuilder: (int count, bool isLiked, String text) => _action(
            count,
            text: '赞　',
            color: isLiked ? currentThemeColor : null,
          ),
          bubblesColor: BubblesColor(
            dotPrimaryColor: currentThemeColor,
            dotSecondaryColor: currentThemeColor,
          ),
          likeBuilder: (bool isLiked) => Center(
            child: SvgPicture.asset(
              R.ASSETS_ICONS_POST_ACTIONS_PRAISE_FILL_SVG,
              color: isLiked ? currentThemeColor : context.iconTheme.color,
              width: 26.w,
            ),
          ),
          likeCount:
              widget.post.isLike ? moreThanOne(praises) : moreThanZero(praises),
          likeCountAnimationType: LikeCountAnimationType.none,
          likeCountPadding: EdgeInsets.only(right: 6.w),
          isLiked: widget.post.isLike,
          onTap: onLikeButtonTap,
        ),
        _actionButton(
          context: context,
          icon: SvgPicture.asset(
            R.ASSETS_ICONS_POST_ACTIONS_COMMENT_FILL_SVG,
            color: context.iconTheme.color,
            width: 26.w,
          ),
          text: '评论',
          value: comments,
          onTap: () {
            pushToDetail(index: widget.index, toComment: true);
          },
        ),
        _actionButton(
          context: context,
          icon: SvgPicture.asset(
            R.ASSETS_ICONS_POST_ACTIONS_FORWARD_FILL_SVG,
            color: context.iconTheme.color,
            width: 26.w,
          ),
          text: '转发',
          value: forwards,
          onTap: () {
            PostActionDialog.show(
              context: context,
              post: widget.post,
              type: PostActionType.forward,
            );
          },
        ),
      ],
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

  Widget getPostBanned(String type, {bool isRoot = false}) {
    String content = '该条微博已被';
    switch (type) {
      case 'shield':
        content += '屏蔽';
        break;
      case 'delete':
        content += '删除';
        break;
    }
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 20.w),
      decoration: BoxDecoration(
        borderRadius: !isRoot ? BorderRadius.circular(10.w) : null,
        color: type == 'delete' ? context.theme.canvasColor : null,
      ),
      child: DefaultTextStyle.merge(
        style: context.textTheme.caption.copyWith(
          height: 1.2,
          fontSize: 20.sp,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              content,
              style: TextStyle(color: context.textTheme.bodyText2.color),
            ),
            if (type == 'shield')
              Expanded(
                child: Tapper(
                  onTap: pushToConvention,
                  child: const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text('为什么该动态会被屏蔽？'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget getExtendedText(String content, {bool isRoot = false}) {
    return GestureDetector(
      onLongPress: () {
        if (widget.isDetail) {
          Clipboard.setData(ClipboardData(text: content));
          showToast('已复制到剪贴板');
        }
      },
      child: ExtendedText(
        content != null ? '$content ' : null,
        style: context.textTheme.bodyText2.copyWith(fontSize: 19.sp),
        onSpecialTextTap: specialTextTapRecognizer,
        maxLines: widget.isDetail != true
            ? post.shouldFoldRootTopic
                ? 2
                : 8
            : null,
        overflowWidget: widget.isDetail ?? false ? null : contentOverflowWidget,
        specialTextSpanBuilder: StackSpecialTextSpanBuilder(),
      ),
    );
  }

  Future<bool> onLikeButtonTap(bool isLiked) {
    final Completer<bool> completer = Completer<bool>();
    final int id = widget.post.id;

    widget.post.isLike = !widget.post.isLike;
    !isLiked ? widget.post.praises++ : widget.post.praises--;
    completer.complete(!isLiked);

    PraiseAPI.requestPraise(id, !isLiked).catchError((dynamic e) {
      isLiked ? widget.post.praises++ : widget.post.praises--;
      completer.complete(isLiked);
    });

    return completer.future;
  }

  Widget get deleteButton {
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

  Widget get postActionButton {
    return Tapper(
      onTap: () => postExtraActions(context),
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

  @override
  Widget build(BuildContext context) {
    final bool hideShield =
        post.isShield && context.read<SettingsProvider>().hideShieldPost;
    if (hideShield) {
      return const SizedBox.shrink();
    }

    if (post.isShield) {
      return Container(
        margin: widget.isDetail
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(
                horizontal: widget.fromPage == 'user' ? 0 : 16.w,
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
        child: getPostBanned('shield'),
      );
    }

    return Tapper(
      onTap: () {
        if (widget.isDetail) {
          return;
        }
        pushToDetail(index: widget.index);
      },
      child: Container(
        margin: widget.isDetail
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(
                horizontal: widget.fromPage == 'user' ? 0 : 16.w,
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
          children: <Widget>[
            Container(
              height: 70.w,
              padding: EdgeInsets.symmetric(vertical: 6.w),
              child: Row(
                children: <Widget>[
                  UserAvatar(
                    uid: widget.post.uid,
                    isSysAvatar: widget.post.user.sysAvatar,
                  ),
                  Gap(16.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        getPostNickname(context, post),
                        getPostInfo(post),
                      ],
                    ),
                  ),
                  if (!widget.isDetail)
                    post.uid == currentUser.uid
                        ? deleteButton
                        : postActionButton,
                ],
              ),
            ),
            getPostContent(context, post),
            getPostImages(context, post),
            if (widget.isDetail)
              VGap(2.w)
            else
              Padding(
                padding: EdgeInsets.only(top: 12.w),
                child: const LineDivider(),
              ),
            if (!widget.isDetail)
              Container(
                margin: EdgeInsets.only(top: 6.w),
                height: 56.w,
                child: Row(
                  children: <Widget>[
                    Text(
                      '浏览${post.glances}次　',
                      style: context.textTheme.caption.copyWith(
                        height: 1.2,
                        fontSize: 16.sp,
                      ),
                    ),
                    const Spacer(),
                    postActions(context),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
