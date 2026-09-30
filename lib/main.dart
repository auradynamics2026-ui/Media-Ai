import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'services/backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Backend.i.init();
  runApp(const MediaAiApp());
}

class MediaAiApp extends StatelessWidget {
  const MediaAiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Media AI',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Backend.i.email == null ? const LoginScreen() : const Shell(),
      );
}
