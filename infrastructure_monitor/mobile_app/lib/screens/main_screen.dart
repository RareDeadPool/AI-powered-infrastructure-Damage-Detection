import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_dashboard_page.dart';
import 'capture_anomaly_screen.dart'; // Assuming QuickDetectScreen is here or similar
import 'project_setup_screen.dart';
import 'analysis_screen.dart';
import 'settings_page.dart';
import 'report_screen.dart';
import '../services/sync_manager.dart';
import '../services/auth_service.dart';

// Note: Ensure QuickDetectScreen is imported correctly. 
// Based on your snippet, I am using QuickDetectScreen as requested.

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Swapped indices as per request: 
  // Index 1 (Create Tab) -> QuickDetectScreen
  // Index 2 (Scan Button) -> ProjectSetupScreen
  final List<Widget> _pages = [
    const HomeDashboardPage(),
    const QuickDetectScreen(), // This is the "Scan" function
    const ReportScreen(),
    const AnalysisScreen(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    final userId = AuthService.currentUser?.uid;
    if (userId != null) {
      SyncManager.pullData(userId).then((_) {
        SyncManager.syncData();
      });
    } else {
      SyncManager.syncData();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    const double barHeight = 100.0;

    return Scaffold(
      extendBody: true, // Allows the FAB notch to look better
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomTabBar(
        currentIndex: _currentIndex,
        onTabTapped: _onTabTapped,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () => _onTabTapped(1), // Index 1 is Scan
        child: Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2D5096), Color(0xFF4ED39A)], // Blue to Green gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D5096).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
              const SizedBox(height: 2),
              Text(
                'SCAN',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomBottomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const CustomBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 30,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left pair
            Row(
              children: [
                _buildTabItem(icon: Icons.home_rounded, label: 'HOME', index: 0),
                const SizedBox(width: 20),
                _buildTabItem(icon: Icons.description_outlined, label: 'REPORT', index: 2),
              ],
            ),
            // Right pair
            Row(
              children: [
                _buildTabItem(icon: Icons.auto_graph_rounded, label: 'ANALYSIS', index: 3),
                const SizedBox(width: 20),
                _buildTabItem(icon: Icons.settings_rounded, label: 'SETTINGS', index: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    final bool isActive = currentIndex == index;
    final color = isActive ? const Color(0xFF2D5096) : const Color(0xFF94A3B8);
    
    return InkWell(
      onTap: () => onTabTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 4,
                width: 4,
                decoration: const BoxDecoration(color: Color(0xFF2D5096), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class SlantedNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path();
    double h = size.height;
    double w = size.width;
    double peakY = 15.0; 
    double sideY = 40.0; 

    path.moveTo(0, sideY);
    path.lineTo(w * 0.4, peakY);
    path.quadraticBezierTo(w * 0.5, 5, w * 0.6, peakY);
    path.lineTo(w, sideY);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawShadow(path.shift(const Offset(0, -3)), Colors.black.withOpacity(0.05), 10, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}