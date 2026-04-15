import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const CityScanApp());
}

class CityScanApp extends StatelessWidget {
  const CityScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CityScan Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const MainScreenWrapper(),
    );
  }
}

class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const QuickDetectScreen(),
    const Center(child: Text('Analysis Screen Placeholder')),
    const Center(child: Text('Settings Screen Placeholder')),
  ];

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
              colors: [Color(0xFF2B57A1), Color(0xFF4F85F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFFAFBFC), width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B57A1).withOpacity(0.4),
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: HeaderWidget()),
          const SliverToBoxAdapter(child: VitalityCard()),
          const SliverToBoxAdapter(child: SectionTitle()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const ModuleCard(
                  title: 'Pothole Detection',
                  description: 'Computer vision mapping for urban road maintenance.',
                  iconData: Icons.add_road,
                  iconColor: Color(0xFFF37B31),
                  iconBgColor: Color(0xFFFFF2EA),
                  imagePath: 'assets/pothole_detection.png',
                ),
                const SizedBox(height: 20),
                const ModuleCard(
                  title: 'Pipeline Monitoring',
                  description: 'Real-time pressure and structural integrity tracking.',
                  iconData: Icons.water_drop,
                  iconColor: Color(0xFF4ED39A),
                  iconBgColor: Color(0xFFE5FBEE),
                  imagePath: 'assets/pipeline_monitoring.png',
                ),
                const SizedBox(height: 20),
                const ModuleCard(
                  title: 'Crack Analysis',
                  description: 'Precision measurement of concrete and steel fatigue.',
                  iconData: Icons.precision_manufacturing,
                  iconColor: Color(0xFF558AFA),
                  iconBgColor: Color(0xFFEFF3FF),
                  imagePath: 'assets/crack_analysis.png',
                ),
              ]),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverToBoxAdapter(child: StartInspectionButton()),
          ),
        ],
      ),
    );
  }
}

class QuickDetectScreen extends StatelessWidget {
  const QuickDetectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUICK DETECT',
              style: TextStyle(color: Color(0xFFF37B31), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'Capture Anomaly',
              style: TextStyle(color: Color(0xFF1D2B40), fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.black,
                  image: const DecorationImage(
                    image: AssetImage('assets/pothole_detection.png'),
                    fit: BoxFit.cover,
                    opacity: 0.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flash_off, color: Colors.white),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'ALIGN CAMERA WITH DAMAGE',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Module',
              style: TextStyle(color: Color(0xFF1D2B40), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  ModuleChip(label: 'Pothole', icon: Icons.add_road, isActive: true),
                  SizedBox(width: 12),
                  ModuleChip(label: 'Pipeline', icon: Icons.water_drop),
                  SizedBox(width: 12),
                  ModuleChip(label: 'Crack', icon: Icons.precision_manufacturing),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFFF37B31), Color(0xFF2B57A1)]),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2B57A1).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: const Center(
                child: Text(
                  'Start AI Analysis',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
    );
  }
}

class ModuleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;

  const ModuleChip({
    super.key,
    required this.label,
    required this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEEF4FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? const Color(0xFF3B82F6) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF7B8EA7), size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF1D2B40),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city, color: Color(0xFF2B57A1)),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  children: const [
                    TextSpan(
                      text: 'City',
                      style: TextStyle(color: Color(0xFFF37B31)),
                    ),
                    TextSpan(
                      text: 'Scan',
                      style: TextStyle(color: Color(0xFF2B57A1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.dashboard_customize_outlined, color: Color(0xFF7B8EA7)),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class VitalityCard extends StatelessWidget {
  const VitalityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2B57A1), Color(0xFFF37B31)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B57A1).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'LIVE INFRASTRUCTURE HEALTH',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '98.4',
                style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800, height: 1),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '%',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Global Vitality\nIndex',
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.2, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'System AI has identified 3 minor anomalies across the northeast pipeline sector. No immediate intervention required.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5, fontWeight: FontWeight.w300),
          )
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('SPECIALIZED ANALYSIS', style: TextStyle(color: Color(0xFFF37B31), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              SizedBox(height: 4),
              Text('Detection Modules', style: TextStyle(color: Color(0xFF1D2B40), fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const Text('View All', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData iconData;
  final Color iconColor;
  final Color iconBgColor;
  final String imagePath;

  const ModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Color(0xFF1D2B40), fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Color(0xFF6E7C91), fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Launch Module', style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: iconColor, size: 16),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class StartInspectionButton extends StatelessWidget {
  const StartInspectionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFF37B31), Color(0xFF2B57A1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B57A1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Start Inspection',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
