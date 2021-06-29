import 'dart:async';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show HTTPCookieSameSitePolicy;
import 'package:uuid/uuid.dart';

import 'package:openjmu/constants/constants.dart';

class DataUtils {
  const DataUtils._();

  static Box<dynamic> get _settingsBox => HiveBoxes.settingsBox;

  static const String spBlowfish = 'blowfish';
  static const String spIsLogin = 'isLogin';
  static const String spTicket = 'ticket';
  static const String spUserUid = 'userUid';
  static const String spUserWorkId = 'userWorkId';

  static Future<bool> login(String username, String password) async {
    // Mock Login Hook
    if (username == 'OpenJmuMock' && password == 'OpenJmuMock') {
      await HiveBoxes.upBox.clear();
      await HiveBoxes.upBox.add(UPModel(username, password));
      final Map<String, dynamic> loginData =
          NetUtils.mockData[API.login] as Map<String, dynamic>;
      currentUser = currentUser.copyWith(
        sid: loginData['sid'] as String,
        ticket: loginData['ticket'] as String,
      );
      final Map<String, dynamic> user = NetUtils
          .mockData[API.userInfo + '?uid=2021Mock'] as Map<String, dynamic>;
      final Map<String, dynamic> userInfo = <String, dynamic>{
        'sid': loginData['sid'],
        'uid': loginData['uid'],
        'username': user['username'],
        'signature': user['signature'],
        'ticket': loginData['ticket'],
        'blowfish': 'blowfish',
        'isTeacher': user['type'].toString().toInt() == 1,
        'unitId': loginData['unitid'],
        'workId': user['workid'],
//        'classId': user['class_id'],
        'gender': user['gender'].toString().toInt(),
      };

      await saveLoginInfo(userInfo);
      await initializeWebViewCookie();
      showToast('登录成功！');
      Instances.eventBus.fire(const TicketGotEvent(true));
      return true;
    }

    final String blowfish = const Uuid().v4();
    final Map<String, dynamic> params = Constants.loginParams(
      username: username,
      password: password,
      blowfish: blowfish,
    );
    await HiveBoxes.upBox.clear();
    await HiveBoxes.upBox.add(UPModel(username, password));
    try {
      final String webVpnFailedReason = await UserAPI.webVpnLogin();
      if (webVpnFailedReason != null) {
        showToast('校内网络通道连接失败 (0 WV $webVpnFailedReason)');
        NetUtils.webVpnNotifier.value = false;
      }
      final Map<String, dynamic> loginData = (await UserAPI.login(params)).data;
      currentUser = currentUser.copyWith(
        sid: loginData['sid'] as String,
        ticket: loginData['ticket'] as String,
      );
      await NetUtils.updateDomainsCookies(API.ndHosts);
      final Response<dynamic> userInfoResponse = await UserAPI.getUserInfo(
        uid: loginData['uid'].toString(),
      ) as Response<dynamic>;
      final Map<String, dynamic> user =
          (userInfoResponse.data as Map<dynamic, dynamic>)
              .cast<String, dynamic>();
      final Map<String, dynamic> userInfo = <String, dynamic>{
        'sid': loginData['sid'],
        'uid': loginData['uid'],
        'username': user['username'],
        'signature': user['signature'],
        'ticket': loginData['ticket'],
        'blowfish': blowfish,
        'isTeacher': user['type'].toString().toInt() == 1,
        'unitId': loginData['unitid'],
        'workId': user['workid'],
//        'classId': user['class_id'],
        'gender': user['gender'].toString().toInt(),
      };
      bool isWizard = true;
      if (!(userInfo['isTeacher'] as bool)) {
        isWizard = await checkWizard();
      }
      await saveLoginInfo(userInfo);
      await initializeWebViewCookie();
      showToast('登录成功！');
      Instances.eventBus.fire(TicketGotEvent(isWizard));
      return true;
    } on DioError catch (dioError) {
      LogUtils.e('Error when login: $dioError');
      showToast('登录失败 (0 ${dioError.response?.data ?? dioError})');
      return false;
    } catch (e) {
      LogUtils.e('Failed when login: $e');
      showToast('登录失败 (-1 DU)');
      return false;
    }
  }

