import 'package:flutter/material.dart';
import 'package:face_attendance_poc/models/deepmin_result_model.dart';
import 'package:face_attendance_poc/screens/scanner/scanner_page.dart';
import 'package:face_attendance_poc/services/repositories/deepmin_repositories.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DeepminRepository deepminRepository = DeepminRepository();

  Future<String> healthCheck() async {
    DeepminResultModel result = await deepminRepository.healthCheck();
    return result.message ??
        'Failed to get server status, please try again later.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Attendance Demo'),
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
                        'minimal deepface API status: ${snapshot.data}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
            ListTile(
              leading: const Icon(Icons.face),
              title: Text('Face Enrollment'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScannerPage(
                        mode: ScannerMode.enrollment,
                      ),
                    ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: Text('Face Recognition'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScannerPage(
                        mode: ScannerMode.recognition,
                      ),
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
