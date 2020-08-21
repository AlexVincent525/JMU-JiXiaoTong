///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-11-08 10:53
///
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:openjmu/constants/constants.dart';

export 'package:provider/provider.dart';
export 'package:openjmu/providers/courses_provider.dart';
export 'package:openjmu/providers/date_provider.dart';
export 'package:openjmu/providers/messages_provider.dart';
export 'package:openjmu/providers/notification_provider.dart';
export 'package:openjmu/providers/report_records_provider.dart';
export 'package:openjmu/providers/scores_provider.dart';
export 'package:openjmu/providers/settings_provider.dart';
export 'package:openjmu/providers/sign_provider.dart';
export 'package:openjmu/providers/team_post_provider.dart';
export 'package:openjmu/providers/themes_provider.dart';
export 'package:openjmu/providers/webapps_provider.dart';

ChangeNotifierProvider<T> buildProvider<T extends ChangeNotifier>(T value) {
  return ChangeNotifierProvider<T>.value(value: value);
}

List<SingleChildWidget> get providers => _providers;

final _providers = [
  buildProvider<CoursesProvider>(CoursesProvider()),
  buildProvider<DateProvider>(DateProvider()),
  buildProvider<MessagesProvider>(MessagesProvider()),
  buildProvider<NotificationProvider>(NotificationProvider()),
  buildProvider<ReportRecordsProvider>(ReportRecordsProvider()),
  buildProvider<ScoresProvider>(ScoresProvider()),
  buildProvider<SettingsProvider>(SettingsProvider()),
  buildProvider<SignProvider>(SignProvider()),
  buildProvider<ThemesProvider>(ThemesProvider()),
  buildProvider<WebAppsProvider>(WebAppsProvider()),
];
