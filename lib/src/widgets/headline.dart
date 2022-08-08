import 'package:flutter/material.dart';

const Duration headlineAnimationDuration = Duration(milliseconds: 600);

class Headline extends ImplicitlyAnimatedWidget {
  final String text;
  final int index;

  Color get targetColor => index == 0 ? Colors.black : Colors.blue;

  const Headline({Key? key, required this.text, required this.index})
      : super(key: key, duration: headlineAnimationDuration);

  @override
  _HeadlineState createState() => _HeadlineState();
}

class _HeadlineState extends AnimatedWidgetBaseState<Headline> {
  GhostFadeTween? _colorTween;
  SwitchStringTween? _stringTween;

  @override
  Widget build(BuildContext context) {
    return Text(
      (_stringTween == null) ? 'Loading' : _stringTween!.evaluate(animation),
      style: TextStyle(
        color: (_colorTween == null)
            ? Colors.amber
            : _colorTween!.evaluate(animation),
      ),
    );
  }

  @override
  void forEachTween(visitor) {
    _colorTween = visitor(_colorTween, widget.targetColor,
        (color) => GhostFadeTween(begin: color)) as GhostFadeTween;

    _stringTween = visitor(
            _stringTween, widget.text, (text) => SwitchStringTween(begin: text))
        as SwitchStringTween;
  }
}

@visibleForTesting
class GhostFadeTween extends Tween<Color> {
  final Color between = Colors.white;

  GhostFadeTween({Color? begin, Color? end}) : super(begin: begin, end: end);

  @override
  Color lerp(double t) {
    if (t < 0.5) {
      return Color.lerp(begin, between, t * 2)!;
    } else {
      return Color.lerp(between, end, (t - 0.5) * 2)!;
    }
  }
}

@visibleForTesting
class SwitchStringTween extends Tween<String> {
  SwitchStringTween({String? begin, String? end})
      : super(begin: begin, end: end);

  @override
  String lerp(double t) {
    return (t < 0.5) ? begin! : end!;
  }
}
