import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoodiaryWebApp());
}

class MoodiaryWebApp extends StatelessWidget {
  const MoodiaryWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moodiary',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const Scaffold(
        body: Center(
          child: Text('Web build is available. Native-only features are disabled.'),
        ),
      ),
    );
  }
}
