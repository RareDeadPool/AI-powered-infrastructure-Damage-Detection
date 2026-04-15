import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../repositories/project_repository.dart';
import '../models/project_model.dart';
import 'project_setup_screen.dart';
import 'login_screen.dart';
import '../services/sync_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-sync when dashboard opens
    SyncManager.syncData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InfraScan Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync), 
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting Sync...'), duration: Duration(seconds: 1)),
              );
              await SyncManager.syncData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () async {
              await AuthService.signOut();
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.projectsBox.listenable(),
        builder: (context, Box<Project> box, _) {
          final projects = ProjectRepository.getProjectsForUser(AuthService.currentUser?.uid ?? '');
          
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    "No offline projects yet.\nStart a new inspection!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.architecture, color: Colors.white),
                  ),
                  title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Created: ${project.createdAt.toString().split('.')[0]}"),
                  trailing: Icon(
                    project.isSynced ? Icons.cloud_done : Icons.cloud_off,
                    color: project.isSynced ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    // Logic for viewing results would go here
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProjectSetupScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Project", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
