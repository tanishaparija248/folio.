import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../models/folder_model.dart';
import '../../models/document_model.dart';
import '../../repositories/document_repository.dart';
import '../widgets/glass_card.dart';
import 'document_detail_screen.dart';

class DocumentsByFolderScreen extends StatelessWidget {
  final Folder folder;

  const DocumentsByFolderScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<DocumentRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
      ),
      body: FutureBuilder<List<Document>>(
        future: repository.getDocumentsInFolder(folder.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No documents in this folder.'));
          }

          final docs = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Hero(
                tag: 'doc_${doc.id}',
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      doc.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().format(doc.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DocumentDetailScreen(
                            document: doc,
                            repository: repository,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
