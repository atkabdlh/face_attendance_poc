import 'dart:async';

class Debouncer {
  final int? milliseconds;
  final int? seconds;
  Timer? _timer;
  Debouncer({this.milliseconds, this.seconds});
  void run(void Function() action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(
      seconds != null
          ? Duration(seconds: seconds ?? 1)
          : Duration(milliseconds: milliseconds ?? 300),
      action,
    );
  }
}
