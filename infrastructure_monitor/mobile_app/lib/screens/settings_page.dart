import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'about_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/detector_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, double> _thresholds = {
    'pothole': 0.15,
    'crack': 0.15,
    'pipeline_leak': 0.15,
    'corrosion': 0.15,
  };
  double _iouThreshold = 0.45;
  bool _isLoading = true;
  bool _autoSync = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _thresholds['pothole'] = prefs.getDouble('conf_pothole') ?? 0.15;
      _thresholds['crack'] = prefs.getDouble('conf_crack') ?? 0.15;
      _thresholds['pipeline_leak'] = prefs.getDouble('conf_pipeline_leak') ?? 0.15;
      _thresholds['corrosion'] = prefs.getDouble('conf_corrosion') ?? 0.15;
      _iouThreshold = prefs.getDouble('iou_threshold') ?? 0.45;
      _autoSync = prefs.getBool('auto_sync') ?? true;

      // Update the service static variables
      DetectorService.categoryThresholds = Map.from(_thresholds);
      DetectorService.iouThreshold = _iouThreshold;
    }); // FIX: Added missing closing brace and parenthesis

    final userData = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfidence(String key, double val) async {
    setState(() => _thresholds[key] = val);
    DetectorService.categoryThresholds[key] = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('conf_$key', val);
  }

  Future<void> _saveIou(double val) async {
    setState(() => _iouThreshold = val);
    DetectorService.iouThreshold = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('iou_threshold', val);
  }

  Future<void> _toggleSetting(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
    setState(() {
      if (key == 'auto_sync') _autoSync = val;
    });
  }

  Future<void> _resetToDefaults() async {
    final defaults = {
      'pothole': 0.15,
      'crack': 0.15,
      'pipeline_leak': 0.15,
      'corrosion': 0.15,
    };
    const iouDefault = 0.45;

    final prefs = await SharedPreferences.getInstance();
    for (var entry in defaults.entries) {
      await prefs.setDouble('conf_${entry.key}', entry.value);
    }
    await prefs.setDouble('iou_threshold', iouDefault);

    setState(() {
      _thresholds = defaults;
      _iouThreshold = iouDefault;
      DetectorService.categoryThresholds = Map.from(defaults);
      DetectorService.iouThreshold = iouDefault;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Calibration reset to defaults')),
      );
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Local Cache?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('This will delete all local inspection data. Synced data on the cloud will remain safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.projectsBox.clear();
      await DatabaseService.detectionsBox.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local cache cleared.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final user = AuthService.currentUser;
    final displayName = user?.displayName ?? 'Authorized Inspector';
    final email = user?.email ?? 'No email associated';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40), fontSize: 22)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 PROFILE HEADER
                  _buildProfileHeader(displayName, email, () => _showEditProfileBottomSheet()),
                  
                  const SizedBox(height: 32),

                  _buildSectionHeader('APPLICATION SETTINGS'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.sync_rounded,
                          label: 'Automatic Cloud Sync',
                          value: _autoSync,
                          onChanged: (v) => _toggleSetting('auto_sync', v),
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('AI INFERENCE CALIBRATION'),
                      TextButton(
                        onPressed: _resetToDefaults,
                        child: Text('Reset', style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        _buildCalibrationTile(
                          label: 'Pothole Sensitivity',
                          value: _thresholds['pothole']!,
                          color: const Color(0xFF2D5096),
                          onChanged: (v) => _saveConfidence('pothole', v),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildCalibrationTile(
                          label: 'Crack Sensitivity',
                          value: _thresholds['crack']!,
                          color: const Color(0xFFF38020),
                          onChanged: (v) => _saveConfidence('crack', v),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildCalibrationTile(
                          label: 'Pipeline Leak Sensitivity',
                          value: _thresholds['pipeline_leak']!,
                          color: const Color(0xFF10B981),
                          onChanged: (v) => _saveConfidence('pipeline_leak', v),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildCalibrationTile(
                          label: 'Corrosion Sensitivity',
                          value: _thresholds['corrosion']!,
                          color: const Color(0xFFEF4444),
                          onChanged: (v) => _saveConfidence('corrosion', v),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildCalibrationTile(
                          label: 'IoU Threshold (NMS)',
                          value: _iouThreshold,
                          color: const Color(0xFF64748B),
                          onChanged: _saveIou,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildSectionHeader('ACCOUNT & SECURITY'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.delete_sweep_rounded,
                          label: 'Clear Local Cache',
                          onTap: _clearCache,
                          color: const Color(0xFFEF4444),
                        ),
                        const Divider(height: 1, indent: 50),
                        _buildActionTile(
                          icon: Icons.info_outline_rounded,
                          label: 'About CityScan v26.0',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                          color: const Color(0xFF64748B),
                        ),
                        const Divider(height: 1, indent: 50),
                        _buildActionTile(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out Session',
                          onTap: () async {
                            await AuthService.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileBottomSheet() {
    final user = AuthService.currentUser;
    final currentName = user?.displayName ?? '';
    final currentPhone = _userData?['phone'] ?? '';
    
    final TextEditingController nameController = TextEditingController(text: currentName);
    final TextEditingController phoneController = TextEditingController(text: currentPhone);
    XFile? selectedImage;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 32,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Edit Profile", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40))),
                  const SizedBox(height: 24),
                  // Avatar Picker
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (image != null) {
                        setModalState(() => selectedImage = image);
                      }
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: selectedImage != null 
                              ? FileImage(File(selectedImage!.path)) 
                              : (user?.photoURL != null ? NetworkImage(user!.photoURL!) as ImageProvider : null),
                          child: (selectedImage == null && user?.photoURL == null) 
                              ? const Icon(Icons.person_outline_rounded, size: 50, color: Color(0xFF2D5096))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFF3B82F6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      labelStyle: GoogleFonts.outfit(),
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: GoogleFonts.outfit(),
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5096), 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isSaving ? null : () async {
                        final newName = nameController.text.trim();
                        final newPhone = phoneController.text.trim();
                        if (newName.isNotEmpty) {
                          setModalState(() => isSaving = true);
                          try {
                            String? photoUrl;
                            if (selectedImage != null && user != null) {
                              photoUrl = await FirebaseService.uploadImage('profile_images/${user.uid}', selectedImage!.path);
                            }
                            await AuthService.updateProfile(
                              fullName: newName, 
                              phone: newPhone.isNotEmpty ? newPhone : null,
                              photoUrl: photoUrl,
                            );
                            await _loadSettings(); // Reload local state to update UI
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
                            }
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            setModalState(() => isSaving = false);
                          }
                        }
                      },
                      child: isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Save Changes", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, VoidCallback onEdit) {
    final photoUrl = AuthService.currentUser?.photoURL ?? _userData?['profileImageUrl'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2D5096).withOpacity(0.1), width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? const Icon(Icons.person_outline_rounded, size: 40, color: Color(0xFF2D5096)) : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40)),
                ),
                Text(
                  email,
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF7B8EA7)),
                ),
                if (_userData?['phone'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _userData!['phone'],
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2D5096)),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7B8EA7), letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))
        ],
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1D2B40))),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1D2B40))),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E0)),
    );
  }

  Widget _buildCalibrationTile({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${(value * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.1),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.05,
              max: 0.95,
              divisions: 18,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}