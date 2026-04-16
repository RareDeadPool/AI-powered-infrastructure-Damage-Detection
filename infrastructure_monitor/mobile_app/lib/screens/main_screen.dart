import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_dashboard_page.dart';
import 'capture_anomaly_screen.dart'; // Assuming QuickDetectScreen is here or similar
import 'project_setup_screen.dart';
import 'analysis_screen.dart';
import 'settings_page.dart';
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
    const HomeDashboardPage(),     // Index 0
    const QuickDetectScreen(),     // Index 1 (Triggered by 'Create' Tab)
    const ProjectSetupScreen(),    // Index 2 (Triggered by 'Scan' Button)
    const AnalysisScreen(),        // Index 3
    const SettingsPage(),          // Index 4
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
      extendBody: true,
      // IndexedStack keeps the state of all pages and allows 
      // the bottom bar to remain visible.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 📐 THE SLANTED BAR (BACKGROUND)
          CustomPaint(
            size: Size(size.width, barHeight),
            painter: SlantedNotchPainter(),
          ),

          // 🔳 INTERACTIVE TAB ITEMS
          SizedBox(
            height: barHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTabItem(
                  iconActive: Icons.home,
                  iconInactive: Icons.home_outlined,
                  label: 'Home',
                  index: 0,
                ),
                _buildTabItem(
                  iconActive: Icons.add_box,
                  iconInactive: Icons.add_box_outlined,
                  label: 'Create',
                  index: 1, // Now loads QuickDetectScreen
                ),

                // 🔵 SPACING FOR THE CENTER BUTTON
                const SizedBox(width: 80),

                _buildTabItem(
                  iconActive: Icons.analytics,
                  iconInactive: Icons.analytics_outlined,
                  label: 'Analysis',
                  index: 3,
                ),
                _buildTabItem(
                  iconActive: Icons.person,
                  iconInactive: Icons.person_outline_rounded,
                  label: 'Settings',
                  index: 4,
                ),
              ],
            ),
          ),

          // 🔵 SCAN BUTTON (OVERLAPPING PEAK)
          Positioned(
            top: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _onTabTapped(2), // Now loads ProjectSetupScreen
                  child: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Highlight if the "Scan" index (2) is active
                      color: _currentIndex == 2 ? const Color(0xFF2D5096) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D5096).withOpacity(0.35),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: _currentIndex == 2 ? Colors.white : const Color(0xFF2D5096), 
                        width: 4
                      ),
                    ),
                    child: Icon(
                      Icons.document_scanner_rounded,
                      color: _currentIndex == 2 ? Colors.white : const Color(0xFF2D5096),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2D5096),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required IconData iconActive,
    required IconData iconInactive,
    required String label,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;
    const activeColor = Color(0xFF2D5096);
    const inactiveColor = Color(0xFFA0ABBC);
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? iconActive : iconInactive,
                color: color,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
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