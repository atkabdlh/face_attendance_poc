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
    // await Firebase.initializeApp();

    final client = AppClient(
      mykokuApiUrl: dotenv.env['API_URL'] ?? '',
      flaskApiUrl: dotenv.env['FLASK_API_URL'] ?? '',
    );

    // MykokuReporting mykokuReporting = MykokuReporting();
    // await mykokuReporting.initialize();

    // AuthenticationRepository authRepo =
    //     await AuthenticationRepository.initialize(client);
    DeepminRepository deepminRepo = await DeepminRepository.initialize(client);

    runApp(
      MultiRepositoryProvider(
        providers: [
          // RepositoryProvider.value(value: authRepo),
          RepositoryProvider.value(value: deepminRepo),
        ],
        child: MyApp(),
        // child: BlocProvider(
        //   create: (context) => AuthenticationBloc(
        //     authenticationRepository: authRepo,
        //   )..add(GetPrefs()),
        //   child: MyApp(
        //     localeService: localeService,
        //   ),
        // ),
      ),
    );
  }, (error, stack) {
    print('runZonedGuarded Error: $error');
  });
  // }, zoneSpecification: AppLogger().zoneSpec());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/landing',
      title: 'Mykoku Attendance Demo',
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
