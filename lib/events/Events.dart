import 'package:OpenJMU/model/Bean.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

class LoginEvent {}
class LogoutEvent {}
class LoginFailedEvent {}
class TicketGotEvent {}
class TicketFailedEvent {}

class PostDeletedEvent {
  int postId;
  PostDeletedEvent(int id) {
    this.postId = id;
  }
}
class PostForwardedEvent {
  int postId;
  PostForwardedEvent(int id) {
    this.postId = id;
  }
}
class PostCommentedEvent {
  int postId;
  PostCommentedEvent(int id) {
    this.postId = id;
  }
}

class HasUpdateEvent {
  Map<String, dynamic> response;
  HasUpdateEvent(Map<String, dynamic> response) {
    this.response = response;
  }
}

class OTAEvent {
  OtaEvent otaEvent;
  OTAEvent(OtaEvent _otaEvent) {
    this.otaEvent = _otaEvent;
  }
}

class UserInfoGotEvent {
  UserInfo currentUser;
  UserInfoGotEvent(UserInfo userInfo) {
    this.currentUser = userInfo;
  }
}

class NotificationsChangeEvent {
  Notifications notifications;

  NotificationsChangeEvent(Notifications notifications) {
    this.notifications = notifications;
  }
}

class ChangeThemeEvent {
  Color color;
  ChangeThemeEvent(Color color) {
    this.color = color;
  }
}

class ChangeBrightnessEvent {
  bool isDarkState;
  Brightness brightness;
  Color primaryColor;

  ChangeBrightnessEvent(bool isDark) {
    if (isDark) {
      this.isDarkState = true;
      this.brightness = Brightness.dark;
      this.primaryColor = Colors.grey[850];
    } else {
      this.isDarkState = false;
      this.brightness = Brightness.light;
      this.primaryColor = Colors.white;
    }
  }
}

class ScrollToTopEvent {
  int tabIndex;
  String type;

  ScrollToTopEvent({int tabIndex, String type}) {
    this.tabIndex = tabIndex;
    this.type = type;
  }
}

class PostChangeEvent {
  Post post;
  bool remove;

  PostChangeEvent(this.post, [this.remove = false]);
}
