///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-11-19 10:04
///
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:extended_text_field/extended_text_field.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/widgets/cards/team_post_card.dart';
import 'package:openjmu/widgets/cards/team_comment_preview_card.dart';
import 'package:openjmu/widgets/cards/team_post_comment_preview_card.dart';
import 'package:openjmu/widgets/dialogs/mention_people_dialog.dart';

@FFRoute(
  name: "openjmu://team-post-detail",
  routeName: "小组动态详情页",
  argumentNames: ["provider", "type", "postId"],
)
class TeamPostDetailPage extends StatefulWidget {
  final TeamPostProvider provider;
  final TeamPostType type;
  final int postId;

  const TeamPostDetailPage({
    this.provider,
    @required this.type,
    this.postId,
    Key key,
  }) : super(key: key);

  @override
  TeamPostDetailPageState createState() => TeamPostDetailPageState();
}

class TeamPostDetailPageState extends State<TeamPostDetailPage> {
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();
  final comments = <TeamPost>{};
  final postComments = <TeamPostComment>{};

  List<Map<String, dynamic>> get extendedFeature => [
//        {
//          'name': '添加图片',
//          'icon': Icons.add_photo_alternate,
//          'color': Colors.blueAccent,
//          'action': () {},
//        },
        {
          'name': '提到某人',
          'icon': Icons.alternate_email,
          'color': Colors.teal,
          'action': mentionPeople,
        },
        {
          'name': '插入话题',
          'icon': Icons.create,
          'color': Colors.deepOrangeAccent,
          'action': addTopic,
        },
      ];

  TeamPostProvider provider;

  int commentPage = 1, total, currentOffset;
  bool loading, canLoadMore = true, canSend = false, sending = false;
  bool showExtendedPad = false, showEmoticonPad = false;
  String replyHint;
  double _keyboardHeight = EmotionPad.emoticonPadDefaultHeight;
  TeamPost replyToPost;
  TeamPostComment replyToComment;

  @override
  void initState() {
    super.initState();
    provider = widget.provider;
    canLoadMore = (provider.post?.repliesCount ?? -1) >
        (widget.type == TeamPostType.comment ? 50 : 30);
    loading = (provider.post?.repliesCount ?? -1) > 0;
    initialLoad();

    _textEditingController.addListener(() {
      final _canSend = _textEditingController.text.isNotEmpty;
      if (mounted && canSend != _canSend) {
        setState(() {
          canSend = _canSend;
        });
      }
    });

    _focusNode.addListener(() {
      if (mounted && _focusNode.hasFocus) {
        setState(() {
          showExtendedPad = false;
        });
      }
    });

    Instances.eventBus
      ..on<TeamCommentDeletedEvent>().listen((event) {
        if (event.topPostId == provider.post.tid) {
          comments.removeWhere((item) => item.tid == event.postId);
          if (mounted) setState(() {});
        }
        initialLoad();
      })
      ..on<TeamPostCommentDeletedEvent>().listen((event) {
        if (event.topPostId == provider.post.tid) {
          postComments.removeWhere((item) => item.rid == event.commentId);
          if (mounted) setState(() {});
        }
      });
  }

  void initialLoad({bool loadMore = false}) async {
    if (!loadMore) {
      switch (widget.type) {
        case TeamPostType.post:
          comments.clear();
          break;
        case TeamPostType.comment:
          postComments.clear();
          break;
      }
      if (provider.post == null) {
        final data = (await TeamPostAPI.getPostDetail(
          id: widget.postId,
          postType: 7,
        ))
            .data;
        final post = TeamPost.fromJson(data);
        provider = TeamPostProvider(post);
      }
    }
    if (loadMore) ++commentPage;
    if (provider.post.repliesCount > 0) {
      TeamCommentAPI.getCommentInPostList(
        id: provider.post.tid,
        page: commentPage,
        isComment: widget.type == TeamPostType.comment,
      ).then((response) {
        final data = response.data;
        total = data['total'].toString().toInt();
        canLoadMore = data['count'].toString().toInt() >
            (widget.type == TeamPostType.comment ? 50 : 30);
        Set list;
        switch (widget.type) {
          case TeamPostType.post:
            list = comments;
            break;
          case TeamPostType.comment:
            list = postComments;
            break;
        }
        if (total != 0) {
          if (!loadMore) list.clear();
          data['data'].forEach((post) {
            var _post;
            switch (widget.type) {
              case TeamPostType.post:
                _post = TeamPost.fromJson(post);
                break;
              case TeamPostType.comment:
                _post = TeamPostComment.fromJson(post);
                break;
            }
            list.add(_post);
          });
        }
        loading = false;
        if (mounted) setState(() {});
      });
    } else {
      total = 0;
      canLoadMore = false;
      if (mounted) setState(() {});
    }
  }

