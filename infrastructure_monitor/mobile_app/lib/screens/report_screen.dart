import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../utils/constants.dart';
import '../widgets/brand_header.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<File> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/reports');
      
      if (await reportsDir.exists()) {
        final List<FileSystemEntity> entities = reportsDir.listSync();
        _reports = entities
            .whereType<File>()
            .where((file) => file.path.endsWith('.pdf'))
            .toList();
        
        // Sort by date modified (newest first)
        _reports.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      } else {
        _reports = [];
      }
    } catch (e) {
      print('Error loading reports: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Report?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete the PDF file from your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await file.delete();
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const BrandHeader(),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DOCUMENTATION',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFF38020),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inspection Reports',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1D2B40),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty 
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final file = _reports[index];
                          final name = file.path.split(Platform.isWindows ? '\\' : '/').last;
                          final date = file.lastModifiedSync();
                          final size = (file.lengthSync() / 1024).toStringAsFixed(1);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF3FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.picture_as_pdf, color: Color(0xFF558AFA)),
                              ),
                              title: Text(
                                name,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${DateFormat('MMM dd, yyyy • HH:mm').format(date)}  |  $size KB',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (val) {
                                  if (val == 'open') OpenFilex.open(file.path);
                                  if (val == 'delete') _deleteReport(file);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'open', child: Text('Open PDF')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                              onTap: () => OpenFilex.open(file.path),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: Color(0xFFCBD5E0)),
          const SizedBox(height: 16),
          Text(
            'No Reports Generated',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40)),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a report from the Analysis screen\nto see it listed here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: const Color(0xFF7B8EA7)),
          ),
        ],
      ),
    );
  }
}
