import 'dart:convert';

import 'package:http/http.dart';
import 'package:mykoku_attendance/models/deepmin_result_model.dart';
import 'package:mykoku_attendance/services/app_client.dart';

class DeepminRepository {
  static final DeepminRepository _instance = DeepminRepository._internal();

  factory DeepminRepository() => _instance;

  late final AppClient client;

  DeepminRepository._internal();

  static Future<DeepminRepository> initialize(AppClient client) async {
    _instance.client = client;

    return _instance;
  }

  Future<DeepminResultModel> healthCheck() async {
    String healthCheckUrl = 'health';

    try {
      Response response =
          await client.get(healthCheckUrl, ApiType.flask, requiresAuth: false);

      var decodedBody = utf8.decode(response.bodyBytes);
      var result = json.decode(decodedBody);
      var statusCode = result['code'] ?? response.statusCode;

      if (statusCode == 200) {
        return DeepminResultModel(
          message: result['message'] ?? 'Successfully fetch server status.',
          status: DeepminResultStatus.success,
        );
      } else {
        return DeepminResultModel(
            message: result['message'] ??
                'Failed to get server status, please try again later.',
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

  Future<DeepminResultModel> listJobs() async {
    String pendingJobsUrl = 'list-jobs';

    try {
      Response response =
          await client.get(pendingJobsUrl, ApiType.flask, requiresAuth: false);

      var decodedBody = utf8.decode(response.bodyBytes);
      var result = json.decode(decodedBody);
      var statusCode = result['code'] ?? response.statusCode;

      if (statusCode == 200) {
        return DeepminResultModel(
          message: result['message'] ?? 'Successfully fetch pending jobs.',
          status: DeepminResultStatus.success,
        );
      } else {
        return DeepminResultModel(
            message: result['message'] ??
                'Failed to get pending jobs, please try again later.',
            status: DeepminResultStatus.error);
      }
    } catch (e) {
      print('deepminrepo listJobs error: $e');
      return DeepminResultModel(
        message: e.toString(),
        status: DeepminResultStatus.error,
      );
    }
  }

  Future<DeepminResultModel> getJobResult(String jobId) async {
    String jobResultUrl = 'job-result/$jobId';

    try {
      Response response =
          await client.get(jobResultUrl, ApiType.flask, requiresAuth: false);

      var decodedBody = utf8.decode(response.bodyBytes);
      var result = json.decode(decodedBody);
      var statusCode = result['code'] ?? response.statusCode;

      if (statusCode == 200) {
        return DeepminResultModel(
          message: result['message'] ?? 'Successfully fetch job result.',
          matchName: result['matches']['name'],
          status: DeepminResultStatus.success,
        );
      } else {
        return DeepminResultModel(
            message: result['message'] ??
                'Failed to get pending jobs, please try again later.',
            status: DeepminResultStatus.error);
      }
    } catch (e) {
      print('deepminrepo getJobResult error: $e');
      return DeepminResultModel(
        message: e.toString(),
        status: DeepminResultStatus.error,
      );
    }
  }

  Future<DeepminResultModel> registerFace(
      String name, String imageBase64) async {
    String registerFaceUrl = 'register-student';

    Map<String, dynamic> body = {
      'name': name,
      'image': imageBase64,
    };

    try {
      Response response = await client
          .post(registerFaceUrl, body, ApiType.flask, requiresAuth: false);

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
            message: result['message'] ??
                'Failed to register face, please try again later.',
            status: DeepminResultStatus.error);
      }
    } catch (e) {
      print('deepminrepo registerFace error: $e');
      return DeepminResultModel(
        message: e.toString(),
        status: DeepminResultStatus.error,
      );
    }
  }

  Future<DeepminResultModel> recognizeFace(String imageBase64) async {
    String recognizeFaceUrl = 'get-all-students';

    Map<String, dynamic> body = {
      'image': imageBase64,
    };

    try {
      Response response = await client
          .post(recognizeFaceUrl, body, ApiType.flask, requiresAuth: false);

      print('deepminrepo recognizeFace response: $response');

      var decodedBody = utf8.decode(response.bodyBytes);
      var result = json.decode(decodedBody);
      var statusCode = result['code'] ?? response.statusCode;

      if (statusCode == 200) {
        return DeepminResultModel(
          message: result['message'] ?? 'Successfully recognize face.',
          jobId: result['job_id'],
          status: DeepminResultStatus.success,
        );
      } else {
        return DeepminResultModel(
            message: result['message'] ??
                'Failed to recognize face, please try again later.',
            status: DeepminResultStatus.error);
      }
    } catch (e) {
      print('deepminrepo recognizeFace error: $e');
      return DeepminResultModel(
        message: e.toString(),
        status: DeepminResultStatus.error,
      );
    }
  }
}