  void setReplyToTop() {
    replyToPost = null;
    replyToComment = null;
    replyHint = null;
    if (mounted) setState(() {});
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  void setReplyToPost(TeamPost post) {
    replyToPost = post;
    replyHint = '回复@${post.nickname}:';
    if (mounted) setState(() {});
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  void setReplyToComment(TeamPostComment comment) {
    replyToComment = comment;
    replyHint = '回复@${comment.userInfo['nickname']}:';
    if (mounted) setState(() {});
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  void confirmDelete(context, TeamPostProvider provider) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: '删除动态',
      content: '是否删除该条动态?',
      showConfirm: true,
    );
    if (confirm) delete(provider);
  }

  void delete(TeamPostProvider provider) {
    TeamPostAPI.deletePost(postId: provider.post.tid, postType: 7).then(
      (dynamic _) {
        showToast('删除成功');
        switch (widget.type) {
          case TeamPostType.post:
            Instances.eventBus
                .fire(TeamPostDeletedEvent(postId: provider.post.tid));
            break;
          case TeamPostType.comment:
            Instances.eventBus
                .fire(TeamCommentDeletedEvent(postId: provider.post.tid));
            break;
        }
        navigatorState.pop();
      },
    );
  }

  void triggerEmoticonPad() {
    if (showEmoticonPad && _focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }

    final change = () {
      showEmoticonPad = !showEmoticonPad;
      if (showEmoticonPad) showExtendedPad = false;
      if (mounted) setState(() {});
    };

    if (showEmoticonPad) {
      change();
    } else {
      if (MediaQuery.of(context).viewInsets.bottom != 0.0) {
        SystemChannels.textInput.invokeMethod('TextInput.hide').whenComplete(
          () {
            Future.delayed(300.milliseconds, null).whenComplete(change);
          },
        );
      } else {
        change();
      }
    }
  }

  void triggerExtendedPad() {
    if (!showExtendedPad) _focusNode.unfocus();
    setState(() {
      showExtendedPad = !showExtendedPad;
      if (showExtendedPad) showEmoticonPad = false;
    });
  }

  void addTopic() async {
    _focusNode.requestFocus();
    await Future.delayed(const Duration(milliseconds: 100));
    final currentPosition = _textEditingController.selection.baseOffset;
    String result;
    if (_textEditingController.text.isNotEmpty) {
      final leftText =
          _textEditingController.text.substring(0, currentPosition);
      final rightText = _textEditingController.text
          .substring(currentPosition, _textEditingController.text.length);
      result = '$leftText##$rightText';
    } else {
      result = '##';
    }
    _textEditingController.text = result;
    _textEditingController.selection = TextSelection.fromPosition(
      TextPosition(offset: currentPosition + 1),
    );
  }

  void mentionPeople() {
    currentOffset = _textEditingController.selection.extentOffset;
    showDialog<User>(
      context: context,
      builder: (BuildContext context) => MentionPeopleDialog(),
    ).then((result) {
      if (_focusNode.canRequestFocus) _focusNode.requestFocus();
      if (result != null) {
        trueDebugPrint('Mentioned User: ${result.toString()}');
        Future.delayed(const Duration(milliseconds: 250), () {
          if (_focusNode.canRequestFocus) _focusNode.requestFocus();
          insertText('<M ${result.id}>@${result.nickname}<\/M>');
        });
      }
    });
  }

  void insertText(String text) {
    final value = _textEditingController.value;
    final start = value.selection.baseOffset;
    final end = value.selection.extentOffset;

    if (value.selection.isValid) {
      String newText = '';
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
      }
      _textEditingController.value = value.copyWith(
        text: newText,
        selection: value.selection.copyWith(
          baseOffset: end + text.length,
          extentOffset: end + text.length,
        ),
      );
      if (mounted) setState(() {});
    }
  }

