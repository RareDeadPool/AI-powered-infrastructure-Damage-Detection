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
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

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
    _currentIndex = widget.initialIndex;
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
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomTabBar(
        currentIndex: _currentIndex,
        onTabTapped: _onTabTapped,
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildTabItem(icon: Icons.home_rounded, label: 'HOME', index: 0)),
              Expanded(child: _buildTabItem(icon: Icons.description_outlined, label: 'REPORT', index: 2)),
              _buildMiddleButton(),
              Expanded(child: _buildTabItem(icon: Icons.auto_graph_rounded, label: 'ANALYSIS', index: 3)),
              Expanded(child: _buildTabItem(icon: Icons.settings_rounded, label: 'SETTINGS', index: 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleButton() {
    const int index = 1;
    final bool isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTabTapped(index),
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2D5096), Color(0xFF4F85F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D5096).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    final bool isActive = currentIndex == index;
    
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: isActive ? Colors.white : const Color(0xFF94A3B8)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.outfit(
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );

    return InkWell(
      onTap: () => onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: isActive
            ? ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF2D5096), Color(0xFF4F85F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: content,
              )
            : content,
      ),
    );
  }
}
