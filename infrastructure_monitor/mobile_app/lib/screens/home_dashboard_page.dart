import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/sync_manager.dart';
import '../repositories/project_repository.dart';
import '../models/project_model.dart';
import 'project_setup_screen.dart';
import '../widgets/brand_header.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _isOnline = !results.contains(ConnectivityResult.none);
      });
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = !results.contains(ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: BrandHeader()),
          SliverToBoxAdapter(child: VitalityCard(isOnline: _isOnline)),
          const SliverToBoxAdapter(child: SectionTitle(label: 'SPECIALIZED ANALYSIS', title: 'Detection Modules')),
          
          // Hardcoded Module Cards (UI Concept)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ModuleCard(
                  title: 'Pothole Detection',
                  description: 'Computer vision mapping for urban road maintenance.',
                  iconData: Icons.add_road,
                  iconColor: const Color(0xFFF38020),
                  iconBgColor: const Color(0xFFFFF2EA),
                  imagePath: 'assets/pothole_detection.png',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectSetupScreen())),
                ),
                const SizedBox(height: 20),
                ModuleCard(
                  title: 'Pipeline Monitoring',
                  description: 'Real-time pressure and structural integrity tracking.',
                  iconData: Icons.water_drop,
                  iconColor: const Color(0xFF4ED39A),
                  iconBgColor: const Color(0xFFE5FBEE),
                  imagePath: 'assets/pipeline_monitoring.png',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectSetupScreen())),
                ),
                const SizedBox(height: 20),
                ModuleCard(
                  title: 'Crack Analysis',
                  description: 'Precision measurement of concrete and steel fatigue.',
                  iconData: Icons.precision_manufacturing,
                  iconColor: const Color(0xFF558AFA),
                  iconBgColor: const Color(0xFFEFF3FF),
                  imagePath: 'assets/crack_analysis.png',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectSetupScreen())),
                ),
              ]),
            ),
          ),

          const SliverToBoxAdapter(
            child: SectionTitle(
              label: 'OFFLINE SYNC',
              title: 'Recent Inspections',
            ),
          ),

          // REAL HIVE DATA SECTION
          ValueListenableBuilder(
            valueListenable: DatabaseService.projectsBox.listenable(),
            builder: (context, Box<Project> box, _) {
              final projects = ProjectRepository.getProjectsForUser(AuthService.currentUser?.uid ?? '');
              
              if (projects.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text("No offline projects. Start an inspection!", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = projects[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.description_outlined, color: Color(0xFF2D5096)),
                            ),
                            title: Text(project.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(project.location, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${project.detectionCount} items', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF38020))),
                                Text(project.isSynced ? 'Cloud Synced' : 'Offline Mode', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: projects.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String label;
  final String title;

  const SectionTitle({
    super.key,
    required this.label,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: const Color(0xFFF38020), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(color: const Color(0xFF1D2B40), fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class VitalityCard extends StatelessWidget {
  final bool isOnline;
  const VitalityCard({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5096), Color(0xFF4F85F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5096).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE INFRASTRUCTURE HEALTH',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              // Connectivity Bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF4ED39A).withOpacity(0.9) : const Color(0xFF558AFA).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online Mode' : 'Offline Mode',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome Back,',
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 16),
          ),
          Text(
            'System Inspector',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStat('98.2%', 'Accuracy'),
              const SizedBox(width: 24),
              FutureBuilder<int>(
                future: Future.value(ProjectRepository.getProjectsForUser(AuthService.currentUser?.uid ?? '').length),
                builder: (context, snapshot) {
                  return _buildStat(snapshot.data?.toString() ?? '...', 'Projects');
                },
              ),
              const SizedBox(width: 24),
              _buildStat(isOnline ? 'Cloud' : 'Local', 'Target'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
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
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconData,
    required this.iconColor,
    required this.iconBgColor,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.outfit(color: const Color(0xFF1D2B40), fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: GoogleFonts.outfit(color: const Color(0xFF7B8EA7), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(iconData, size: 16, color: iconColor),
                        const SizedBox(width: 6),
                        Text('MODULAR', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40))),
                        const SizedBox(width: 16),
                        const Icon(Icons.bolt, size: 16, color: Color(0xFFF38020)),
                        const SizedBox(width: 6),
                        Text('AI READY', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
