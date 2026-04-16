import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project_model.dart';
import '../models/detection_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/sync_manager.dart';
import '../repositories/project_repository.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isUploading = false;

  Future<void> _uploadToCloud() async {
    setState(() => _isUploading = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header with Upload To Cloud button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFFLINE STORAGE',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFF38020),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'My Projects',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1D2B40),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                _isUploading
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D5096).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2D5096),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Uploading...',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2D5096),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _uploadToCloud,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D5096), Color(0xFF4F85F3)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2D5096).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Upload To Cloud',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Project list
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: DatabaseService.projectsBox.listenable(),
              builder: (context, Box<Project> box, _) {
                final userId = AuthService.currentUser?.uid ?? '';
                final projects = ProjectRepository.getProjectsForUser(userId);

                if (projects.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return _ProjectCard(
                      project: projects[index],
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Delete Project?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            content: Text(
                              'This will permanently remove "${projects[index].name}" and all its detections from local storage.',
                              style: GoogleFonts.outfit(color: const Color(0xFF6E7C91)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF7B8EA7))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ProjectRepository.deleteProject(projects[index].id);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
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
            'No Projects Yet',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D2B40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start an inspection to create your\nfirst project. All data is stored offline.',
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

class _ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onDelete,
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
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: _isExpanded
            ? Border.all(color: const Color(0xFF2D5096).withOpacity(0.2), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main card content
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: p.isSynced
                                ? [const Color(0xFFE5FBEE), const Color(0xFFD1FAE5)]
                                : [const Color(0xFFFFF2EA), const Color(0xFFFFE4CE)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.architecture_rounded,
                          color: p.isSynced ? const Color(0xFF22C55E) : const Color(0xFFF38020),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title & info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1D2B40),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 13, color: const Color(0xFF7B8EA7)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    p.location.isNotEmpty ? p.location : 'No location',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF7B8EA7),
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
                      // Sync status + expand arrow
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.isSynced
                                  ? const Color(0xFFE5FBEE)
                                  : const Color(0xFFFFF2EA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  p.isSynced ? Icons.cloud_done : Icons.cloud_off,
                                  size: 14,
                                  color: p.isSynced ? const Color(0xFF22C55E) : const Color(0xFFF38020),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  p.isSynced ? 'Synced' : 'Local',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: p.isSynced ? const Color(0xFF22C55E) : const Color(0xFFF38020),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFCBD5E0), size: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statChip(Icons.calendar_today, p.createdAt.toString().split(' ')[0]),
                      _statChip(Icons.warning_amber_rounded, '${p.detectionCount} anomalies'),
                      if ((p.reportPdfPath != null && p.reportPdfPath!.isNotEmpty) || (p.reportPdfUrl != null && p.reportPdfUrl!.isNotEmpty))
                        _statChip(Icons.picture_as_pdf, 'PDF Ready'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded section
          if (_isExpanded) ...[
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detection list
                  if (detections.isNotEmpty) ...[
                    Text(
                      'DETECTIONS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF38020),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...detections.take(5).map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _severityColor(d.severity).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.warning_rounded,
                              size: 16,
                              color: _severityColor(d.severity),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.damageType.toUpperCase().replaceAll('_', ' '),
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1D2B40),
                                  ),
                                ),
                                Text(
                                  d.severity,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF7B8EA7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(d.confidence * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _severityColor(d.severity),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (detections.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '+ ${detections.length - 5} more detections',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7B8EA7)),
                        ),
                      ),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No detections recorded yet',
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF7B8EA7)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Action buttons
                  Row(
                    children: [
                      // View Report button
                      if ((p.reportPdfPath != null && p.reportPdfPath!.isNotEmpty) || (p.reportPdfUrl != null && p.reportPdfUrl!.isNotEmpty))
                        Expanded(
                          child: _actionButton(
                            icon: Icons.picture_as_pdf_rounded,
                            label: 'View Report',
                            color: const Color(0xFF2D5096),
                            onTap: () async {
                              final pdfPath = p.reportPdfPath;
                              final pdfUrl = p.reportPdfUrl;

                              if (pdfPath != null && pdfPath.isNotEmpty && File(pdfPath).existsSync()) {
                                try {
                                  OpenFilex.open(pdfPath);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Cannot open report: $e')),
                                  );
                                }
                              } else if (pdfUrl != null && pdfUrl.isNotEmpty) {
                                final uri = Uri.parse(pdfUrl);
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error launching browser: $e')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Report file is missing')),
                                );
                              }
                            },
                          ),
                        ),
                      if (p.reportPdfPath != null) const SizedBox(width: 10),
                      // Delete button
                      Expanded(
                        child: _actionButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: const Color(0xFFEF4444),
                          onTap: widget.onDelete,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ],
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
