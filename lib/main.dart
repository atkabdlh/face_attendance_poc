import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mykoku_attendance/screens/authentication/landing_page.dart';
import 'package:mykoku_attendance/screens/home/home_page.dart';
import 'package:mykoku_attendance/screens/settings/settings_page.dart';
import 'package:mykoku_attendance/services/app_client.dart';
import 'package:mykoku_attendance/services/repositories/deepmin_repositories.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");

  runZonedGuarded(() async {
    final client = AppClient(
      attnApiUrl: dotenv.env['API_URL'] ?? '',
      flaskApiUrl: dotenv.env['FLASK_API_URL'] ?? '',
    );

    DeepminRepository deepminRepo = await DeepminRepository.initialize(client);

    runApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: deepminRepo),
        ],
        child: MyApp(),
      ),
    );
  }, (error, stack) {
    print('runZonedGuarded Error: $error');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/landing',
      title: 'Face Attendance Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink[200]!),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/landing':
            return MaterialPageRoute(
              builder: (context) => const LandingPage(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const HomePage(),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            );
          default:
            return MaterialPageRoute(builder: (_) => const HomePage());
        }
      },
    );
  }
}
