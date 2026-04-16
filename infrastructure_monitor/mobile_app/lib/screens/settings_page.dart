import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/detector_service.dart';
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
      const SnackBar(content: Text('Settings reset to defaults')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
              tooltip: 'Reset to Defaults',
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PER-CATEGORY CALIBRATION',
                  style: GoogleFonts.outfit(
                      color: const Color(0xFFF38020), 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fine-tune Sensitivity',
                  style: GoogleFonts.outfit(
                      color: const Color(0xFF1D2B40), 
                      fontSize: 28, 
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  'Independently adjust how sensitive the AI should be for each type of infrastructure damage.',
                  style: GoogleFonts.outfit(color: const Color(0xFF6E7C91), fontSize: 14, height: 1.4),
                ),
                
                const SizedBox(height: 32),

                _buildCategoryHeader('🕳️ Potholes'),
                _buildSlider(
                  value: _thresholds['pothole']!,
                  onChanged: (val) => _saveConfidence('pothole', val),
                  color: const Color(0xFF2D5096)
                ),

                const SizedBox(height: 24),

                _buildCategoryHeader('⚡ Cracks (Road & Bridge)'),
                _buildSlider(
                  value: _thresholds['crack']!,
                  onChanged: (val) => _saveConfidence('crack', val),
                  color: const Color(0xFFF38020)
                ),

                const SizedBox(height: 24),

                _buildCategoryHeader('💧 Pipeline Leaks'),
                _buildSlider(
                  value: _thresholds['pipeline_leak']!,
                  onChanged: (val) => _saveConfidence('pipeline_leak', val),
                  color: const Color(0xFF10B981)
                ),

                const SizedBox(height: 24),

                _buildCategoryHeader('🏗️ Corrosion'),
                _buildSlider(
                  value: _thresholds['corrosion']!,
                  onChanged: (val) => _saveConfidence('corrosion', val),
                  color: const Color(0xFFEF4444)
                ),

                const SizedBox(height: 40),

                Text(
                  'GLOBAL SETTINGS',
                  style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B), 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 16),

                _buildSliderCard(
                  title: 'Non-Maximum Supression (IoU)',
                  value: _iouThreshold,
                  min: 0.1,
                  max: 0.9,
                  onChanged: _saveIou,
                  icon: Icons.layers_clear_outlined,
                  color: const Color(0xFF64748B)
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: SliderTheme(
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
            ),
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(value * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: color),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