  static void logout() {
    UserAPI.blacklist?.clear();
    MessageUtils.sendLogout();
    NetUtils.post<void>(API.logout).whenComplete(() {
      NetUtils.dio.clear();
      NetUtils.tokenDio.clear();
      NetUtils.cookieJar.deleteAll();
      NetUtils.tokenCookieJar.deleteAll();
      NetUtils.webViewCookieManager.deleteAllCookies();
      clearLoginInfo();
    });
    showToast('退出登录成功');
  }

  static Future<bool> checkWizard() async {
    final Map<String, dynamic> info = (await UserAPI.getStudentInfo()).data;
    if (info['wizard'].toString() == '1') {
      return true;
    } else {
      return false;
    }
  }

  static String recoverWorkId() => _settingsBox.get(spUserWorkId) as String;

  static void recoverLoginInfo() {
    final Map<String, dynamic> info = getSpTicket();
    currentUser = currentUser.copyWith(
      ticket: info['ticket'] as String,
    );
  }

  static Future<void> reFetchTicket() async {
    try {
      final bool result = await getTicket();
      if (!result) {
        throw Error.safeToString('Re-fetch ticket failed.');
      }
      bool isWizard;
      isWizard = true;
//      if (!currentUser.isTeacher) isWizard = await checkWizard();
      if (currentUser.sid != null) {
        UserAPI.initializeBlacklist();
      }
      final String isWebVPNLogin = await UserAPI.webVpnLogin();
      if (isWebVPNLogin == null) {
        await initializeWebViewCookie();
      } else {
        NetUtils.webVpnNotifier.value = false;
        LogUtils.e('Failed to login with WebVPN.');
      }
      Instances.eventBus.fire(TicketGotEvent(isWizard));
    } catch (e) {
      LogUtils.e('Error in recover login info: $e');
      Instances.eventBus.fire(TicketFailedEvent());
    }
  }

  static Future<void> getUserInfo() async {
    try {
      final DateTime _start = currentTime;
      final Map<String, dynamic> data =
          (await NetUtils.tokenDio.get<Map<String, dynamic>>(
        API.userInfo,
        queryParameters: <String, dynamic>{'uid': currentUser.uid},
      ))
              .data;
      final DateTime _end = currentTime;
      LogUtils.d('Done request user info in: ${_end.difference(_start)}');
      getUserInfoFromResponse(data);
    } catch (e) {
      LogUtils.e('Get user info error: $e');
    }
  }

  static void getUserInfoFromResponse(Map<String, dynamic> response) {
    final Map<String, dynamic> userInfo = <String, dynamic>{
      'sid': currentUser.sid,
      'uid': currentUser.uid,
      'username': response['username'],
      'signature': response['signature'],
      'blowfish': _settingsBox.get(spBlowfish),
      'ticket': _settingsBox.get(spTicket),
      'isTeacher': response['type'].toString().toInt() == 1,
      'unitId': response['unitid'],
      'workId': response['workid'],
//      'classId': data['class_id'],
      'gender': response['gender'].toString().toInt(),
    };
    setUserInfo(userInfo);
  }

  static void setUserInfo(Map<String, dynamic> data) {
    UserAPI.currentUser = UserInfo.fromJson(data);
    if (HiveFieldUtils.getEnabledNewAppsIcon() == null) {
      HiveFieldUtils.setEnabledNewAppsIcon(!(data['isTeacher'] as bool));
    }
  }

  static Future<void> saveLoginInfo(Map<String, dynamic> data) async {
    if (data != null) {
      setUserInfo(data);
      await _settingsBox.putAll(<dynamic, dynamic>{
        spBlowfish: data['blowfish'],
        spIsLogin: true,
        spTicket: data['ticket'],
        spUserUid: data['uid'],
        spUserWorkId: data['workId'],
      });
    }
  }

