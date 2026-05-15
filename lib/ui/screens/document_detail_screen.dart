import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../models/document_model.dart';
import '../../models/page_model.dart';
import '../../repositories/document_repository.dart';
import '../../services/pdf_service.dart';
import '../widgets/glass_card.dart';
import 'studio_screen.dart';

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
  late Future<List<PageModel>> _pagesFuture;
  final PdfService _pdfService = PdfService();

  @override
  void initState() {
    super.initState();
    _pagesFuture = widget.repository.getPages(widget.document.id!);
  }

  Future<void> _exportAndShare() async {
    try {
      final pages = await _pagesFuture;
      if (pages.isEmpty) return;

      final images = pages.map((p) => File(p.imagePath)).toList();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfFile = await _pdfService.generatePdf(images, widget.document.name);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final result = await Share.shareXFiles([XFile(pdfFile.path)], text: 'Check out this document from Folio');
      
      if (result.status == ShareResultStatus.success) {
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
            icon: const Icon(Icons.share_outlined),
            onPressed: _exportAndShare,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              final pages = await _pagesFuture;
              final images = pages.map((p) => File(p.imagePath)).toList();
              final pdfFile = await _pdfService.generatePdf(images, widget.document.name);
              await OpenFilex.open(pdfFile.path);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<PageModel>>(
        future: _pagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No pages found.',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            );
          }

          final pages = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return Hero(
                tag: 'page_${page.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                        child: GestureDetector(
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
                              setState(() {
                                _pagesFuture = widget.repository.getPages(widget.document.id!);
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.edit_outlined, size: 20, color: Colors.black),
                          ),
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
        },
      ),
    );
  }
}
