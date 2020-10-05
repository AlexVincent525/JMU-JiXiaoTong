import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:openjmu/constants/constants.dart';

export 'package:openjmu/controller/comment_controller.dart';
export 'package:openjmu/controller/post_controller.dart';
export 'package:openjmu/controller/praise_controller.dart';
export 'package:openjmu/model/special_text.dart';

part 'models.g.dart';

part 'backpack_item.dart';

part 'app_message.dart';

part 'blacklist_user.dart';

part 'changelog.dart';

part 'cloud_settings.dart';

part 'comment.dart';

part 'course.dart';

part 'json_model.dart';

part 'message.dart';

part 'news.dart';

part 'notifications.dart';

part 'packet.dart';

part 'post.dart';

part 'praise.dart';

part 'score.dart';

part 'team_mention.dart';

part 'team_notifications.dart';

part 'team_post.dart';

part 'team_post_comment.dart';

part 'theme_group.dart';

part 'user.dart';

part 'user_info.dart';

part 'user_level.dart';

part 'user_tag.dart';

part 'web_app.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildViewportChrome(BuildContext _, Widget child, AxisDirection __) =>
      child;
}
