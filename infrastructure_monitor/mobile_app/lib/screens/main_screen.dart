import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_dashboard_page.dart';
import 'capture_anomaly_screen.dart';
import 'project_setup_screen.dart';
import 'analysis_screen.dart';
import 'settings_page.dart';
import '../services/sync_manager.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboardPage(),
    const QuickDetectScreen(),
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
    return Scaffold(
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProjectSetupScreen()),
          );
        },
        child: Container(
          height: 60,
          width: 60,
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2D5096), Color(0xFFF38020)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFFAFBFC), width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D5096).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 28),
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
      color: Colors.white.withOpacity(0.95),
      elevation: 20,
      shadowColor: Colors.black12,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabItem(icon: Icons.home_rounded, label: 'HOME', index: 0),
            _buildTabItem(icon: Icons.add_circle_outline, label: 'CREATE', index: 1),
            const SizedBox(width: 50), // Spacer for FAB
            _buildTabItem(icon: Icons.auto_graph, label: 'ANALYSIS', index: 2),
            _buildTabItem(icon: Icons.settings_outlined, label: 'SETTINGS', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    final bool isActive = currentIndex == index;
    final color = isActive ? const Color(0xFF3B82F6) : const Color(0xFFA0ABBC);
    return InkWell(
      onTap: () => onTabTapped(index),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFEEF4FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
