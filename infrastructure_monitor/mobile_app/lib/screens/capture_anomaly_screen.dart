import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUICK DETECT',
              style: GoogleFonts.outfit(color: const Color(0xFFF38020), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Capture Anomaly',
              style: GoogleFonts.outfit(color: const Color(0xFF1D2B40), fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.black,
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1542013936693-884638332954?q=80&w=600&auto=format&fit=crop'),
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
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'ALIGN CAMERA WITH DAMAGE',
                          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              'Select AI Mode',
              style: GoogleFonts.outfit(color: const Color(0xFF1D2B40), fontSize: 16, fontWeight: FontWeight.bold),
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
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    label: 'From Gallery',
                    icon: Icons.photo_library_rounded,
                    color: const Color(0xFFF38020),
                    onTap: () => _handleCapture(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100), // Space for bottom bar
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
      height: 64,
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
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEEF4FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? const Color(0xFF3B82F6) : const Color(0xFFEDF2F7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF7B8EA7), size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF1D2B40),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
