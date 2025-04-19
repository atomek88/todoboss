import 'package:dio/dio.dart';
import 'package:todoApp/data/remote/api/cient/api_client.dart';

final mockApiClient = ApiClient(Dio(), baseUrl: "");
