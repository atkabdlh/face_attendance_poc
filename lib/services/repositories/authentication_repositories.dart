// import 'dart:convert';

// import 'package:encrypt/encrypt.dart';
// import 'package:flutter_appauth/flutter_appauth.dart';
// import 'package:http/http.dart';

// enum AuthenticationStatus {
//   unknown,
//   authenticated,
//   unauthenticated,
//   maintenance,
//   offline,
// }

// class AuthenticationRepository {
//   static final AuthenticationRepository _instance =
//       AuthenticationRepository._internal();

//   factory AuthenticationRepository() => _instance;

//   late final MykokuClient client;
//   final FlutterAppAuth appAuth = FlutterAppAuth();

//   AuthenticationStatus _status = AuthenticationStatus.unknown;

//   AuthenticationStatus get status => _status;

//   AuthenticationRepository._internal();

//   static Future<AuthenticationRepository> initialize(
//       MykokuClient client) async {
//     _instance.client = client;

//     await _instance.updateStatus();

//     final accessToken = await AppStorage().read(AppStorageKey.accessToken);

//     print('api url: ${client.apiUrl}');
//     print('accessToken: $accessToken');

//     return _instance;
//   }

//   Future<void> updateStatus() async {
//     try {
//       String? savedToken = await AppStorage().read(AppStorageKey.accessToken);

//       if (savedToken != null && savedToken.isNotEmpty) {
//         String getProfilelUrl = 'user/profile';
//         Response response = await client.get(getProfilelUrl);

//         var decodedBody = utf8.decode(response.bodyBytes);
//         var result = json.decode(decodedBody);
//         var statusCode = result['code'] ?? response.statusCode;

//         if (statusCode == 200) {
//           _status = AuthenticationStatus.authenticated;
//           // Get token and register to backend
//           final fcmToken = await FirebaseMessaging.instance.getToken();
//           print('fcmToken: $fcmToken');

//           if (fcmToken != null && fcmToken.isNotEmpty) {
//             AppStorage().write(AppStorageKey.fcmToken, fcmToken);
//             await deviceToken(fcmToken);
//           }
//         } else if (statusCode == 503) {
//           _status = AuthenticationStatus.maintenance;
//         } else {
//           _status = AuthenticationStatus.unauthenticated;
//         }
//       } else {
//         _status = AuthenticationStatus.unauthenticated;
//       }
//     } catch (error) {
//       print('updateStatus error: $error');
//       _status = AuthenticationStatus.unauthenticated;
//     }
//   }

//   Future<void> saveTokens(String accessToken, int? parentId) async {
//     await AppStorage().write(AppStorageKey.accessToken, accessToken);
//     await AppStorage().write(AppStorageKey.parentId, parentId.toString());
//     _status = AuthenticationStatus.authenticated;

//     print('Tokens saved. Auth status: $_status');
//   }

//   Future<void> deleteTokens() async {
//     await AppStorage().delete(AppStorageKey.accessToken);
//     _status = AuthenticationStatus.unauthenticated;

//     print('Tokens deleted. Auth status: $_status');
//   }

//   Future<Key?> _getOrCreateKey(String? fileName) async {
//     final dir = await getApplicationDocumentsDirectory();
//     final keyFile = File('${dir.path}/$fileName');

//     if (await keyFile.exists()) {
//       return Key(await keyFile.readAsBytes());
//     } else {
//       // Only clear the current environment's key, not both
//       final currentKey = AppConfig().isProd
//           ? AppStorageKey.encryptedCred
//           : AppStorageKey.encryptedCredDev;
//       AppStorage().delete(currentKey);
//       print('key doesnt exists, deleted saved cred for current environment');
//       final key = Key.fromSecureRandom(32);
//       await keyFile.writeAsBytes(key.bytes);
//       return key;
//     }
//   }