  void send() {
    setState(() {
      sending = true;
    });
    String prefix;
    int postId;
    int postType;
    int regionType;
    switch (widget.type) {
      case TeamPostType.post:
        if (replyHint == null) {
          postId = provider.post?.tid;
          postType = 7;
          regionType = 128;
        } else {
          postId = replyToPost?.tid;
          postType = 8;
          regionType = 256;
        }
        break;
      case TeamPostType.comment:
        if (replyHint != null) {
          prefix = replyHint;
        }
        postId = replyToComment?.originId ?? provider.post?.tid;
        postType = 8;
        regionType = 256;
        break;
    }
    TeamPostAPI.publishPost(
      content: '${prefix ?? ''}${_textEditingController.text}',
      postType: postType,
      regionId: postId,
      regionType: regionType,
    ).then((response) {
      provider.replied();
      _focusNode.unfocus();
      _textEditingController.clear();
      replyHint = null;
      showToast('发送成功');
      initialLoad();
    }).catchError((e) {
      trueDebugPrint('Reply failed: $e');
      showErrorToast('发送失败');
    }).whenComplete(() {
      sending = false;
      if (mounted) setState(() {});
    });
  }

  Widget get deleteButton => SizedBox.fromSize(
        size: Size.square(48.0),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.delete_outline),
          iconSize: suSetWidth(32.0),
          onPressed: () {
            confirmDelete(context, provider);
          },
        ),
      );

  Widget get textField => Expanded(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(suSetWidth(50.0)),
            color: Theme.of(context).canvasColor.withOpacity(0.5),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ExtendedTextField(
                  controller: _textEditingController,
                  focusNode: _focusNode,
                  specialTextSpanBuilder: StackSpecialTextFieldSpanBuilder(),
                  enabled: !sending,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: suSetWidth(20.0),
                      vertical: suSetHeight(10.0),
                    ),
                    prefixText: replyHint,
                    hintText: replyHint == null ? '给你一个神评的机会...' : null,
                  ),
                  cursorColor: currentThemeColor,
                  style: Theme.of(context).textTheme.bodyText2.copyWith(
                        fontSize: suSetSp(20.0),
                        textBaseline: TextBaseline.alphabetic,
                      ),
                  maxLines: null,
                ),
              ),
              emoticonButton,
            ],
          ),
        ),
      );

  Widget get extendedPadButton => Container(
        padding: EdgeInsets.only(left: suSetWidth(12.0)),
        height: suSetHeight(46.0),
        child: MaterialButton(
          elevation: 0.0,
          highlightElevation: canSend ? 2.0 : 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(suSetWidth(50.0)),
          ),
          minWidth: suSetWidth(60.0),
          color: currentThemeColor,
          child: Center(
            child: Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: suSetWidth(28.0),
            ),
          ),
          onPressed: triggerExtendedPad,
        ),
      );

  Widget get sendButton => Container(
        padding: EdgeInsets.only(left: suSetWidth(12.0)),
        height: suSetHeight(46.0),
        child: MaterialButton(
          elevation: 0.0,
          highlightElevation: canSend ? 2.0 : 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(suSetWidth(50.0)),
          ),
          minWidth: suSetWidth(60.0),
          disabledColor: currentThemeColor.withOpacity(sending ? 1 : 0.3),
          color: currentThemeColor.withOpacity(canSend ? 1 : 0.3),
          child: Center(
            child: SizedBox.fromSize(
              size: Size.square(suSetWidth(28.0)),
              child: sending
                  ? PlatformProgressIndicator()
                  : Icon(
                      Icons.send,
                      color: Colors.white,
                      size: suSetWidth(28.0),
                    ),
            ),
          ),
          onPressed: !sending && canSend ? send : null,
        ),
      );

  Widget get extendedPad => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.fastOutSlowIn,
        width: Screens.width,
        height: showExtendedPad ? Screens.width / 5 : 0.0,
        child: Center(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
            ),
            itemCount: extendedFeature.length,
            itemBuilder: (context, index) {
              return InkWell(
                splashFactory: InkSplash.splashFactory,
                onTap: extendedFeature[index]['action'],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(bottom: suSetHeight(12.0)),
                      padding: EdgeInsets.all(suSetWidth(14.0)),
                      decoration: BoxDecoration(
                        color: extendedFeature[index]['color'],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        extendedFeature[index]['icon'],
                        size: suSetWidth(26.0),
                      ),
                    ),
                    Text(
                      extendedFeature[index]['name'],
                      style: TextStyle(fontSize: suSetSp(19.0)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

  Widget get emoticonButton => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: triggerEmoticonPad,
        child: Container(
          margin: EdgeInsets.only(right: suSetWidth(12.0)),
          child: Center(
            child: Icon(
              Icons.insert_emoticon,
              color: showEmoticonPad ? currentThemeColor : null,
              size: suSetWidth(30.0),
            ),
          ),
        ),
      );

  Widget get emoticonPad => EmotionPad(
        active: showEmoticonPad,
        height: _keyboardHeight,
        route: 'publish',
        controller: _textEditingController,
      );

  @override
  Widget build(BuildContext context) {
    final list = widget.type == TeamPostType.post ? comments : postComments;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0) {
      showEmoticonPad = false;
    }
    _keyboardHeight = math.max(_keyboardHeight, keyboardHeight);
    return Scaffold(
      body: Column(
        children: <Widget>[
          FixedAppBar(
            title: Text('集市动态'),
            centerTitle: true,
            actions: <Widget>[
              if (provider.post?.uid == currentUser.uid ?? false) deleteButton,
            ],
          ),
          Expanded(
            child: Listener(
              onPointerDown: (_) {
                if (MediaQuery.of(context).viewInsets.bottom > 0.0) {
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                }
              },
              child: CustomScrollView(
                slivers: <Widget>[
                  if (provider.post != null)
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TeamPostCard(
                            post: provider.post,
                            detailPageState: this,
                          ),
                          Divider(
                            color: Theme.of(context).canvasColor,
                            height: suSetHeight(10.0),
                            thickness: suSetHeight(10.0),
                          ),
                        ],
                      ),
                    ),
                  loading
                      ? SliverToBoxAdapter(
                          child: SizedBox(
                            height: suSetHeight(300.0),
                            child: Center(child: SpinKitWidget()),
                          ),
                        )
                      : list != null
                          ? SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, int index) {
                                  if (index == list.length - 1 && canLoadMore) {
                                    initialLoad(loadMore: true);
                                  }
                                  if (index == list.length) {
                                    return LoadMoreIndicator(
                                        canLoadMore: canLoadMore);
                                  }
                                  Widget item;
                                  switch (widget.type) {
                                    case TeamPostType.post:
                                      item = ChangeNotifierProvider.value(
                                        value: TeamPostProvider(
                                          list.elementAt(index),
                                        ),
                                        child: TeamCommentPreviewCard(
                                          topPost: provider.post,
                                          detailPageState: this,
                                        ),
                                      );
                                      break;
                                    case TeamPostType.comment:
                                      item = TeamPostCommentPreviewCard(
                                        comment: list.elementAt(index),
                                        topPost: provider.post,
                                        detailPageState: this,
                                      );
                                      break;
                                  }
                                  return Padding(
                                    padding: EdgeInsets.all(suSetSp(4.0)),
                                    child: item,
                                  );
                                },
                                childCount: list.length + 1,
                              ),
                            )
                          : SliverToBoxAdapter(
                              child: SizedBox(
                                height: suSetHeight(300.0),
                                child: Center(child: Text('Nothing here.')),
                              ),
                            ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(suSetWidth(16.0)),
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(context).dividerColor.withOpacity(0.03),
                      offset: Offset(0, -suSetHeight(2.0)),
                      blurRadius: suSetHeight(2.0),
                    ),
                  ],
                  color: Theme.of(context).primaryColor,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    textField,
                    extendedPadButton,
                    sendButton,
                  ],
                ),
              ),
              extendedPad,
              emoticonPad,
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }
}

enum TeamPostType { post, comment }
