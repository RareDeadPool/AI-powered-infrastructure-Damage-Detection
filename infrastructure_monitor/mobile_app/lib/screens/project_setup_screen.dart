import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/constants.dart';
import 'inspection_screen.dart';

class ProjectSetupScreen extends StatefulWidget {
  const ProjectSetupScreen({super.key});

  @override
  State<ProjectSetupScreen> createState() => _ProjectSetupScreenState();
}

class _ProjectSetupScreenState extends State<ProjectSetupScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isFetchingLocation = false;

  void _startInspection() {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all details!'), backgroundColor: AppColors.severityHigh)
      );
      return;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionScreen(
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
            
            ElevatedButton(
              onPressed: _startInspection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: const Text("LAUNCH EDGE SCANNER", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
