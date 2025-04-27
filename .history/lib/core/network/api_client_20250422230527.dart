@riverpod
class ApiClient extends _$ApiClient {
  late final Dio _dio;
  
  @override
  void build() {
    _dio = Dio()
      ..interceptors.addAll([
        AuthInterceptor(ref),
        CacheInterceptor(),
        RetryInterceptor(),
      ]);
  }

  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CachePolicy? cachePolicy,
  }) async {
    // Implement caching, retry logic, etc.
  }
}