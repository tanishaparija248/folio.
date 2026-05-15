import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../widgets/glass_card.dart';
import 'folder_list_screen.dart';
import 'scanner_screen.dart';
import 'document_detail_screen.dart';
import '../../repositories/document_repository.dart';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../../blocs/dashboard/dashboard_event.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF3E5F5),
              Colors.white,
              const Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DashboardError) {
                return Center(child: Text(state.message));
              }
              if (state is DashboardLoaded) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(context),
                    _buildBentoGrid(context, state),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('New Scan'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(24.0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Folio',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: -1,
                  ),
            ),
            Text(
              'Your AI Document Studio',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, DashboardLoaded state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildBentoCard(
                    context,
                    title: 'Total Scans',
                    subtitle: '${state.recentDocuments.length} files',
                    icon: Icons.auto_awesome_outlined,
                    height: 160,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    onTap: () {
                      // Navigate to something useful or show info
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildBentoCard(
                    context,
                    title: 'Storage',
                    subtitle: state.storageUsage,
                    icon: Icons.storage_rounded,
                    height: 160,
                    color: Colors.orange.withOpacity(0.15),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    context,
                    title: 'Folders',
                    subtitle: '${state.folders.length} groups',
                    icon: Icons.folder_outlined,
                    height: 120,
                    color: Colors.blue.withOpacity(0.15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FolderListScreen(folders: state.folders),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoCard(
                    context,
                    title: 'Browse',
                    subtitle: 'External PDFs',
                    icon: Icons.file_open_outlined,
                    height: 120,
                    color: Colors.green.withOpacity(0.15),
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null && result.files.single.path != null) {
                        OpenFilex.open(result.files.single.path!);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildRecentList(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    double height = 150,
    Color? color,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: Colors.black,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentList(BuildContext context, DashboardLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Scans',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.recentDocuments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No documents yet.'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.recentDocuments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = state.recentDocuments[index];
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      doc.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().format(doc.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          context.read<DashboardBloc>().add(DeleteDocument(doc.id!));
                        } else if (value == 'open') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DocumentDetailScreen(
                                document: doc,
                                repository: context.read<DocumentRepository>(),
                              ),
                            ),
                          );
                        } else if (value == 'share') {
                          // Simple share of the PDF (reusing logic or simplified for here)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Generating PDF to share...')),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('Open')),
                        const PopupMenuItem(value: 'share', child: Text('Share')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DocumentDetailScreen(
                            document: doc,
                            repository: context.read<DocumentRepository>(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
