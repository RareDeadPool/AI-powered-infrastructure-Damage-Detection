import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';
import '../services/auth_service.dart';
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
        const SnackBar(content: Text('Please enter all details!'), backgroundColor: AppColors.severityHigh)
      );
      return;
    }

    setState(() => _isFetchingLocation = true); // Using this as simple loading state

    try {
      final String projectId = const Uuid().v4();
      final String? userId = AuthService.currentUser?.uid;

      if (userId == null) throw Exception("User not authenticated");

      // SAVE TO HIVE
      final newProject = Project(
        id: projectId,
        name: title,
        createdAt: DateTime.now(),
        userId: userId,
        isSynced: false,
      );
      
      await ProjectRepository.saveProject(newProject);

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving project: $e"), backgroundColor: AppColors.severityHigh)
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _startBatchMode() {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all details!'), backgroundColor: AppColors.severityHigh)
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoBatchScreen(
          projectTitle: _titleController.text,
          location: _locationController.text,
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

      // Fetch precise hardware GPS coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // Translate coordinates into a physical street name
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Example Output: "Subhash Road, Mumbai, 400030"
        String address = "${place.street ?? ''}, ${place.locality ?? place.subLocality ?? ''}".trim();
        if (address.endsWith(',')) address = address.substring(0, address.length - 1); // Cleanup trailing comma
        
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.severityMedium)
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
      appBar: AppBar(title: const Text("New Inspection")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.architecture, size: 80, color: AppColors.primary),
            const SizedBox(height: 30),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Project Title",
                hintText: "e.g., Highway Section B Review",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.engineering),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: "Geographic Location",
                hintText: "e.g., Subhash Road",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.map),
                // Adds our Auto GPS button physically inside the text box!
                suffixIcon: _isFetchingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location, color: AppColors.primary),
                        onPressed: _fetchAutoLocation,
                        tooltip: "Get Current GPS Location",
                      ),
              ),
            ),
            const Spacer(),

            // ── Mode 1: Live Edge Scanner ────────────────────────────────
            ElevatedButton.icon(
              onPressed: _startInspection,
              icon: const Icon(Icons.videocam, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              label: const Column(
                children: [
                  Text("LAUNCH LIVE SCANNER",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Real-time camera detection",
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Mode 2: Photo Batch Report ───────────────────────────────
            ElevatedButton.icon(
              onPressed: _startBatchMode,
              icon: const Icon(Icons.photo_library, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              label: const Column(
                children: [
                  Text("PHOTO BATCH REPORT",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Analyse multiple saved photos",
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
