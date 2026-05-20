import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/folder_model.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';

import 'documents_by_folder_screen.dart';

class FolderListScreen extends StatelessWidget {
  final List<Folder> folders;

  const FolderListScreen({super.key, required this.folders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3E5F5),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5),
              Colors.white,
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: folders.isEmpty
            ? const Center(child: Text('No folders yet.', style: TextStyle(fontWeight: FontWeight.bold)))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return _FolderCard(folder: folder);
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
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final Folder folder;
  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('folder_${folder.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (folder.id == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot delete default folder')),
          );
          return false;
        }
        return true;
      },
      onDismissed: (_) {
        context.read<DashboardBloc>().add(DeleteFolder(folder.id!));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.blue, size: 32),
            ),
            title: Text(
              folder.name,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 18, letterSpacing: -0.5),
            ),
            subtitle: Text(
              'Created: ${folder.createdAt.toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black),
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
      ),
    );
  }
}