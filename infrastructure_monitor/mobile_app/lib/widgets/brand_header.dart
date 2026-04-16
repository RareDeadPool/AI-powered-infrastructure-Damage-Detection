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
          PopupMenuButton<String>(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              if (value == 'sync') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syncing Data...'), behavior: SnackBarBehavior.floating),
                );
                await SyncManager.syncData();
              } else if (value == 'signout') {
                await AuthService.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded, color: Color(0xFF2D5096), size: 20),
                    const SizedBox(width: 12),
                    Text('Sync Data', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 12),
                    Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: const Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEEF2F6),
              child: const Icon(Icons.person_rounded, color: Color(0xFF7B8EA7), size: 22),
            ),
          ),
        ],
      ),
    );
  }

}
