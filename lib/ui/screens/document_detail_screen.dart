import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../models/document_model.dart';
import '../../models/page_model.dart';
import '../../repositories/document_repository.dart';
import '../../services/pdf_service.dart';
import 'studio_screen.dart';
import '../../services/scanner_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;
  final DocumentRepository repository;

  const DocumentDetailScreen({
    super.key,
    required this.document,
    required this.repository,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final PdfService _pdfService = PdfService();
  bool _isReorderMode = false;
  List<PageModel>? _pages;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    final pages = await widget.repository.getPages(widget.document.id!);
    if (mounted) {
      setState(() {
        _pages = pages;
      });
    }
  }

  Future<void> _exportAndShare() async {
    try {
      if (_pages == null || _pages!.isEmpty) return;
      if (!mounted) return;

      final images = _pages!.map((p) => File(p.imagePath)).toList();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfFile = await _pdfService.generatePdf(images, widget.document.name);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final result = await Share.shareXFiles([XFile(pdfFile.path)], text: 'Check out this document from Folio');

      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shared successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.document.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isReorderMode ? Icons.grid_view : Icons.reorder),
            onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _exportAndShare,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              if (_pages == null) return;
              final images = _pages!.map((p) => File(p.imagePath)).toList();
              final pdfFile = await _pdfService.generatePdf(images, widget.document.name);
              await OpenFilex.open(pdfFile.path);
            },
          ),
        ],
      ),
      body: _pages == null
          ? const Center(child: CircularProgressIndicator())
          : _pages!.isEmpty
          ? const Center(child: Text('No pages found.'))
          : _isReorderMode
          ? _buildReorderableList()
          : _buildGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPages(context),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Future<void> _addPages(BuildContext context) async {
    final scannerService = context.read<ScannerService>();

    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Add More Pages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (source == null) return;

    List<File> newImages = [];
    if (source == 'camera') {
      final img = await scannerService.pickImageFromCamera();
      if (img != null) newImages.add(img);
    } else {
      newImages = await scannerService.pickImages();
    }

    if (newImages.isEmpty) return;
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final startOrder = _pages?.length ?? 0;
      for (int i = 0; i < newImages.length; i++) {
        final permanentFile = await scannerService.saveImageToPermanentStorage(newImages[i]);
        await widget.repository.addPage(PageModel(
          documentId: widget.document.id!,
          imagePath: permanentFile.path,
          pageOrder: startOrder + i,
        ));
      }

      if (context.mounted) Navigator.pop(context); // Close loading
      _loadPages(); // Refresh list
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding pages: $e')));
      }
    }
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _pages!.length,
      itemBuilder: (context, index) {
        final page = _pages![index];
        return Hero(
          tag: 'page_${page.id}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(page.imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final File? editedImage = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudioScreen(image: File(page.imagePath)),
                            ),
                          );
                          if (editedImage != null) {
                            final updatedPage = page.copyWith(imagePath: editedImage.path);
                            await widget.repository.updatePage(updatedPage);
                            _loadPages();
                          }
                        },
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit_outlined, size: 18, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await widget.repository.deletePage(page.id!);
                          _loadPages();
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.red.shade400,
                          child: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Page ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pages!.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final PageModel item = _pages!.removeAt(oldIndex);
          _pages!.insert(newIndex, item);
        });
        // Update order in DB
        for (int i = 0; i < _pages!.length; i++) {
          final updatedPage = _pages![i].copyWith(pageOrder: i);
          await widget.repository.updatePage(updatedPage);
        }
      },
      itemBuilder: (context, index) {
        final page = _pages![index];
        return Padding(
          key: ValueKey(page.id),
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(page.imagePath), width: 50, height: 50, fit: BoxFit.cover),
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
}