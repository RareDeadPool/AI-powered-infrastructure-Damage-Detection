import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1D2B40),
        title: Text("ABOUT VERSION 26.0", 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: const Color(0xFF7B8EA7))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D5096), Color(0xFF4F85F3)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF2D5096).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "CityScan Mobile",
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF1D2B40)),
                  ),
                  Text(
                    "AI Infrastructure Intelligence",
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF7B8EA7), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF38020).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "BUILD v26.0.4 - RELEASE CANDIDATE",
                      style: GoogleFonts.outfit(color: const Color(0xFFF38020), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(
              "NEW IN V26.0",
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D5096), letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.wifi_off_rounded,
              "Offline-First Intelligence",
              "Execute full AI inspections without cellular data. Synchronize automatically when back in range.",
            ),
            _buildFeatureItem(
              Icons.picture_as_pdf_rounded,
              "Premium PDF Reports",
              "Generate standardized, project-ready legal PDF reports directly from your handset with cardinal coordinate mapping.",
            ),
            _buildFeatureItem(
              Icons.gps_fixed_rounded,
              "Cardinal Coordinate System",
              "High-precision GPS tracking supporting North-South/East-West industrial standards for asset management.",
            ),
            _buildFeatureItem(
              Icons.batch_prediction_rounded,
              "Project-Based Batch Scanning",
              "Group multiple site observations into a single cohesive project lifecycle for easier tracking and auditing.",
            ),
            _buildFeatureItem(
              Icons.analytics_rounded,
              "Real-time System Insights",
              "Advanced dashboard analytics showing total detections, project health, and system-wide anomaly statistics.",
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Text(
                    "Developer Information",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This application is designed for infrastructure officials and engineers to digitize manual inspection workflows using edge-AI.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6E7C91), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "© 2024 CityScan Systems. All rights reserved.",
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFCBD5E0)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5096).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D5096), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1D2B40))),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6E7C91), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
