import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/project_model.dart';
import '../models/detection_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/sync_manager.dart';
import '../repositories/project_repository.dart';
import '../widgets/brand_header.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'analysis_map_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _uploadToCloud() async {
    setState(() => _isUploading = true);
    // ... rest of the method (keeping it same)
    // Actually I'll copy the existing body to avoid breaking it
    try {
      final hasNet = await SyncManager.hasInternet();
      if (!hasNet) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Text('No internet connection'),
              ]),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      await SyncManager.syncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.cloud_done, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Text('All data uploaded to cloud!'),
            ]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const BrandHeader(),

            // Redesigned Modern Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  labelColor: const Color(0xFF2D5096),
                  unselectedLabelColor: const Color(0xFF718096),
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'HISTORY'),
                    Tab(text: 'MAP'),
                    Tab(text: 'ANALYTICS'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHistoryTab(),
                  _buildMapTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Modern Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search projects or locations...',
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF718096), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2D5096), size: 18),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16), 
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    }
                  ) 
                : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2D5096), width: 1)),
            ),
          ),
        ),

        // History Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project History',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1D2B40),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2D5096)))
                  : IconButton(
                      icon: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2D5096)),
                      onPressed: _uploadToCloud,
                    ),
            ],
          ),
        ),

        // Filtered Project List
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: DatabaseService.projectsBox.listenable(),
            builder: (context, Box<Project> box, _) {
              final userId = AuthService.currentUser?.uid ?? '';
              final projects = ProjectRepository.getProjectsForUser(userId).where((p) {
                final query = _searchQuery.toLowerCase();
                return p.name.toLowerCase().contains(query) || p.location.toLowerCase().contains(query);
              }).toList();

              if (projects.isEmpty) {
                return _buildEmptyState(_searchQuery.isNotEmpty);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: projects.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _ProjectCard(
                    project: projects[index],
                    onDelete: ()  => _deleteProject(projects[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Project?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently remove "${project.name}" from local storage.',
          style: GoogleFonts.outfit(color: const Color(0xFF6E7C91), fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) await ProjectRepository.deleteProject(project.id);
  }

  Widget _buildMapTab() {
    return const AnalysisMapScreen();
  }
  
  Widget _buildAnalyticsTab() {
    return _AnalyticsView();
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 56,
              color: Color(0xFFCBD5E0),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'No Results Found' : 'No Projects Yet',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D2B40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching 
              ? 'We couldn\'t find any projects matching your search.' 
              : 'Start an inspection to create your\nfirst project. All data is stored offline.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF7B8EA7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DatabaseService.detectionsBox.listenable(),
      builder: (context, Box<Detection> box, _) {
        final detections = ProjectRepository.getAllDetections();
        
        if (detections.isEmpty) {
          return const Center(child: Text('No detection data for analytics yet.'));
        }

        // Aggregate statistics
        Map<String, int> typeCounts = {};
        Map<String, int> severityCounts = {'high': 0, 'medium': 0, 'low': 0};
        
        for (var d in detections) {
          final type = d.damageType.replaceAll('_', ' ').toUpperCase();
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
          
          final sev = d.severity.toLowerCase();
          if (sev.contains('high')) severityCounts['high'] = severityCounts['high']! + 1;
          else if (sev.contains('medium')) severityCounts['medium'] = severityCounts['medium']! + 1;
          else severityCounts['low'] = severityCounts['low']! + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYSTEM INSIGHTS',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFF38020),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Data Analytics',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1D2B40),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // Summary Stats
              Row(
                children: [
                  _statSummaryBox('Total Issues', detections.length.toString(), Icons.warning_amber_rounded, const Color(0xFF2D5096)),
                  const SizedBox(width: 12),
                  _statSummaryBox('Critical', severityCounts['high'].toString(), Icons.emergency_rounded, const Color(0xFFEF4444)),
                ],
              ),
              
              const SizedBox(height: 24),

              // Severity Distribution Pie Chart
              _cardWrapper(
                title: 'Severity Distribution',
                child: SizedBox(
                   height: 220,
                   child: PieChart(
                     PieChartData(
                       sectionsSpace: 4,
                       centerSpaceRadius: 40,
                       sections: [
                         PieChartSectionData(
                           value: severityCounts['high']!.toDouble(),
                           title: 'High',
                           color: const Color(0xFFEF4444),
                           radius: 50,
                           titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                         ),
                         PieChartSectionData(
                           value: severityCounts['medium']!.toDouble(),
                           title: 'Med',
                           color: const Color(0xFFF59E0B),
                           radius: 45,
                           titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                         ),
                         PieChartSectionData(
                           value: severityCounts['low']!.toDouble(),
                           title: 'Low',
                           color: const Color(0xFF22C55E),
                           radius: 40,
                           titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                         ),
                       ],
                     ),
                   ),
                ),
              ),

              const SizedBox(height: 24),

              // Damage Types Bar Chart
              _cardWrapper(
                title: 'Damage Types Breakdown',
                child: SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < typeCounts.keys.length) {
                                final label = typeCounts.keys.elementAt(value.toInt());
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    label.substring(0, 3), 
                                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF6E7C91), fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: typeCounts.entries.map((e) {
                        int idx = typeCounts.keys.toList().indexOf(e.key);
                        return BarChartGroupData(
                          x: idx,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: const Color(0xFF2D5096),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _statSummaryBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40))),
            Text(title, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7B8EA7))),
          ],
        ),
      ),
    );
  }

  Widget _cardWrapper({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40))),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _DamageMap extends StatefulWidget {
  @override
  State<_DamageMap> createState() => _DamageMapState();
}

