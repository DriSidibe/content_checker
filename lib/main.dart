import 'package:content_checker/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:content_checker/utils/global_variables.dart';
import 'package:content_checker/screen/login.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    //await initializeApp();
    runApp(const ContentCheckerApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to load app data: $e'),
          ),
        ),
      ),
    );
  }
}

Future<void> initializeApp() async {
  globalDatas = await ApiService.getAllData();
}

class ContentCheckerApp extends StatelessWidget {
  const ContentCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Content Checker',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Assign the global key
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const ElegantLoginScreen(),
    );
  }
}
