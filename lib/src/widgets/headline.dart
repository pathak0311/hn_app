import 'package:flutter/material.dart';

class Headline extends ImplicitlyAnimatedWidget {
  final String text;
  final int index;

  Color get targetColor => index == 0 ? Colors.black : Colors.blue;

  const Headline({Key? key, required this.text, required this.index})
      : super(key: key, duration: const Duration(milliseconds: 600));

  @override
  _HeadlineState createState() => _HeadlineState();
}

class _HeadlineState extends AnimatedWidgetBaseState<Headline> {
  _GhostFadeTween? _colorTween;
  _SwitchStringTween? _stringTween;

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
        (color) => _GhostFadeTween(begin: color)) as _GhostFadeTween;

    _stringTween = visitor(_stringTween, widget.text,
        (text) => _SwitchStringTween(begin: text)) as _SwitchStringTween;
  }
}

class _GhostFadeTween extends Tween<Color> {
  final Color between = Colors.white;

  _GhostFadeTween({Color? begin, Color? end}) : super(begin: begin, end: end);

  @override
  Color lerp(double t) {
    if (t < 0.5) {
      return Color.lerp(begin, between, t * 2)!;
    } else {
      return Color.lerp(between, end, (t - 0.5) * 2)!;
    }
  }
}

class _SwitchStringTween extends Tween<String> {
  _SwitchStringTween({String? begin, String? end})
      : super(begin: begin, end: end);

  @override
  String lerp(double t) {
    return (t < 0.5) ? begin! : end!;
  }
}