class _DamageMapState extends State<_DamageMap> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  List<Detection> _filteredDetections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    final allDetections = ProjectRepository.getAllDetections();
    
    // Filter for potholes and bridge defects (bridge_crack, etc)
    _filteredDetections = allDetections.where((d) {
      final type = d.damageType.toLowerCase();
      return type.contains('pothole') || type.contains('bridge');
    }).toList();

    _markers.clear();
    for (var d in _filteredDetections) {
      if (d.latitude != null && d.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(d.id),
            position: LatLng(d.latitude!, d.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerHue(d.damageType)
            ),
            infoWindow: InfoWindow(
              title: d.damageType.toUpperCase().replaceAll('_', ' '),
              snippet: 'Severity: ${d.severity} | Conf: ${(d.confidence*100).toStringAsFixed(0)}%',
              onTap: () => _showDetectionDetails(d),
            ),
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  double _getMarkerHue(String type) {
    if (type.toLowerCase().contains('pothole')) return BitmapDescriptor.hueOrange;
    if (type.toLowerCase().contains('bridge')) return BitmapDescriptor.hueAzure;
    return BitmapDescriptor.hueRed;
  }

  void _showDetectionDetails(Detection d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.damageType.toUpperCase().replaceAll('_', ' '),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1D2B40),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Found on ${d.timestamp.toString().split(' ')[0]}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF7B8EA7),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _severityColor(d.severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    d.severity.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _severityColor(d.severity),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _infoCard(Icons.gps_fixed, 'Coordinates', '${d.latitude?.toStringAsFixed(4)}, ${d.longitude?.toStringAsFixed(4)}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(Icons.analytics_outlined, 'Confidence', '${(d.confidence*100).toStringAsFixed(0)}%'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (d.imagePath.isNotEmpty && File(d.imagePath).existsSync()) 
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(d.imagePath),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else if (d.imageUrl != null && d.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  d.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2D5096)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7B8EA7))),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40))),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('high') || s.contains('critical')) return const Color(0xFFEF4444);
    if (s.contains('medium') || s.contains('moderate')) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_markers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 64, color: Color(0xFFCBD5E0)),
            const SizedBox(height: 16),
            Text(
              'No Anomalies Found On Map',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40)),
            ),
            const SizedBox(height: 8),
            Text(
              'Potholes and bridge defects will appear here\nonce they are detected with GPS enabled.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF7B8EA7)),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _markers.first.position,
        zoom: 12,
      ),
      onMapCreated: (curr) => _controller = curr,
      markers: _markers,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      padding: const EdgeInsets.only(bottom: 20, right: 10),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onDelete;
  final VoidCallback onResume;

  const _ProjectCard({
    required this.project,
    required this.onDelete,
    required this.onResume,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final detections = ProjectRepository.getDetectionsForProject(p.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5096).withOpacity(_isExpanded ? 0.08 : 0.04),
            blurRadius: _isExpanded ? 24 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Main card content
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Discovery Icon Container
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: p.isSynced
                                  ? [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF10B981).withOpacity(0.05)]
                                  : [const Color(0xFF3B82F6).withOpacity(0.1), const Color(0xFF3B82F6).withOpacity(0.05)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            p.isSynced ? Icons.check_circle_rounded : Icons.sensors_rounded,
                            color: p.isSynced ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title & info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1D2B40),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF7B8EA7)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      p.location.isNotEmpty ? p.location : 'Survey Area Alpha',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFF7B8EA7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Sync status badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: p.isSynced ? const Color(0xFFE5FBEE) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                p.isSynced ? 'SYNCED' : 'LOCAL',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: p.isSynced ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFCBD5E0), size: 24),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Glassy Stat Chips
                    Row(
                      children: [
                        _statChip(Icons.calendar_today_outlined, p.createdAt.toString().split(' ')[0]),
                        const SizedBox(width: 8),
                        _statChip(Icons.analytics_outlined, '${p.detectionCount} Anomalies'),
                        const Spacer(),
                        if ((p.reportPdfPath != null && p.reportPdfPath!.isNotEmpty) || (p.reportPdfUrl != null && p.reportPdfUrl!.isNotEmpty))
                           const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF64748B), size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expanded section
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 18),
                    // Detection list
                    if (detections.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AI ANALYSIS SUMMARY',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'TOP 5 ISSUES',
                            style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...detections.take(5).map((d) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _severityColor(d.severity).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: _severityColor(d.severity),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.damageType.toUpperCase().replaceAll('_', ' '),
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                  Text(
                                    'Confidence Rating: ${(d.confidence * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _severityColor(d.severity).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d.severity.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: _severityColor(d.severity),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (detections.length > 5)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '+ ${detections.length - 5} additional anomalies recorded',
                              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Area structure appears stable',
                                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Action buttons
                    Row(
                      children: [
                        // View Report button
                        if ((p.reportPdfPath != null && p.reportPdfPath!.isNotEmpty) || (p.reportPdfUrl != null && p.reportPdfUrl!.isNotEmpty))
                          Expanded(
                            child: _actionButton(
                              icon: Icons.description_rounded,
                              label: 'View Project Report',
                              color: const Color(0xFF2D5096),
                              onTap: () async {
                                final pdfPath = p.reportPdfPath;
                                final pdfUrl = p.reportPdfUrl;

                                if (pdfPath != null && pdfPath.isNotEmpty && File(pdfPath).existsSync()) {
                                  try {
                                    OpenFilex.open(pdfPath);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open report: $e')));
                                  }
                                } else if (pdfUrl != null && pdfUrl.isNotEmpty) {
                                  final uri = Uri.parse(pdfUrl);
                                  try {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report file missing')));
                                }
                              },
                            ),
                          ),
                        if ((p.reportPdfPath != null && p.reportPdfPath!.isNotEmpty) || (p.reportPdfUrl != null && p.reportPdfUrl!.isNotEmpty))
                          const SizedBox(width: 12),
                        // Delete button
                        Expanded(
                          child: _actionButton(
                            icon: Icons.delete_sweep_rounded,
                            label: 'Purge Project',
                            color: const Color(0xFFEF4444),
                            onTap: widget.onDelete,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF7B8EA7)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF7B8EA7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('high') || s.contains('critical')) return const Color(0xFFEF4444);
    if (s.contains('medium') || s.contains('moderate')) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }
}