//   Future<void> savePassword(String password, String filename) async {
//     final key = await _getOrCreateKey(filename);
//     final iv = IV.fromLength(16);
//     final encrypter = Encrypter(AES(key!));
//     final encrypted = encrypter.encrypt(password, iv: iv);

//     // Store as "iv:encrypted"
//     final toStore = '${iv.base64}:${encrypted.base64}';

//     await AppStorage().write(
//         AppConfig().isProd
//             ? AppStorageKey.encryptedCred
//             : AppStorageKey.encryptedCredDev,
//         toStore);
//   }

//   Future<String?> getPassword(String filename) async {
//     try {
//       final key = await _getOrCreateKey(filename);
//       if (key == null) {
//         return null;
//       }

//       final storageKey = AppConfig().isProd
//           ? AppStorageKey.encryptedCred
//           : AppStorageKey.encryptedCredDev;

//       final stored = await AppStorage().read(storageKey);
//       if (stored == null || stored.isEmpty) return null;

//       final parts = stored.split(':');
//       if (parts.length != 2) {
//         print(
//             'Invalid stored format, clearing corrupted data for current environment');
//         await AppStorage().delete(storageKey); // Only clear current environment
//         return null;
//       }

//       try {
//         final iv = IV.fromBase64(parts[0]);
//         final encryptedData = Encrypted.fromBase64(parts[1]);

//         final encrypter = Encrypter(AES(key));
//         return encrypter.decrypt(encryptedData, iv: iv);
//       } catch (e) {
//         print(
//             'Decryption failed, clearing corrupted data for current environment: $e');
//         await AppStorage().delete(storageKey); // Only clear current environment
//         return null;
//       }
//     } catch (e) {
//       print('Error in getPassword: $e');
//       return null;
//     }
//   }

//   // ---------- API CALLS ----------

//   Future<AuthResultModel> login(String email, String password,
//       {bool rememberUser = false}) async {
//     String loginUrl = 'user/login';
//     final body = {
//       "email": email.trim(),
//       "password": password.trim(),
//       "role": "parent"
//     };

//     try {
//       Response response =
//           await client.post(loginUrl, body, requiresAuth: false);

//       var decodedBody = utf8.decode(response.bodyBytes);
//       var result = json.decode(decodedBody);
//       var statusCode = result['code'] ?? response.statusCode;

//       if (statusCode == 200) {
//         print('success login: ${result['token']}');
//         await saveTokens(
//           result['token'],
//           result['user']['parent_id'],
//         );
//         if (rememberUser) {
//           await savePassword(password,
//               'user_mykoku_${result['user']['parent_id']}${AppConfig().isProd ? '' : '_dev'}');
//         }
//         return AuthResultModel(
//             message: result['message'], status: AuthResultStatus.success);
//       } else {
//         return AuthResultModel(
//             message:
//                 result['message'] ?? 'Failed to login, please try again later.',
//             status: AuthResultStatus.error);
//       }
//     } catch (e) {
//       print('authrepo login error: $e');
//       if (e.toString().toLowerCase().contains('role invalid')) {
//         return AuthResultModel(
//           message:
//               'This user account exists as another role. Please register as Parent to MYKOKU Parent.',
//           status: AuthResultStatus.error,
//         );
//       }
//       return AuthResultModel(
//         message: e.toString(),
//         status: AuthResultStatus.error,
//       );
//     }
//   }

//   Future<AuthResultModel> logout() async {
//     String logoutUrl = 'user/logout';
//     try {
//       Response response = await client.post(logoutUrl, {});

//       var result = response.statusCode;
//       if (result == 204) {
//         return AuthResultModel(
//             message: 'Successfully logged out.',
//             status: AuthResultStatus.success);
//       } else {
//         return AuthResultModel(
//             message: 'Failed to logout, please try again later.',
//             status: AuthResultStatus.error);
//       }
//     } catch (e) {
//       print('authrepo logout error: $e');
//       return AuthResultModel(
//           message: 'Failed to logout, please try again later.',
//           status: AuthResultStatus.error);
//     }
//   }
// }
