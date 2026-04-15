import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'inspection_screen.dart';
import '../utils/constants.dart';

class QuickDetectScreen extends StatefulWidget {
  const QuickDetectScreen({super.key});

  @override
  State<QuickDetectScreen> createState() => _QuickDetectScreenState();
}

class _QuickDetectScreenState extends State<QuickDetectScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _handleCapture(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        if (!mounted) return;
        
        // Navigate to InspectionScreen with a temporary Quick Scan context
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionScreen(
              projectId: 'quick_scan_${DateTime.now().millisecondsSinceEpoch}',
              projectTitle: 'Quick Anomaly Capture',
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUICK DETECT',
              style: TextStyle(color: Color(0xFFF38020), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'Capture Anomaly',
              style: TextStyle(color: Color(0xFF1D2B40), fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            
            // Large Action Header
            Center(
              child: Column(
                children: [
                  Icon(Icons.camera_enhance_outlined, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Select a capture method to begin AI analysis.",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            
            // NEW BUTTONS: Live Capture and Upload from Gallery
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Live Capture',
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFF2D5096),
                    onTap: () => _handleCapture(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Gallery',
                    icon: Icons.photo_library_rounded,
                    color: const Color(0xFFF38020),
                    onTap: () => _handleCapture(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 120), // Space for bottom bar
          ],
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
      height: 60,
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
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
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
