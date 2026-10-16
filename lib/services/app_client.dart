import 'dart:convert';
import 'package:http/http.dart';
import 'package:mykoku_attendance/services/app_storage.dart';

enum ApiType { flask, attn }

class AppClient {
  final Client _client;
  final String attnApiUrl;
  final String flaskApiUrl;

  AppClient({String? attnApiUrl, String? flaskApiUrl, Client? client})
      : _client = client ?? Client(),
        attnApiUrl = attnApiUrl ?? '',
        flaskApiUrl = flaskApiUrl ?? '';

  Future<Response> get(String endpoint, ApiType apiType,
      {bool requiresAuth = true, bool? getPdf}) async {
    final headers = await _buildHeaders(requiresAuth);
    final response = await _client.get(
      Uri.parse(
          '${apiType == ApiType.attn ? attnApiUrl : flaskApiUrl}/$endpoint'),
      headers: headers,
    );
    return _handleResponse(response, apiType);
  }

  Future<Response> post(
      String endpoint, Map<String, dynamic> body, ApiType apiType,
      {bool requiresAuth = true, bool requiresCsrf = false}) async {
    final headers =
        await _buildHeaders(requiresAuth, requiresCsrf: requiresCsrf);
    final response = await _client.post(
      Uri.parse(
          '${apiType == ApiType.attn ? attnApiUrl : flaskApiUrl}/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    print('deepminrepo post response: $response');
    return _handleResponse(response, apiType);
  }

  Future<Response> postMultipart(
    String endpoint,
    Map<String, String> fields,
    List<MultipartFile> files,
    ApiType apiType, {
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth);
    headers['Content-Type'] = 'multipart/form-data';

    final request = MultipartRequest(
        'POST',
        Uri.parse(
            '${apiType == ApiType.attn ? attnApiUrl : flaskApiUrl}/$endpoint'))
      ..headers.addAll(headers)
      ..fields.addAll(fields)
      ..files.addAll(files);

    final streamed = await request.send();
    final response = await Response.fromStream(streamed);
    return _handleResponse(response, apiType);
  }

  Future<Response> put(
      String endpoint, Map<String, dynamic> body, ApiType apiType,
      {bool requiresAuth = true}) async {
    final headers = await _buildHeaders(requiresAuth);
    final response = await _client.put(
      Uri.parse(
          '${apiType == ApiType.attn ? attnApiUrl : flaskApiUrl}/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, apiType);
  }

  Future<Response> delete(String endpoint, ApiType apiType,
      {bool requiresAuth = true}) async {
    final headers = await _buildHeaders(requiresAuth);
    final response = await _client.delete(
      Uri.parse(
          '${apiType == ApiType.attn ? attnApiUrl : flaskApiUrl}/$endpoint'),
      headers: headers,
    );
    return _handleResponse(response, apiType);
  }

  Future<Map<String, String>> _buildHeaders(bool requiresAuth,
      {bool pdfresponse = false, bool requiresCsrf = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': pdfresponse ? 'application/pdf' : 'application/json',
    };

    if (requiresAuth) {
      final token = await AppStorage().read(AppStorageKey.accessToken);
      if (token != null) {
        headers['Authorization'] = '$token';
      }
    }

    if (requiresCsrf) {
      final cookie = await AppStorage().read(AppStorageKey.csrfCookie);
      if (cookie != null) {
        headers['Cookie'] = cookie;
      }
    }

    return headers;
  }

  Response _handleResponse(Response response, ApiType apiType) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      Map<String, dynamic> responseBody = json.decode(response.body);
      print('error response body: ${response.body}');
      // throw Exception('API Error: ${response.statusCode} - ${response.body}');
      throw Exception(responseBody['errors'] != null
          ? responseBody['errors']['message'][0]
          : responseBody['message'] ??
              '${apiType == ApiType.attn ? 'Attendance' : 'Flask'} API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
