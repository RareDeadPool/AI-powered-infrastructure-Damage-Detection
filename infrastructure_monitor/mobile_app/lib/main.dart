import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print("DEBUG: Starting Firebase Initialization...");
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("DEBUG: Firebase Initialized Successfully.");
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        print("DEBUG: Firebase already initialized (duplicate-app), skipping...");
      } else {
        rethrow;
      }
    }

    print("DEBUG: Starting Hive Initialization...");
    // Initialize Local Database (Hive)
    await DatabaseService.init();
    print("DEBUG: Hive Initialized Successfully.");

    runApp(const InfraMonitorApp());
  } catch (e, stack) {
    print("FATAL ERROR DURING BOOT: $e");
    print(stack);
    // Continue anyway to see if basic UI can render, or handle as needed
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Startup Error: $e\n\nPlease check Firebase Console.")),
      ),
    ));
  }
}

class InfraMonitorApp extends StatelessWidget {
  const InfraMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          // While checking auth state, show a splash or loader
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          // If user is authenticated, go to Main Screen, else go to Login
          if (snapshot.hasData) {
            return const MainScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
