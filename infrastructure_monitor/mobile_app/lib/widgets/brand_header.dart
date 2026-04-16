import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/sync_manager.dart';

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
          Row(
            children: [
              _buildHeaderIcon(
                context,
                icon: Icons.sync_rounded, 
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing Data...'), behavior: SnackBarBehavior.floating),
                  );
                  await SyncManager.syncData();
                }
              ),
              const SizedBox(width: 10),
              _buildHeaderIcon(
                context,
                icon: Icons.logout_rounded, 
                onTap: () => AuthService.signOut()
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEEF2F6),
                child: const Icon(Icons.person_rounded, color: Color(0xFF7B8EA7), size: 22),
              ),
            ],
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
