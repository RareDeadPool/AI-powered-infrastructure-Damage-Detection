import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/detector_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

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
      
      _isLoading = false;
    });
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
    final iouDefault = 0.45;

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Calibration reset to defaults')),
    );
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
                  _buildProfileHeader(displayName, email),
                  
                  const SizedBox(height: 32),

                  // 📱 APP SETTINGS SECTION
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

                  // 🤖 AI CALIBRATION SECTION
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

                  // 🔒 ACCOUNT & LEGAL SECTION
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
                          label: 'About CityScan v1.2.0',
                          onTap: () {},
                          color: const Color(0xFF64748B),
                        ),
                        const Divider(height: 1, indent: 50),
                        _buildActionTile(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out Session',
                          onTap: () => AuthService.signOut(),
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

  Widget _buildProfileHeader(String name, String email) {
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
              backgroundImage: const AssetImage('assets/inspector_avatar.png'),
              backgroundColor: Colors.grey.shade100,
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
              ],
            ),
          ),
          const Icon(Icons.edit_note_rounded, color: Color(0xFFCBD5E0)),
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
