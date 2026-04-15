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
<<<<<<< HEAD
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: HeaderWidget()),
            const SliverToBoxAdapter(child: VitalityCard()),
            
            const SliverToBoxAdapter(
              child: SectionTitle(
                label: 'SPECIALIZED ANALYSIS',
                title: 'Detection Modules',
              ),
            ),
            
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
                    title: 'Bridge Integrity',
                    description: 'Precision measurement of concrete and steel fatigue.',
                    iconData: Icons.precision_manufacturing,
                    iconColor: Color(0xFF558AFA),
                    iconBgColor: Color(0xFFEFF3FF),
                    imagePath: 'assets/crack_analysis.png',
                  ),
                ]),
              ),
=======
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
>>>>>>> 4fc285463d412009cdbf061c2d4c943fa7fe500a
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
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4F8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.architecture, color: const Color(0xFF2D5096)),
                              ),
                              title: Text(project.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text(project.createdAt.toString().split(' ')[0], style: GoogleFonts.outfit(fontSize: 12)),
                              trailing: Icon(
                                project.isSynced ? Icons.cloud_done : Icons.cloud_off,
                                color: project.isSynced ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: projects.length > 5 ? 5 : projects.length, // Limit to 5 on home
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
<<<<<<< HEAD
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFF38020), Color(0xFFFBA864)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.offline_bolt_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
=======
              Image.asset('assets/cityscan_logo.png', height: 32),
              const SizedBox(width: 8),
>>>>>>> 4fc285463d412009cdbf061c2d4c943fa7fe500a
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  children: const [
                    TextSpan(text: 'City', style: TextStyle(color: Color(0xFFF38020))),
                    TextSpan(text: 'Scan', style: TextStyle(color: Color(0xFF2D5096))),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIcon(
                icon: Icons.sync_rounded, 
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing Data...'), behavior: SnackBarBehavior.floating),
                  );
                  await SyncManager.syncData();
                }
              ),
              const SizedBox(width: 10),
              _buildHeaderIcon(
                icon: Icons.logout_rounded, 
                onTap: () => AuthService.signOut()
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEEF2F6),
                child: const Icon(Icons.person_rounded, color: Color(0xFF7B8EA7), size: 22),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDF2F7)),
        ),
        child: Icon(icon, color: const Color(0xFF7B8EA7), size: 20),
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
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '98.4',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text('%', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              const Expanded(
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
          const SizedBox(height: 16),
          Text(
            'System AI has identified 3 minor anomalies recently. Data is fully synced and stored locally.',
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4, fontWeight: FontWeight.w300),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: const Color(0xFFF38020), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(title, style: GoogleFonts.outfit(color: const Color(0xFF1D2B40), fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          Text('View All', style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.outfit(color: const Color(0xFF1D2B40), fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: const Color(0xFF6E7C91), fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E0), size: 16),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 160,
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
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5096), Color(0xFF4F85F3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2D5096).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectSetupScreen()));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'NEW INSPECTION PROJECT',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
