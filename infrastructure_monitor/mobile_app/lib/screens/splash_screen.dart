import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading AI modules for 3 seconds then navigate to dashboard
    Future.delayed(const Duration(seconds: 3), () {
      // Routes directly to the Dashboard
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Engineering Icon
            const Icon(Icons.engineering, size: 100, color: AppColors.secondary),
            const SizedBox(height: 20),
            
            // App Title defined in constants
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            
            // Subtitle
            Text(
              "AI Damage Detection",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textLight.withOpacity(0.7),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 60),
            
            // Loading Animation
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            )
          ],
        ),
      ),
    );
  }
}
