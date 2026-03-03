import 'dart:convert';

import 'package:http/http.dart';
import 'package:mykoku_attendance/services/app_storage.dart';

class AppClient {
  final Client _client;
  final String apiUrl;

  AppClient(this.apiUrl, {Client? client}) : _client = client ?? Client();

  Future<Response> get(String endpoint,
      {bool requiresAuth = true, bool? getPdf}) async {
    final headers = await _buildHeaders(requiresAuth);
    final response = await _client.get(
      Uri.parse('$apiUrl/$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Response> post(String endpoint, Map<String, dynamic> body,
      {bool requiresAuth = true, bool requiresCsrf = false}) async {
    final headers =
        await _buildHeaders(requiresAuth, requiresCsrf: requiresCsrf);
    final response = await _client.post(
      Uri.parse('$apiUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Response> postMultipart(
    String endpoint,
    Map<String, String> fields,
    List<MultipartFile> files, {
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth);
    headers['Content-Type'] = 'multipart/form-data';

    final request = MultipartRequest('POST', Uri.parse('$apiUrl/$endpoint'))
      ..headers.addAll(headers)
      ..fields.addAll(fields)
      ..files.addAll(files);

    final streamed = await request.send();
    final response = await Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<Response> put(String endpoint, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final headers = await _buildHeaders(requiresAuth);
    final response = await _client.put(
      Uri.parse('$apiUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Response> delete(String endpoint, {bool requiresAuth = true}) async {
    final headers = await _buildHeaders(requiresAuth);
    final response = await _client.delete(
      Uri.parse('$apiUrl/$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
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

  Response _handleResponse(Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      Map<String, dynamic> responseBody = json.decode(response.body);
      print('error response body: ${response.body}');
      // throw Exception('API Error: ${response.statusCode} - ${response.body}');
      throw Exception(responseBody['errors'] != null
          ? responseBody['errors']['message'][0]
          : responseBody['message'] ??
              'API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
