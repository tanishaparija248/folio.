import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/scanner/scanner_bloc.dart';
import '../../blocs/scanner/scanner_event.dart';
import '../../repositories/document_repository.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/folder_list_tile.dart';
import 'scanner_screen.dart';
import 'document_detail_screen.dart';
import 'documents_by_folder_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  static const Color primaryColor = Color(0xFF7C5CFC);
  static const Color accentColor = Color(0xFF1F1B2E);
  static const Color headingText = Colors.white;
  static const Color subtitleText = Color(0xFFA6A0C2);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF12101C),
            Color(0xFF181424),
            Color(0xFF0F0B18),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 20,

          title: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(
                'Folio',
                textAlign: TextAlign.left,

                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 1),

              Text(
                'Scan smarter, organize faster',
                textAlign: TextAlign.left,

                style: TextStyle(
                  color: Color(0xFFA6A0C2),
                  fontSize: 13,

                ),
              ),
            ],
          ),
        ),

        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (state is DashboardError) {
              return Center(
                child: Text(state.message,
                    style: const TextStyle(color: subtitleText)),
              );
            }

            if (state is DashboardLoaded) {
              return CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(
                    'Folders (${state.folders.length})',
                    onAdd: () => _showAddFolderDialog(context),
                  ),

                  _buildFolderList(state),

                  _buildHeader('Recent Documents'),

                  _buildRecentList(state),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            }

            return const SizedBox();
          },
        ),

        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          onPressed: () {
            context.read<ScannerBloc>().add(ResetScanner());

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ScannerScreen(),
              ),
            );
          },
          icon: const Icon(Icons.document_scanner),
          label: const Text("New Scan"),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader(String title, {VoidCallback? onAdd}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            if (onAdd != null)
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add, color: primaryColor),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- FOLDERS ----------------

  Widget _buildFolderList(DashboardLoaded state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final folder = state.folders[index];

          return FolderListTile(
            folder: folder,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DocumentsByFolderScreen(folder: folder),
                ),
              );
            },

            onDelete: () {
              context.read<DashboardBloc>().add(
                DeleteFolder(folder.id!),
              );
            },

            onRename: (newName) {
              context.read<DashboardBloc>().add(
                RenameFolder(folder.id!, newName),
              );
            },
          );
        },
        childCount: state.folders.length,
      ),
    );
  }

  // ---------------- RECENT DOCUMENTS ----------------

  Widget _buildRecentList(DashboardLoaded state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final doc = state.recentDocuments[index];

          return DocumentListTile(
            doc: doc,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentDetailScreen(
                    document: doc,
                    repository:
                    context.read<DocumentRepository>(),
                  ),
                ),
              );
            },

            onDelete: () {
              context.read<DashboardBloc>().add(
                DeleteDocument(doc.id!),
              );
            },

            onRename: (newName) {
              context.read<DashboardBloc>().add(
                RenameDocument(doc.id!, newName),
              );
            },
          );
        },
        childCount: state.recentDocuments.length,
      ),
    );
  }

  // ---------------- ADD FOLDER DIALOG ----------------

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("New Folder"),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  context.read<DashboardBloc>().add(
                    AddFolder(controller.text),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }
}