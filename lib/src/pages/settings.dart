import 'package:flutter/material.dart';
import 'package:hn_app/src/notifiers/prefs.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  final Animation<double> initialAnimation;

  const SettingsPage({Key? key, required this.initialAnimation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: initialAnimation,
      builder: (BuildContext context, double value, Widget? child) {
        return Theme(
          data: ThemeData(
            canvasColor:
                ColorTween(begin: const Color(0x00FFFFFF), end: Colors.white)
                    .transform(value),
          ),
          child: child!,
        );
      },
      child: Scaffold(
        appBar: AppBar(),
        body: Column(
          children: [
            const Text('Use Dark Mode'),
            Switch(
              value: Provider.of<PrefsNotifier>(context).userDarkMode,
              onChanged: (bool value) {
                Provider.of<PrefsNotifier>(context, listen: false)
                    .userDarkMode = value;
              },
            ),
          ],
        ),
      ),
    );
  }
}
