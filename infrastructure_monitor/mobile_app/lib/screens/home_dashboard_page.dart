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

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: HeaderWidget()),
          const SliverToBoxAdapter(child: VitalityCard()),
          const SliverToBoxAdapter(child: SectionTitle(label: 'SPECIALIZED ANALYSIS', title: 'Detection Modules')),
          
          // Hardcoded Module Cards (UI Concept)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const ModuleCard(
                  title: 'Pothole Detection',
                  description: 'Computer vision mapping for urban road maintenance.',
                  iconData: Icons.add_road,
                  iconColor: Color(0xFFF38020),
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

          const SliverToBoxAdapter(child: SectionTitle(label: 'OFFLINE SYNC', title: 'Recent Inspections')),

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
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade100),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.architecture, color: AppColors.primary.withOpacity(0.7)),
                            title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(project.createdAt.toString().split(' ')[0]),
                            trailing: Icon(
                              project.isSynced ? Icons.cloud_done : Icons.cloud_off,
                              color: project.isSynced ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: projects.length > 3 ? 3 : projects.length, // Limit to 3 on home
                  ),
                ),
              );
            },
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
              Image.asset('assets/cityscan_logo.png', height: 32),
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
                      style: TextStyle(color: Color(0xFFF38020)),
                    ),
                    TextSpan(
                      text: 'Scan',
                      style: TextStyle(color: Color(0xFF2D5096)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.sync, color: Color(0xFF7B8EA7)),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting Sync...'), duration: Duration(seconds: 1)),
                  );
                  await SyncManager.syncData();
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF7B8EA7)),
                onPressed: () => AuthService.signOut(),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
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
            'System AI has identified 3 minor anomalies. No immediate intervention required.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4, fontWeight: FontWeight.w300),
          )
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String label;
  final String title;

  const SectionTitle({super.key, required this.label, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFFF38020), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Color(0xFF1D2B40), fontSize: 22, fontWeight: FontWeight.w800)),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 140,
                color: Colors.grey.shade100,
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
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
          colors: [Color(0xFFF38020), Color(0xFF2D5096)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2D5096).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectSetupScreen()));
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Start Project Setup', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
