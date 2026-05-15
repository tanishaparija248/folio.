import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/folder_model.dart';
import '../widgets/glass_card.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';

import 'documents_by_folder_screen.dart';

class FolderListScreen extends StatelessWidget {
  final List<Folder> folders;

  const FolderListScreen({super.key, required this.folders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Folders'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.folder, color: Colors.amber),
                  title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Created: ${folder.createdAt.toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentsByFolderScreen(folder: folder),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFolderDialog(context),
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<DashboardBloc>().add(AddFolder(controller.text));
                Navigator.pop(dialogContext);
                Navigator.pop(context); // Go back to dashboard to refresh or handle state
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
