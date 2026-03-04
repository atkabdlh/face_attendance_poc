import 'package:flutter/material.dart';
import 'package:mykoku_attendance/screens/home/home_page.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // initialRoute: '/home',
      title: 'Mykoku Attendance Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink[200]!),
        useMaterial3: true,
      ),
      home: const HomePage(),
      // onGenerateRoute: (settings) {
      //   switch (settings.name) {
      //     case '/landing':
      //       return MaterialPageRoute(
      //         builder: (context) => const LandingPage(),
      //       );
      //     case '/home':
      //       return MaterialPageRoute(
      //         builder: (context) => const HomePage(),
      //       );
      //     case '/settings':
      //       return MaterialPageRoute(
      //         builder: (context) => const SettingsPage(),
      //       );
      //     default:
      //       return MaterialPageRoute(builder: (_) => const HomePage());
      //   }
      // },
    );
  }
}
