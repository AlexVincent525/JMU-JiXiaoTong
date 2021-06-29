import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/adapter.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as web_view
    show Cookie, CookieManager;
import 'package:open_file/open_file.dart';
import 'package:openjmu/api/mock_interceptor.dart';
import 'package:path_provider/path_provider.dart';

import 'package:openjmu/constants/constants.dart';

class NetUtils {
  const NetUtils._();

  static const bool _isProxyEnabled = false;
  static const String _proxyDestination = 'PROXY 192.168.1.23:8764';

  static const bool shouldLogRequest = true;

  static final Dio dio = Dio(_options);
  static final Dio tokenDio = Dio(_options);

  static Future<Directory> get _tempDir => getTemporaryDirectory();
  static final ValueNotifier<bool> webVpnNotifier = ValueNotifier<bool>(false);

  static bool get shouldUseWebVPN => webVpnNotifier.value;

  static PersistCookieJar cookieJar;
  static PersistCookieJar tokenCookieJar;
  static CookieManager cookieManager;
  static CookieManager tokenCookieManager;
  static final web_view.CookieManager webViewCookieManager =
      web_view.CookieManager.instance();

  /// Mock Data
  static Map<String, dynamic> mockData = <String, dynamic>{};

  /// Method to Load Mock Data
  static Future<void> loadMockSources() async {
    mockData =
        jsonDecode(await rootBundle.loadString('assets/mock/mock_data.json'))
            as Map<String, dynamic>;
  }

  /// Method to update ticket.
  static Future<void> updateTicket() async {
    // Lock and clear dio while requesting new ticket.
    dio
      ..lock()
      ..clear();

    if (await DataUtils.getTicket()) {
      LogUtils.d(
        'Ticket updated success with new ticket: ${currentUser.sid}',
      );
    } else {
      LogUtils.e('Ticket updated error: ${currentUser.sid}');
    }
    // Release lock.
    dio.unlock();
  }

  static Future<void> initConfig() async {
    await initCookieManagement();

    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        _clientCreate;

    dio.interceptors..add(cookieManager)..add(MockingInterceptor());

    (tokenDio.httpClientAdapter as DefaultHttpClientAdapter)
        .onHttpClientCreate = _clientCreate;
    tokenDio.interceptors..add(tokenCookieManager)..add(MockingInterceptor());

    // if (Constants.isDebug && shouldLogRequest) {
    //   dio.interceptors.add(LoggingInterceptor());
    //   tokenDio.interceptors.add(LoggingInterceptor());
    // }
  }

  static Future<void> initCookieManagement() async {
    // Initialize cookie jars.
    final Directory _d = await _tempDir;
    if (!Directory('${_d.path}/cookie_jar').existsSync()) {
      Directory('${_d.path}/cookie_jar').createSync();
    }
    if (!Directory('${_d.path}/token_cookie_jar').existsSync()) {
      Directory('${_d.path}/token_cookie_jar').createSync();
    }
    if (!Directory('${_d.path}/web_view_cookie_jar').existsSync()) {
      Directory('${_d.path}/web_view_cookie_jar').createSync();
    }
    cookieJar = PersistCookieJar(
      storage: FileStorage('${_d.path}/cookie_jar'),
    );
    tokenCookieJar = PersistCookieJar(
      storage: FileStorage('${_d.path}/token_cookie_jar'),
    );
    cookieManager = CookieManager(cookieJar);
    tokenCookieManager = CookieManager(tokenCookieJar);
  }

  static List<Cookie> convertWebViewCookies(List<web_view.Cookie> cookies) {
    if (cookies?.isNotEmpty != true) {
      return const <Cookie>[];
    }
    final List<Cookie> replacedCookies = cookies.map((web_view.Cookie cookie) {
      return Cookie(cookie.name, Uri.encodeComponent(cookie.value.toString()))
        ..domain = cookie.domain
        ..httpOnly = cookie.isHttpOnly ?? false
        ..secure = cookie.isSecure ?? false
        ..path = cookie.path;
    }).toList();
    return replacedCookies;
  }

