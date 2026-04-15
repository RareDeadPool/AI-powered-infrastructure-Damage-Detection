import 'package:flutter/material.dart';

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
      height: 80,
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
              style: TextStyle(
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
