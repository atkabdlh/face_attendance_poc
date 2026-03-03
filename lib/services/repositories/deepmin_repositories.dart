import 'dart:convert';

import 'package:http/http.dart';
import 'package:mykoku_attendance/models/deepmin_result_model.dart';
import 'package:mykoku_attendance/services/app_client.dart';

class DeepminRepository {
  static final DeepminRepository _instance = DeepminRepository._internal();

  factory DeepminRepository() => _instance;

  late final AppClient client;

  DeepminRepository._internal();

  Future<DeepminResultModel> healthCheck(String email, String password,
      {bool rememberUser = false}) async {
    String healthCheckUrl = 'user/health';

    try {
      Response response = await client.get(healthCheckUrl, requiresAuth: false);

      var decodedBody = utf8.decode(response.bodyBytes);
      var result = json.decode(decodedBody);
      var statusCode = result['code'] ?? response.statusCode;

      if (statusCode == 200) {
        return DeepminResultModel(
          message: result['status'] ?? 'Success',
          status: DeepminResultStatus.success,
        );
      } else {
        return DeepminResultModel(
            message:
                result['status'] ?? 'Failed to login, please try again later.',
            status: DeepminResultStatus.error);
      }
    } catch (e) {
      print('deepminrepo healthCheck error: $e');
      return DeepminResultModel(
        message: e.toString(),
        status: DeepminResultStatus.error,
      );
    }
  }
}
