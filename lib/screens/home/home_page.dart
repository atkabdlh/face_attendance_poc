import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mykoku_attendance/screens/scanner/scanner_initial.dart';
import 'package:mykoku_attendance/services/app_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppClient client = AppClient(dotenv.env['FLASK_API_URL']!);
  Future<Map<String, dynamic>?> healthCheck() async {
    String healthCheckUrl = 'health';

    try {
      Response response = await client.get(healthCheckUrl, requiresAuth: false);

      var decodedBody = utf8.decode(response.bodyBytes);
      var result = json.decode(decodedBody);
      var statusCode = response.statusCode;

      print('healthCheck statusCode: $statusCode');
      print('healthCheck result: $result');
      return result;
    } catch (e) {
      print('deepminrepo healthCheck error: $e');
      print('deepminrepo healthCheck error: ${e.toString()}');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mykoku Attendance Demo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder(
                future: healthCheck(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    print('healthCheck snapshot: ${snapshot}');
                    return Text(
                        'minimal deepface API status: ${snapshot.data?['status']}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
            ListTile(
              leading: const Icon(Icons.face),
              title: Text('Initial Scan'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                print('Initial Scan');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScannerInitial(),
                    ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: Text('Check In Attendance'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                print('Check In Attendance');
              },
            ),
          ],
        ),
      ),
    );
  }
}
