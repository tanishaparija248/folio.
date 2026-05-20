import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../models/folder_model.dart';
import '../../models/document_model.dart';
import '../../repositories/document_repository.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../widgets/document_list_tile.dart';
import 'document_detail_screen.dart';

class DocumentsByFolderScreen extends StatefulWidget {
  final Folder folder;

  const DocumentsByFolderScreen({super.key, required this.folder});

  @override
  State<DocumentsByFolderScreen> createState() => _DocumentsByFolderScreenState();
}

class _DocumentsByFolderScreenState extends State<DocumentsByFolderScreen> {
  @override
  Widget build(BuildContext context) {
    final repository = context.read<DocumentRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E5F5),
              Colors.white,
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: FutureBuilder<List<Document>>(
          future: repository.getDocumentsInFolder(widget.folder.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No documents in this folder.',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              );
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
                  child: DocumentListTile(
                    doc: doc,
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
                    onDelete: () {
                      context.read<DashboardBloc>().add(DeleteDocument(doc.id!));
                      setState(() {}); // Refresh list
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}