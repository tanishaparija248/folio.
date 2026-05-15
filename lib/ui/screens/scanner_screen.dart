import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/scanner/scanner_bloc.dart';
import '../../blocs/scanner/scanner_event.dart';
import '../../blocs/scanner/scanner_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../widgets/glass_card.dart';
import 'studio_screen.dart';
import 'dart:io';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isReorderMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScannerBloc, ScannerState>(
      listener: (context, state) {
        if (state is ScannerImagesPicked) {
          _nameController.text = state.suggestedName;
        }
        if (state is ScannerSaved) {
          context.read<DashboardBloc>().add(LoadDashboard());
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document Saved Successfully')),
          );
        }
        if (state is ScannerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(_isReorderMode ? 'Reorder Pages' : 'Review Scans'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              if (state is ScannerImagesPicked) ...[
                IconButton(
                  icon: Icon(_isReorderMode ? Icons.grid_view : Icons.reorder),
                  onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
                  tooltip: _isReorderMode ? 'Grid View' : 'Reorder View',
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    context.read<ScannerBloc>().add(SaveDocument(
                          name: _nameController.text,
                          folderId: 1, // Default uncategorized
                        ));
                  },
                ),
              ]
            ],
          ),
          body: _buildBody(context, state),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state is ScannerImagesPicked || state is ScannerInitial)
                FloatingActionButton.extended(
                  onPressed: () {
                    context.read<ScannerBloc>().add(PickImages());
                  },
                  heroTag: 'gallery',
                  label: const Text('Gallery'),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
              const SizedBox(height: 12),
              if (state is ScannerImagesPicked || state is ScannerInitial)
                FloatingActionButton.extended(
                  onPressed: () {
                    context.read<ScannerBloc>().add(TakePhoto());
                  },
                  heroTag: 'camera',
                  label: const Text('Camera'),
                  icon: const Icon(Icons.camera_alt_outlined),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, ScannerImagesPicked state) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: state.images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () async {
            final File? editedImage = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudioScreen(image: state.images[index]),
              ),
            );
            if (editedImage != null && context.mounted) {
              context.read<ScannerBloc>().add(UpdateImage(index, editedImage));
            }
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  state.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    context.read<ScannerBloc>().add(RemoveImage(index));
                  },
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Page ${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReorderableList(BuildContext context, ScannerImagesPicked state) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.images.length,
      onReorder: (oldIndex, newIndex) {
        context.read<ScannerBloc>().add(ReorderImages(oldIndex, newIndex));
      },
      itemBuilder: (context, index) {
        return Padding(
          key: ValueKey(state.images[index].path),
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(state.images[index], width: 50, height: 50, fit: BoxFit.cover),
              ),
              title: Text(
                'Page ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              trailing: const Icon(Icons.drag_handle, color: Colors.black),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ScannerState state) {
    if (state is ScannerLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ScannerImagesPicked) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Document Name',
                labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit_note, color: Colors.black),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          Expanded(
            child: _isReorderMode ? _buildReorderableList(context, state) : _buildGrid(context, state),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No images picked yet',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