  /// Get header only.
  ///
  /// This request is targeted to get filename directly.
  static Future<String> head(
    String url, {
    Map<String, dynamic> queryParameters,
    Map<String, dynamic> data,
    CancelToken cancelToken,
    Options options,
  }) async {
    final Response<dynamic> res = await dio.head<dynamic>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options ?? Options(followRedirects: true),
    );
    String filename = res.headers
        ?.value('content-disposition')
        ?.split('; ')
        ?.where((String element) => element.contains('filename'))
        ?.first;
    if (filename != null) {
      final RegExp filenameReg = RegExp(r'filename=\"(.+)\"');
      filename = filenameReg.allMatches(filename).first.group(1);
      filename = Uri.decodeComponent(filename);
    } else {
      filename = url.split('/').last.split('?')?.first;
    }
    return filename;
  }

  /// Get response through bytes.
  ///
  /// For now it provides response for image saving.
  static Future<Response<T>> getBytes<T>(
    String url, {
    Map<String, dynamic> queryParameters,
    Map<String, dynamic> headers,
    CancelToken cancelToken,
    Options options,
  }) =>
      dio.get<T>(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(
          headers: headers ?? _buildPostHeaders(currentUser.sid),
          responseType: ResponseType.bytes,
        ),
      );

  static Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic> queryParameters,
    Map<String, dynamic> headers,
    CancelToken cancelToken,
    Options options,
  }) =>
      dio.get<T>(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(
          headers: headers ?? _buildPostHeaders(currentUser.sid),
        ),
      );

  static Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic> queryParameters,
    Map<String, dynamic> headers,
    CancelToken cancelToken,
    Options options,
  }) async =>
      await dio.post<T>(
        url,
        queryParameters: queryParameters,
        data: data,
        options: (options ?? Options()).copyWith(
          headers: headers ?? _buildPostHeaders(currentUser.sid),
        ),
        cancelToken: cancelToken,
      );

  static Future<Response<T>> delete<T>(
    String url, {
    Map<String, dynamic> queryParameters,
    Map<String, dynamic> data,
    Map<String, dynamic> headers,
    CancelToken cancelToken,
    Options options,
  }) =>
      dio.delete<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(
          headers: headers ?? _buildPostHeaders(currentUser.sid),
        ),
      );

  /// For download progress, here we don't simply use the [dio.download],
  /// because there's no file name provided. So in here we take two steps:
  /// * Using [head] to get the 'content-disposition' in headers to determine
  ///   the real file name of the attachment.
  /// * Call [dio.download] to download the file with the real name.
  static Future<Response<dynamic>> download(
    String url,
    String filename, {
    Map<String, dynamic> data,
    Map<String, dynamic> headers,
    CancelToken cancelToken,
    Options options,
  }) async {
    String path;
    if (await checkPermissions(<Permission>[Permission.storage])) {
      showToast('开始下载 ...');
      LogUtils.d('File start download: $url');
      path = '${(await getExternalStorageDirectory()).path}/$filename';
      try {
        final Response<dynamic> response = await dio.download(
          url,
          path,
          data: data,
          cancelToken: cancelToken,
          options: (options ?? Options()).copyWith(
            headers: headers ?? _buildPostHeaders(currentUser.sid),
          ),
        );
        LogUtils.d('File downloaded: $path');
        showToast('下载完成 $path');
        final OpenResult openFileResult = await OpenFile.open(path);
        LogUtils.d('File open result: ${openFileResult.type}');
        return response;
      } catch (e) {
        LogUtils.e('File download failed: $e');
        return null;
      }
    } else {
      LogUtils.e('No permission to download file: $url');
      showToast('未获得存储权限');
      return null;
    }
  }

  static Map<String, dynamic> _buildPostHeaders(String sid) {
    final Map<String, String> headers = <String, String>{
      'CLOUDID': 'jmu',
      'CLOUD-ID': 'jmu',
      'UAP-SID': sid,
      'WEIBO-API-KEY': Platform.isIOS
          ? Constants.postApiKeyIOS
          : Constants.postApiKeyAndroid,
      'WEIBO-API-SECRET': Platform.isIOS
          ? Constants.postApiSecretIOS
          : Constants.postApiSecretAndroid,
    };
    return headers;
  }

  static List<Cookie> _buildPHPSESSIDCookies(String sid) => <Cookie>[
        if (sid != null) Cookie('PHPSESSID', sid),
        if (sid != null) Cookie('OAPSID', sid),
      ];

  static Future<void> updateDomainsCookies(
    List<String> urls, [
    List<Cookie> cookies,
  ]) async {
    final List<Cookie> _cookies =
        cookies ?? _buildPHPSESSIDCookies(currentUser.sid);
    for (final String url in urls) {
      String _url = url;
      if (!_url.endsWith('/')) {
        _url += '/';
      }
      await Future.wait<void>(
        <Future<void>>[
          cookieJar.saveFromResponse(Uri.parse(_url), _cookies),
          tokenCookieJar.saveFromResponse(Uri.parse(_url), _cookies),
        ],
      );
    }
  }

  /// 通过测试「课堂助理」应用，判断是否需要使用 WebVPN。
  static Future<void> testClassKit() async {
    dio.lock();
    try {
      await tokenDio.get<String>(
        API.classKitHost,
        options: Options(contentType: 'text/html;charset=utf-8'),
      );
      webVpnNotifier.value = false;
    } on DioError catch (dioError) {
      if (dioError.response?.statusCode == HttpStatus.forbidden) {
        webVpnNotifier.value = true;
        return;
      }
      webVpnNotifier.value = false;
    } catch (e) {
      LogUtils.e('Error when testing classKit: $e');
      webVpnNotifier.value = false;
    } finally {
      dio.unlock();
    }
  }

  static BaseOptions get _options {
    return BaseOptions(
      connectTimeout: 20000,
      sendTimeout: 10000,
      receiveTimeout: 10000,
      receiveDataWhenStatusError: true,
      followRedirects: true,
    );
  }

  static dynamic Function(HttpClient client) get _clientCreate {
    return (HttpClient client) {
      if (_isProxyEnabled) {
        client.findProxy = (_) => _proxyDestination;
      }
      client.badCertificateCallback = (_, __, ___) => true;
    };
  }

  // static InterceptorsWrapper get _interceptor {
  //   return InterceptorsWrapper(
  //     onError: (
  //       DioError e,
  //       ErrorInterceptorHandler handler,
  //     ) {
  //       if (e.response?.isRedirect == true ||
  //           e.response?.statusCode == HttpStatus.movedPermanently ||
  //           e.response?.statusCode == HttpStatus.movedTemporarily ||
  //           e.response?.statusCode == HttpStatus.seeOther ||
  //           e.response?.statusCode == HttpStatus.temporaryRedirect) {
  //         handler.next(e);
  //         return;
  //       }
  //       if (e.response?.statusCode == 401) {
  //         LogUtils.e(
  //           'Session is outdated, calling update...',
  //           withStackTrace: false,
  //         );
  //         updateTicket();
  //       }
  //       LogUtils.e(
  //         'Error when requesting ${e.requestOptions.uri} '
  //         '${e.response?.statusCode}'
  //         ': ${e.response?.data}',
  //         withStackTrace: false,
  //       );
  //       handler.reject(e);
  //     },
  //   );
  // }
}
