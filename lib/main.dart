
import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'screens/sign_in_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Initialize Flutter before accessing SQLite.
  WidgetsFlutterBinding.ensureInitialized();

  // Insert demo team members and tasks.
  // Existing records will not be overwritten.
  await DatabaseHelper.instance.seedDemoData();

  // Start the application.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SLA Task Tracker',
      theme: AppTheme.light,
      home: const SignInScreen(),
    );
  }
}
