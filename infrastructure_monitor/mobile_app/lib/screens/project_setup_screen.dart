import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';
import 'inspection_screen.dart';
import 'photo_batch_screen.dart';

class ProjectSetupScreen extends StatefulWidget {
  const ProjectSetupScreen({super.key});

  @override
  State<ProjectSetupScreen> createState() => _ProjectSetupScreenState();
}

class _ProjectSetupScreenState extends State<ProjectSetupScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isFetchingLocation = false;

  Future<void> _startInspection() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all details!'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.severityHigh)
      );
      return;
    }

    final String projectId = const Uuid().v4();

    // Save project to Hive
    final project = Project(
      id: projectId,
      name: title,
      location: location,
      createdAt: DateTime.now(),
      userId: AuthService.currentUser?.uid ?? '',
    );
    await ProjectRepository.saveProject(project);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionScreen(
          projectId: projectId,
          projectTitle: title,
          location: location,
        ),
      ),
    );
  }

  Future<void> _startBatchMode() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all details!'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.severityHigh)
      );
      return;
    }

    final String projectId = const Uuid().v4();

    // Save project to Hive
    final project = Project(
      id: projectId,
      name: title,
      location: location,
      createdAt: DateTime.now(),
      userId: AuthService.currentUser?.uid ?? '',
    );
    await ProjectRepository.saveProject(project);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoBatchScreen(
          projectId: projectId,
          projectTitle: title,
          location: location,
        ),
      ),
    );
  }

  Future<void> _fetchAutoLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled on your phone.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street ?? ''}, ${place.locality ?? place.subLocality ?? ''}".trim();
        if (address.startsWith(',')) address = address.substring(1).trim();
        if (address.endsWith(',')) address = address.substring(0, address.length - 1);
        
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.severityMedium)
      );
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1D2B40),
        title: Text("Project Setup", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.architecture_rounded, size: 64, color: Color(0xFF2D5096)),
                  const SizedBox(height: 16),
                  Text(
                    "Define your inspection goals. Named projects help organize AI detection history and PDF reports.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: const Color(0xFF6E7C91), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text("General Information", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40), letterSpacing: 0.5)),
            const SizedBox(height: 16),

            _buildField(
              controller: _titleController,
              label: "Project Title",
              hint: "e.g., Highway Section B Review",
              icon: Icons.engineering_rounded,
            ),
            const SizedBox(height: 20),
            
            _buildField(
              controller: _locationController,
              label: "Geographic Location",
              hint: "e.g., Subhash Road, Mumbai",
              icon: Icons.location_on_rounded,
              suffix: _isFetchingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF38020))),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location_rounded, color: Color(0xFFF38020)),
                      onPressed: _fetchAutoLocation,
                    ),
            ),
            
            const SizedBox(height: 40),
            
            Text("Select Inspection Type", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40), letterSpacing: 0.5)),
            const SizedBox(height: 16),

            _buildModeCard(
              title: "Project-Based Batch Inspection",
              subtitle: "Live scanning where damages are added into a single report one by one.",
              icon: Icons.collections_rounded,
              color: const Color(0xFF2D5096),
              onTap: _startBatchMode,
              isPremium: true,
            ),
            
            const SizedBox(height: 16),

            _buildModeCard(
              title: "Rapid Edge Scanner",
              subtitle: "Real-time AI detection in a single high-speed session.",
              icon: Icons.videocam_rounded,
              color: const Color(0xFFF38020),
              onTap: _startInspection,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7B8EA7))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFFCBD5E0), fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: const Color(0xFF2D5096), size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2D5096))),
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, bool isPremium = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPremium ? Border.all(color: color.withOpacity(0.3), width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                       if (isPremium) ...[
                         const SizedBox(width: 8),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                           child: const Text("BATCH", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                         )
                       ]
                     ],
                   ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.outfit(color: const Color(0xFF7B8EA7), fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E0), size: 16),
          ],
        ),
      ),
    );
  }
}
