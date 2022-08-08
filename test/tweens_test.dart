import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hn_app/src/widgets/headline.dart';

void main() {
  group("GhostFadeTween", () {
    test('interpolates color correctly', () {
      Color blue = const Color.fromARGB(255, 0, 0, 255);
      Color red = const Color.fromARGB(255, 255, 0, 255);
      Color white = const Color.fromARGB(255, 255, 255, 255);

      GhostFadeTween tween = GhostFadeTween(begin: blue, end: red);

      expect(tween.lerp(0.0), blue);
      expect(tween.lerp(0.5), white);
      expect(tween.lerp(1.0), red);
    });
  });
}
