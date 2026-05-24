import 'package:flutter/material.dart';
import '../../models/folder_model.dart';

class FolderListTile extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String newName)? onRename; // ✅ ADD THIS

  const FolderListTile({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onDelete,
    required this.onRename, // ✅ ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    const Color card = Color(0xFF1F1B2E);
    const Color primary = Color(0xFF7C5CFC);
    const Color softPrimary = Color(0xFF2D2642);
    const Color text = Colors.white;
    const Color subtext = Color(0xFFA6A0C2);

    return Dismissible(
      key: Key('folder_${folder.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373),
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
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,

          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

          leading: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: softPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.folder_rounded,
              color: primary,
              size: 30,
            ),
          ),

          title: Text(
            folder.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: text,
            ),
          ),

          subtitle: Text(
            '${folder.createdAt.toString().split(' ')[0]} • Offline',
            style: const TextStyle(
              color: subtext,
              fontWeight: FontWeight.w500,
            ),
          ),

          trailing: PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFFB39DCA),
            ),
            onSelected: (value) {
              if (value == 'rename') {
                _showRenameDialog(context);
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'rename',
                child: Text('Rename'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Rename Folder"),
          content: TextField(
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();

                if (newName.isNotEmpty && newName != folder.name) {
                  onRename?.call(newName); // ✅ IMPORTANT
                }

                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}