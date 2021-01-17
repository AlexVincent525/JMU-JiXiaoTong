///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-11-18 16:45
///
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text_field/extended_text_field.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/widgets/dialogs/convention_dialog.dart';
import 'package:openjmu/widgets/dialogs/mention_people_dialog.dart';

@FFRoute(name: 'openjmu://publish-team-post', routeName: '发布小组动态')
class PublishTeamPostPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => PublishTeamPostPageState();
}

class PublishTeamPostPageState extends State<PublishTeamPostPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController textEditingController = TextEditingController();
  final LoadingDialogController loadingDialogController =
      LoadingDialogController();
  final FocusNode focusNode = FocusNode();
  final double iconSize = 28.h;

  List<AssetEntity> selectedAssets = <AssetEntity>[];
  final Set<AssetEntity> failedAssets = <AssetEntity>{};
  final List<CancelToken> assetsUploadCancelTokens = <CancelToken>[];
  final Map<AssetEntity, int> uploadedAssetId = <AssetEntity, int>{};

  int maxAssetsLength = 9;
  int uploadedAssets = 0;

  bool isFocus = false;
  bool isLoading = false;
  bool isTextFieldEnable = true;
  bool isEmoticonPadActive = false;
  bool isAssetListViewCollapsed = false;

  int currentLength = 0, currentOffset;
  Color counterTextColor = Colors.grey;
  double maximumKeyboardHeight = EmotionPad.emoticonPadDefaultHeight;

  bool emoticonPadActive = false;

  int get imagesLength => selectedAssets.length;

  bool get hasImages => selectedAssets.isNotEmpty;

  String get filteredContent => textEditingController?.text?.trim();

  bool get isContentNotEmpty => filteredContent?.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    textEditingController?.dispose();
    focusNode?.unfocus();
    focusNode?.dispose();
    super.dispose();
  }

  /// Method to add `##`(topic) into text field.
  /// 输入区域内插入`##`（话题）的方法
  void addTopic() {
    InputUtils.insertText(
      text: '##',
      state: this,
      controller: textEditingController,
      selectionOffset: 1,
    );
  }

  /// Method to show mention people dialog and insert mentioned user.
  /// 弹出提到某人的搜索框并在输入区域中插入已选用户
  Future<void> mentionPeople() async {
    try {
      final User result = await showDialog<User>(
        context: context,
        builder: (BuildContext context) => MentionPeopleDialog(),
      );
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
      if (result != null) {
        Future<void>.delayed(250.milliseconds, () {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
          InputUtils.insertText(
            text: '<M ${result.id}>@${result.nickname}<\/M>',
            state: this,
            controller: textEditingController,
          );
        });
      }
    } catch (e) {
      LogUtils.e('Error when trying to mention someone: $e');
    }
  }

  /// Removes focus from the [FocusNode] of the [ExtendedTextField].
  /// 取消输入区域的焦点
  void unFocusTextField() => focusNode.unfocus();

  /// Method to pick assets using photo selector.
  /// 使用图片选择器选择图片
  Future<void> pickAssets() async {
    unFocusTextField();
    final List<AssetEntity> result = await AssetPicker.pickAssets(
      context,
      selectedAssets: selectedAssets,
      themeColor: currentThemeColor,
    );
    if (result != selectedAssets && result != null) {
      selectedAssets = List<AssetEntity>.from(result);
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Reverse [isAssetListViewCollapsed] state.
  /// 切换资源列表展开收起
  void switchAssetsListCollapse() {
    setState(() {
      isAssetListViewCollapsed = !isAssetListViewCollapsed;
    });
  }

  /// Update [maximumKeyboardHeight] during [build] to set maximum keyboard height.
  /// 执行 [build] 时更新 [maximumKeyboardHeight] 以获得最高键盘高度
  void updateKeyboardHeight(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0) {
      isEmoticonPadActive = false;
    }

    if (maximumKeyboardHeight !=
        math.max(maximumKeyboardHeight, keyboardHeight)) {
      maximumKeyboardHeight = math.max(maximumKeyboardHeight, keyboardHeight);
    }
  }

  /// Method to update display status for the emoticon pad.
  /// 更新表情选择区显隐的方法
  void updateEmoticonPadStatus(BuildContext context, bool active) {
    final VoidCallback change = () {
      isEmoticonPadActive = active;
      if (mounted) {
        setState(() {});
      }
    };
    if (isEmoticonPadActive) {
      change();
    } else {
      if (MediaQuery.of(context).viewInsets.bottom != 0.0) {
        InputUtils.hideKeyboard().whenComplete(
          () {
            Future<void>.delayed(300.milliseconds, null).whenComplete(change);
          },
        );
      } else {
        change();
      }
    }
  }

  /// Check whether there's content left when trying to pop.
  /// 返回时检查是否有未发送的内容
  Future<bool> isContentEmptyWhenPop() async {
    unFocusTextField();
    if (imagesLength != 0 || isContentNotEmpty) {
      final bool confirm = await ConfirmationDialog.show(
        context,
        title: '退出发布动态',
        content: '仍有未发送的内容，是否退出？',
        showConfirm: true,
      );
      if (confirm) {
        focusNode.unfocus();
        Navigator.of(context).pop();
      }
      return false;
    } else {
      Navigator.of(context).pop();
      return false;
    }
  }

  /// Check if user confirmed with convention.
  /// 检查用户是否同意了公约
  Future<void> checkConvention() async {
    final bool confirm = await ConventionDialog.show(context);
    if (confirm) {
      LoadingDialog.show(
        context,
        controller: loadingDialogController,
        text: hasImages
            ? '正在上传图片 (${uploadedAssets + 1}/$imagesLength)'
            : '正在发布动态...',
      );
      setState(() {
        isLoading = true;
      });
      if (hasImages) {
        runImagesRequests();
      } else {
        unawaited(runPublishRequest());
      }
    }
  }

  /// Execute images upload requests.
  /// 执行图片上传请求
  ///
  /// This method doesn't required to be [Future], just run them with [Iterable.forEach] and
  /// using [CancelToken] (Completer) to control requests' cancel when one of them failed.
  /// 该方法不需要声明为 [Future]，只需要使用 forEach 调用异步方法，并且使用 [CancelToken] 来控制
  /// 请求。为了避免过多状态导致的意外结果，当任意资源上传失败时，就立刻取消所有请求，要求用户处理。
  void runImagesRequests() {
    setState(() {
      failedAssets.clear();
    });

    /// Using `forEach` instead of `for in` is that `for in` will execute
    /// one by one, and stuck if the previous request takes a long duration.
    /// `forEach` will send requests at the same time.
    /// 使用`forEach`而不是`for in`是因为`for in`会逐个执行，
    /// 如果上一个请求耗费了很长时间，整个流程都将被 阻塞，
    /// 而使用`forEach`会同时发起所有请求。
    selectedAssets.forEach(assetsUploadRequest);
  }

  Future<void> assetsUploadRequest(AssetEntity asset) async {
    /// Make a data record first, in order to keep the sequence of the images.
    /// 先创建数据条目，保证上传的图片的顺序。
    uploadedAssetId[asset] = null;
    final CancelToken cancelToken = CancelToken();
    assetsUploadCancelTokens.add(cancelToken);
    final FormData formData =
        await TeamPostAPI.createPostImageUploadForm(asset);
    try {
      final Map<String, dynamic> result =
          (await TeamPostAPI.createPostImageUploadRequest(
        formData: formData,
        cancelToken: cancelToken,
      ))
              .data;
      uploadedAssetId[asset] = result['fid'].toString().toInt();
      ++uploadedAssets;
      loadingDialogController.updateText(
        '正在上传图片('
        '${math.min(uploadedAssets + 1, imagesLength)}'
        '/'
        '$imagesLength'
        ')',
      );

      /// Execute publish when all assets were upload.
      /// 所有图片上传完成时进行发布
      if (uploadedAssets == imagesLength) {
        unawaited(runPublishRequest());
      }
    } catch (e) {
      isLoading = false; // 停止Loading
      uploadedAssets = 0; // 上传清零
      failedAssets.add(asset); // 添加失败entity
      loadingDialogController.changeState('failed', '图片上传失败');

      /// Cancel all request and clear token list.
      /// 取消所有的上传请求并清空所有cancel token
      assetsUploadCancelTokens
        ..forEach((CancelToken token) => token?.cancel())
        ..clear();

      if (mounted) {
        setState(() {});
      }

      LogUtils.e('Error when trying upload images: $e');
      if (e is DioError) {
        LogUtils.e('${e.response.data}');
      }
      LogUtils.e('Images requests will be all cancelled.');
    }
  }

  /// Execute post content publish request.
  /// 执行内容发布请求
  Future<void> runPublishRequest() async {
    String content;
    if ((imagesLength != 0 && textEditingController.text == null) ||
        filteredContent.isEmpty) {
      content = '分享图片~';
    } else {
      content = textEditingController.text;
    }
    try {
      final Map<String, dynamic> response = (await TeamPostAPI.publishPost(
        content: content,
        files: uploadedAssetId.values.toList(),
      ))
          .data;
      if (response['tid'] != null) {
        loadingDialogController.changeState(
          'success',
          '动态发布成功',
          duration: 3.seconds,
          customPop: () {
            navigatorState.popUntil((Route<dynamic> route) => route.isFirst);
          },
        );
      }
    } catch (e) {
      loadingDialogController.changeState('failed', '动态发布失败');
      LogUtils.e(e);
    } finally {
      isLoading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  ////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////// Just a line breaker ////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////////

  /// Publish button.
  /// 发布按钮
  Widget get publishButton {
    return GestureDetector(
      onTap: checkConvention,
      child: Container(
        width: 120.w,
        height: 50.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.w),
          color: currentThemeColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 6.w),
              child: SvgPicture.asset(
                R.ASSETS_ICONS_SEND_SVG,
                height: 22.h,
                color: Colors.white,
              ),
            ),
            Text(
              '发动态',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                height: 1.24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [TextField] for content.
  /// 内容输入区
  Widget get textField => Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ExtendedTextField(
            autofocus: false,
            controller: textEditingController,
            enabled: !isLoading,
            focusNode: focusNode,
            scrollPadding: EdgeInsets.zero,
            specialTextSpanBuilder: StackSpecialTextFieldSpanBuilder(),
            cursorColor: Theme.of(context).cursorColor,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(top: 20.h),
              border: InputBorder.none,
              counterStyle: const TextStyle(color: Colors.transparent),
              hintText: '分享你的动态...',
              hintStyle: const TextStyle(
                color: Colors.grey,
                textBaseline: TextBaseline.alphabetic,
              ),
            ),
            buildCounter: emptyCounterBuilder,
            style: currentTheme.textTheme.bodyText2.copyWith(
              fontSize: 22.sp,
              textBaseline: TextBaseline.alphabetic,
            ),
            maxLines: null,
          ),
        ),
      );

  /// Selected asset image widget.
  /// 已选资源的单个图片组件
  Widget _assetWidget(int index) {
    final AssetEntity asset = selectedAssets.elementAt(index);
    return GestureDetector(
      onTap: !isAssetListViewCollapsed
          ? () async {
              final List<AssetEntity> result =
                  await AssetPickerViewer.pushToViewer(
                context,
                currentIndex: index,
                previewAssets: selectedAssets,
                themeData: AssetPicker.themeData(currentThemeColor),
              );
              if (result != selectedAssets && result != null) {
                selectedAssets = result;
                if (mounted) {
                  setState(() {});
                }
              }
            }
          : null,
      child: RepaintBoundary(
        child: ExtendedImage(
          image: AssetEntityImageProvider(asset, isOriginal: false),
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(10.w),
          shape: BoxShape.rectangle,
        ),
      ),
    );
  }

  /// Cover for error when there's any image failed in uploading.
  /// 图片上传失败时的错误遮罩
  Widget get uploadErrorCover => Positioned.fill(
        child: Container(
          color: Colors.white.withOpacity(0.7),
          child: Center(
            child: Icon(
              Icons.error,
              color: Colors.redAccent,
              size: 40.w,
            ),
          ),
        ),
      );

  /// The delete button for assets.
  /// 资源的删除按钮
  Widget _assetDeleteButton(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          failedAssets.remove(selectedAssets.elementAt(index));
          selectedAssets.remove(selectedAssets.elementAt(index));
          if (imagesLength == 0) {
            isAssetListViewCollapsed = false;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 6.w,
          vertical: 2.h,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          color: currentTheme.primaryColor.withOpacity(0.75),
        ),
        child: Text(
          '删除',
          style: TextStyle(
            color: currentTheme.iconTheme.color,
            fontSize: 14.sp,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Item shown when selected assets not reached maximum images length yet.
  /// 已选中图片数量未达到最大限制时，显示添加item。
  Widget get _assetAddItem => AnimatedContainer(
        duration: kThemeAnimationDuration,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 16.w,
        ),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: pickAssets,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10.w),
                color: currentIsDark ? Colors.grey[700] : Colors.white,
              ),
              child: Icon(
                Icons.add,
                size: (isAssetListViewCollapsed ? 20 : 50).w,
              ),
            ),
          ),
        ),
      );

  /// List view for assets.
  /// 已选资源的显示列表
  Widget get assetsListView => Align(
        alignment: AlignmentDirectional.centerStart,
        child: GestureDetector(
          onTap: isAssetListViewCollapsed ? switchAssetsListCollapse : null,
          child: AnimatedContainer(
            curve: Curves.easeInOut,
            duration: kThemeAnimationDuration,
            height: selectedAssets.isNotEmpty
                ? isAssetListViewCollapsed
                    ? 72.w
                    : 140.w
                : 0.0,
            margin: EdgeInsets.all(
              isAssetListViewCollapsed ? 12.w : 0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                isAssetListViewCollapsed ? 15.w : 0,
              ),
              color: currentTheme.canvasColor,
            ),
            child: ListView.builder(
              shrinkWrap: isAssetListViewCollapsed,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: math.min(
                isAssetListViewCollapsed ? imagesLength : imagesLength + 1,
                maxAssetsLength,
              ),
              itemBuilder: (BuildContext _, int index) {
                if (index == imagesLength) {
                  return _assetAddItem;
                }
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 16.w,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(child: _assetWidget(index)),
                        if (failedAssets
                            .contains(selectedAssets.elementAt(index)))
                          uploadErrorCover,
                        if (!isAssetListViewCollapsed)
                          Positioned(
                            top: 6.w,
                            right: 6.w,
                            child: _assetDeleteButton(index),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  /// Emoticon pad widget.
  /// 表情选择部件
  Widget get emoticonPad {
    return EmotionPad(
      active: isEmoticonPadActive,
      route: 'publish',
      height: maximumKeyboardHeight,
      controller: textEditingController,
    );
  }

  /// Button wrapper for the toolbar.
  /// 工具栏按钮封装
  Widget _toolbarButton({
    VoidCallback onPressed,
    IconData icon,
    Widget child,
    Color color,
  }) {
    return IconButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: child ??
          Icon(
            icon,
            color: color ?? currentTheme.iconTheme.color,
            size: iconSize,
          ),
    );
  }

  /// Toolbar for the page.
  /// 工具栏
  Widget toolbar(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom:
            !isEmoticonPadActive ? MediaQuery.of(context).padding.bottom : 0.0,
      ),
      height: 60.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _toolbarButton(
            onPressed: addTopic,
            child: SvgPicture.asset(
              R.ASSETS_ICONS_ADD_TOPIC_SVG,
              color: currentTheme.iconTheme.color,
              width: iconSize,
              height: iconSize,
            ),
          ),
          _toolbarButton(
            onPressed: mentionPeople,
            icon: Platform.isAndroid ? Ionicons.ios_at : Ionicons.md_at,
          ),
          _toolbarButton(
            onPressed: () {
              if (imagesLength > 0) {
                switchAssetsListCollapse();
              } else {
                pickAssets();
              }
            },
            icon: imagesLength > 0
                ? Icons.photo_library
                : Icons.add_photo_alternate,
            color: !isAssetListViewCollapsed && imagesLength > 0
                ? currentThemeColor
                : currentTheme.iconTheme.color,
          ),
          _toolbarButton(
            onPressed: () {
              if (isEmoticonPadActive && focusNode.canRequestFocus) {
                focusNode.requestFocus();
              }
              updateEmoticonPadStatus(context, !isEmoticonPadActive);
            },
            icon: Icons.sentiment_very_satisfied,
            color: isEmoticonPadActive
                ? currentThemeColor
                : currentTheme.iconTheme.color,
          ),
        ],
      ),
    );
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    super.build(context);
    updateKeyboardHeight(context);
    return WillPopScope(
      onWillPop: isContentEmptyWhenPop,
      child: FixedAppBarWrapper(
        appBar: FixedAppBar(
          actions: <Widget>[publishButton],
          actionsPadding: EdgeInsets.only(right: 20.w),
        ),
        body: Scaffold(
          backgroundColor: currentTheme.primaryColor,
          body: Column(
            children: <Widget>[
              textField,
              if (selectedAssets.isNotEmpty) assetsListView,
              toolbar(context),
              emoticonPad,
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
