import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'inspection_screen.dart';
import '../utils/constants.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';
import '../services/auth_service.dart';
import 'project_setup_screen.dart';

class QuickDetectScreen extends StatefulWidget {
  const QuickDetectScreen({super.key});

  @override
  State<QuickDetectScreen> createState() => _QuickDetectScreenState();
}

class _QuickDetectScreenState extends State<QuickDetectScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _startLiveCapture() async {
    final userId = AuthService.currentUser?.uid ?? '';
    final projectId = 'quick_scan_${DateTime.now().millisecondsSinceEpoch}';

    final project = Project(
      id: projectId,
      name: 'Live Anomaly Capture',
      createdAt: DateTime.now(),
      userId: userId,
      location: 'Manual Geo-Tag',
    );
    await ProjectRepository.saveProject(project);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionScreen(
          projectId: projectId,
          projectTitle: 'Live Anomaly Capture',
          location: 'Manual Geo-Tag',
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final userId = AuthService.currentUser?.uid ?? '';
        final projectId = 'quick_scan_${DateTime.now().millisecondsSinceEpoch}';

        final project = Project(
          id: projectId,
          name: 'Gallery Scan Analysis',
          createdAt: DateTime.now(),
          userId: userId,
          location: 'Manual Geo-Tag',
        );
        await ProjectRepository.saveProject(project);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionScreen(
              projectId: projectId,
              projectTitle: 'Gallery Scan Analysis',
              location: 'Manual Geo-Tag',
              initialImage: File(image.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.severityHigh)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'QUICK DETECT',
                style: GoogleFonts.outfit(color: const Color(0xFFF38020), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture Anomaly',
                style: GoogleFonts.outfit(color: const Color(0xFF1D2B40), fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Text(
                'Instantly scan environments for infrastructure damage or upload existing footage for rapid AI evaluation.',
                style: GoogleFonts.outfit(color: const Color(0xFF6E7C91), fontSize: 16, height: 1.4),
              ),
              
              const SizedBox(height: 60),
              
              _buildActionButton(
                label: 'Project Scan',
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFF2D5096),
                onTap: _startLiveCapture,
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                label: 'Batch Mode',
                icon: Icons.collections_rounded,
                color: const Color(0xFF1D2B40), // Darker color for professional batch mode
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectSetupScreen())),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                label: 'From Gallery',
                icon: Icons.photo_library_rounded,
                color: const Color(0xFFF38020),
                onTap: _pickFromGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 70,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
