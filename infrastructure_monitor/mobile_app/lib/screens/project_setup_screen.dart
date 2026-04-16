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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF1D2B40),
        title: Text("PROJECT CONFIGURATION", 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: const Color(0xFF7B8EA7))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "New Inspection",
              style: GoogleFonts.outfit(
                color: const Color(0xFF1D2B40),
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Set up your environment to begin AI-assisted monitoring.",
              style: GoogleFonts.outfit(
                color: const Color(0xFF6E7C91),
                fontSize: 15,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Configuration Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    controller: _titleController,
                    label: "PROJECT TITLE",
                    hint: "e.g., Eastern Bridge Phase II",
                    icon: Icons.edit_note_rounded,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildField(
                    controller: _locationController,
                    label: "SITE LOCATION",
                    hint: "Detecting location...",
                    icon: Icons.map_outlined,
                    suffix: _isFetchingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF38020))),
                          )
                        : IconButton(
                            icon: const Icon(Icons.gps_fixed_rounded, color: Color(0xFFF38020), size: 20),
                            onPressed: _fetchAutoLocation,
                          ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            Text(
              "SELECT MODE", 
              style: GoogleFonts.outfit(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: const Color(0xFFF38020), 
                letterSpacing: 1.2
              )
            ),
            const SizedBox(height: 16),

            _buildActionCard(
              title: "AI Project Inspection",
              subtitle: "Capture multiple site photos. Our AI will automatically tag, track, and generate a comprehensive structural report.",
              icon: Icons.camera_enhance_rounded,
              color: const Color(0xFF2D5096),
              onTap: _startBatchMode,
              tag: "RECOMMENDED",
            ),
            
            const SizedBox(height: 32),
            
            Center(
              child: Text(
                "Version 26.0 Build  •  Advanced Asset Management",
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFCBD5E0), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7B8EA7), letterSpacing: 1)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1D2B40)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFFCBD5E0), fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: const Color(0xFF2D5096), size: 22),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF2D5096), width: 1)),
          ),
        ),
        if (label == "Geographic Location") ...[
          const SizedBox(height: 8),
          Text(
            "Use the technical highlight marker for precision pings.",
            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, String? tag}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                if (tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text("PROCEED TO SCAN", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
