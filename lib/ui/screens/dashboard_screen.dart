import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import 'scanner_screen.dart';
import 'document_detail_screen.dart';
import 'documents_by_folder_screen.dart';
import '../../repositories/document_repository.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../widgets/document_list_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Folio',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -1.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardInitial || state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return Center(child: Text(state.message));
          }
          if (state is DashboardLoaded) {
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildFolderHeader(context, state),
                _buildFolderList(context, state),
                _buildRecentHeader(context),
                _buildRecentList(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: const Color(0xFF673AB7),
        label: const Text('New Scan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildFolderHeader(BuildContext context, DashboardLoaded state) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Folders (${state.folders.length})',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
            ),
            IconButton(
              onPressed: () => _showAddFolderDialog(context),
              icon: const Icon(Icons.create_new_folder_outlined, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderList(BuildContext context, DashboardLoaded state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final folder = state.folders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DocumentsByFolderScreen(folder: folder)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.folder_rounded, color: Color(0xFF1976D2), size: 32),
                  ),
                  title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('${folder.createdAt.toString().split(' ')[0]} • Offline'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                ),
              ),
            );
          },
          childCount: state.folders.length,
        ),
      ),
    );
  }

  Widget _buildRecentHeader(BuildContext context) {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          'Recent Documents',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildRecentList(BuildContext context, DashboardLoaded state) {
    if (state.recentDocuments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text('No scans yet', style: TextStyle(fontWeight: FontWeight.bold))),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final doc = state.recentDocuments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Hero(
                tag: 'doc_${doc.id}',
                child: DocumentListTile(
                  doc: doc,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetailScreen(
                        document: doc,
                        repository: context.read<DocumentRepository>(),
                      ),
                    ),
                  ),
                  onDelete: () => context.read<DashboardBloc>().add(DeleteDocument(doc.id!)),
                ),
              ),
            );
          },
          childCount: state.recentDocuments.length,
        ),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Folder Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<DashboardBloc>().add(AddFolder(controller.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}