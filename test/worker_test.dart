import 'package:flutter_test/flutter_test.dart';
import 'package:hn_app/src/notifiers/hn_api.dart';
import 'package:hn_app/src/notifiers/worker.dart';

void main() {
  test('worker capitalizes', () async {
    final worker = Worker();
    await worker.isReady;
    worker.dispose();
  });
}