import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_dashboard_page.dart';
import 'capture_anomaly_screen.dart';
import '../services/sync_manager.dart';

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
    const Center(child: Text('Analysis Screen Placeholder')),
    const Center(child: Text('Settings Screen Placeholder')),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-sync when app opens
    SyncManager.syncData();
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () => _onTabTapped(1), // FAB opens Quick Detect (index 1)
        child: Container(
          height: 60,
          width: 60,
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2D5096), Color(0xFF4F85F3)],
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
          child: const Icon(Icons.bar_chart, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
