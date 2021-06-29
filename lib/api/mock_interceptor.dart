///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2020-11-16 22:54
///
import 'package:dio/dio.dart';
import 'package:openjmu/utils/utils.dart';

class MockingInterceptor extends Interceptor {
  static const String HTTP_TAG = 'Mock - LOG';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    /// Set Mock Data
    /// 设置模拟数据
    final String _uri = options.uri.toString();

    if (NetUtils.mockData.containsKey(_uri)) {
      return handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          data: NetUtils.mockData[_uri],
        ),
      );
    }

    handler.reject(DioError(requestOptions: options, error: 'Mock - Reject'));
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    /// Catch Mock Data
    /// 抓取模拟数据
    // NetUtils.mockData[response.requestOptions.uri.toString()] = response.data;
    // final String _mockDataString = jsonEncode(NetUtils.mockData);
    // return;
  }

  @override
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) {
    LogUtils.e(
      '------------------- Error -------------------',
      tag: HTTP_TAG,
    );
    handler.next(err);
  }
}