  /// 清除登录信息
  static Future<void> clearLoginInfo() async {
    final String workId = _settingsBox.get(spUserWorkId) as String;
    UserAPI.currentUser = const UserInfo();
    await _settingsBox.clear();
    await _settingsBox.put(spUserWorkId, workId);
  }

  static Map<String, dynamic> getSpTicket() {
    final Map<String, dynamic> tickets = <String, dynamic>{
      'ticket': _settingsBox.get(spTicket)
    };
    return tickets;
  }

  static Future<bool> getTicket() async {
    try {
      LogUtils.d('Fetch new ticket with: ${_settingsBox.get(spTicket)}');
      final Map<String, dynamic> params = Constants.loginParams(
        blowfish: _settingsBox.get(spBlowfish) as String,
        ticket: _settingsBox.get(spTicket) as String,
      );
      final DateTime _start = currentTime;
      final Map<String, dynamic> response =
          (await NetUtils.tokenDio.post<Map<String, dynamic>>(
        API.loginTicket,
        data: params,
      ))
              .data;
      final DateTime _end = currentTime;
      LogUtils.d('Done request new ticket in: ${_end.difference(_start)}');
      updateSid(response); // Using 99.
      await NetUtils.updateDomainsCookies(API.ndHosts);
      await getUserInfo();
      return true;
    } catch (e) {
      LogUtils.e('Error when getting ticket: $e');
      return false;
    }
  }

  static void updateSid(Map<String, dynamic> response) {
    currentUser = currentUser.copyWith(
      sid: response['sid'] as String,
      ticket: response['sid'] as String,
      uid: _settingsBox.get(spUserUid).toString(),
    );
  }

  /// Initialize WebView's cookie with 'iPlanetDirectoryPro'.
  /// 启动时通过 Session 初始化 WebView 的 Cookie
  static Future<bool> initializeWebViewCookie() async {
    final String url =
        'http://sso.jmu.edu.cn/imapps/2190?sid=${currentUser.sid}';
    final String replacedUrl =
        NetUtils.shouldUseWebVPN ? API.replaceWithWebVPN(url) : url;
    try {
      await NetUtils.head(
        replacedUrl,
        options: Options(
          followRedirects: false,
          receiveTimeout: 10000,
          sendTimeout: 10000,
        ),
      );
      LogUtils.d('Cookie response didn\'t return 302.');
      return false;
    } on DioError catch (dioError) {
      try {
        if (dioError.response.statusCode == HttpStatus.movedTemporarily) {
          for (final Cookie cookie in await NetUtils.cookieJar
              .loadForRequest(Uri.parse('http://www.jmu.edu.cn/'))) {
            await _setWebViewCookie(cookie);
          }
          for (final Cookie cookie in await NetUtils.tokenCookieJar
              .loadForRequest(Uri.parse('http://www.jmu.edu.cn/'))) {
            await _setWebViewCookie(cookie);
          }
          LogUtils.d('Successfully initialize WebView\'s Cookie.');
          return true;
        } else {
          LogUtils.e(
            'Error when initializing WebView\'s Cookie: $dioError',
            withStackTrace: false,
          );
          return false;
        }
      } catch (e) {
        LogUtils.e('Error when handling cookie response: $e');
        return false;
      }
    } catch (e) {
      LogUtils.e('Error when handling cookie response: $e');
      return false;
    }
  }

  static Future<bool> _setWebViewCookie(Cookie cookie) async {
    try {
      String _domain;
      if (cookie.domain == '.jmu.edu.cn') {
        _domain = 'www${cookie.domain}';
      }
      await NetUtils.webViewCookieManager.setCookie(
        url: Uri.parse('${_domain ?? cookie.domain}${cookie.path}'),
        name: cookie.name,
        value: cookie.value,
        domain: _domain ?? cookie.domain,
        path: cookie.path ?? '/',
        expiresDate: cookie.expires?.millisecondsSinceEpoch,
        isSecure: cookie.secure,
        maxAge: cookie.maxAge,
        sameSite: HTTPCookieSameSitePolicy.LAX,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 是否登录
  static bool isLogin() =>
      _settingsBox.get(spIsLogin) == true && HiveBoxes.upBox.isNotEmpty;
}
