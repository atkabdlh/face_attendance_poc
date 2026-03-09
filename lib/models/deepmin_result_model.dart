enum DeepminResultStatus {
  initial,
  loading,
  success,
  error,
  cancel,
}

class DeepminResultModel {
  final DeepminResultStatus? status;
  final Map<String, dynamic>? data;
  final String? jobId;
  final String? matchName;
  final String? message;

  DeepminResultModel(
      {this.status, this.data, this.jobId, this.matchName, this.message});
}
