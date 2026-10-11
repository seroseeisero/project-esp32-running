import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/home_shell.dart';
import 'services/mock_sensor_service.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GaitAlertApp());
}

class GaitAlertApp extends StatefulWidget {
  const GaitAlertApp({super.key});

  @override
  State<GaitAlertApp> createState() => _GaitAlertAppState();
}

class _GaitAlertAppState extends State<GaitAlertApp> {
  // เมื่อต่อเซนเซอร์จริง ให้เปลี่ยนเป็น BleSensorService()
  late final AppState _state = AppState(MockSensorService());

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'Gait Alert',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B)),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00897B),
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}
