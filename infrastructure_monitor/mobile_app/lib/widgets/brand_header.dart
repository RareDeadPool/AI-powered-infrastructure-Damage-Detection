import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/sync_manager.dart';
import '../screens/main_screen.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/brand/logo.png', height: 40),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  children: const [
                    TextSpan(text: 'City', style: TextStyle(color: Color(0xFFF38020))),
                    TextSpan(text: 'Scan', style: TextStyle(color: Color(0xFF2D5096))),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4)),
                  (route) => false,
                );
              } else if (value == 'sync') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syncing Data...'), behavior: SnackBarBehavior.floating),
                );
                await SyncManager.syncData();
              } else if (value == 'logout') {
                AuthService.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF2D5096)),
                    const SizedBox(width: 12),
                    Text('Profile Settings', style: GoogleFonts.outfit(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded, size: 20, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Text('Offline Sync', style: GoogleFonts.outfit(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Text('Sign Out', style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AuthService.currentUser?.displayName ?? 'Inspector',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1D2B40)),
                    ),
                    Text(
                      'Ready to Scan',
                      style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF7B8EA7)),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFEEF2F6),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF7B8EA7), size: 24),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDF2F7)),
        ),
        child: Icon(icon, color: const Color(0xFF7B8EA7), size: 20),
      ),
    );
  }
}
