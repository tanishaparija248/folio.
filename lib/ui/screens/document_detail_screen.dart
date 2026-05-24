import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/document_model.dart';
import '../../models/page_model.dart';
import '../../repositories/document_repository.dart';
import '../../services/pdf_service.dart';
import '../../services/scanner_service.dart';
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
  State<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState
    extends State<DocumentDetailScreen> {

  final PdfService _pdfService = PdfService();

  bool _isReorderMode = false;

  List<PageModel>? _pages;

  static const Color primaryColor =
  Color(0xFF6C63FF);

  static const Color backgroundColor =
  Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    final pages =
    await widget.repository.getPages(
      widget.document.id!,
    );

    if (mounted) {
      setState(() {
        _pages = pages;
      });
    }
  }

  /// OCR FUNCTION
  Future<void> _extractText(
      String imagePath) async {
    try {
      final inputImage =
      InputImage.fromFilePath(
        imagePath,
      );

      final textRecognizer =
      TextRecognizer();

      final RecognizedText
      recognizedText =
      await textRecognizer
          .processImage(
        inputImage,
      );

      await textRecognizer.close();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            "Extracted Text",
          ),
          content:
          SingleChildScrollView(
            child: Text(
              recognizedText.text
                  .isEmpty
                  ? "No text found"
                  : recognizedText.text,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  Future<void> _exportAndShare() async {
    try {
      if (_pages == null ||
          _pages!.isEmpty) return;

      final images = _pages!
          .map((p) => File(p.imagePath))
          .toList();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child:
          CircularProgressIndicator(),
        ),
      );

      final pdfFile =
      await _pdfService.generatePdf(
        images,
        widget.document.name,
      );

      if (!mounted) return;

      Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text:
        'Check out this document from Folio',
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:
            Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF111827),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              /// APP BAR
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [

                    IconButton(
                      onPressed: () =>
                          Navigator.pop(
                              context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),

                    Expanded(
                      child: Text(
                        widget.document.name,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 24,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isReorderMode =
                          !_isReorderMode;
                        });
                      },
                      icon: Icon(
                        _isReorderMode
                            ? Icons
                            .grid_view_rounded
                            : Icons
                            .reorder_rounded,
                        color:
                        Colors.white,
                      ),
                    ),

                    IconButton(
                      onPressed:
                      _exportAndShare,
                      icon: const Icon(
                        Icons.share,
                        color:
                        Colors.white,
                      ),
                    ),

                    IconButton(
                      onPressed:
                          () async {

                        if (_pages ==
                            null) return;

                        final images =
                        _pages!
                            .map(
                              (p) =>
                              File(
                                p.imagePath,
                              ),
                        )
                            .toList();

                        final pdfFile =
                        await _pdfService
                            .generatePdf(
                          images,
                          widget
                              .document
                              .name,
                        );

                        await OpenFilex
                            .open(
                          pdfFile.path,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .picture_as_pdf,
                        color:
                        Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              /// BODY
              Expanded(
                child: _pages == null
                    ? const Center(
                  child:
                  CircularProgressIndicator(
                    color:
                    primaryColor,
                  ),
                )
                    : _pages!.isEmpty
                    ? const Center(
                  child: Text(
                    'No Pages Found',
                    style:
                    TextStyle(
                      color:
                      Colors
                          .white,
                    ),
                  ),
                )
                    : _isReorderMode
                    ? _buildReorderableList()
                    : _buildGrid(),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton:
      FloatingActionButton(
        backgroundColor:
        primaryColor,
        onPressed: () =>
            _addPages(context),
        child: const Icon(
          Icons.add_a_photo_outlined,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _addPages(
      BuildContext context) async {

    final scannerService =
    context.read<ScannerService>();

    final source =
    await showModalBottomSheet<
        String>(
      context: context,
      backgroundColor:
      const Color(0xFF1E293B),
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [

            const SizedBox(height: 20),

            const Text(
              'Add More Pages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
              title: const Text(
                'Camera',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () =>
                  Navigator.pop(
                    ctx,
                    'camera',
                  ),
            ),

            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.white,
              ),
              title: const Text(
                'Gallery',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () =>
                  Navigator.pop(
                    ctx,
                    'gallery',
                  ),
            ),

            const SizedBox(height: 20),
          ],
        );
      },
    );

    if (source == null) return;

    List<File> newImages = [];

    if (source == 'camera') {
      final img = await scannerService
          .pickImageFromCamera();

      if (img != null) {
        newImages.add(img);
      }
    } else {
      newImages =
      await scannerService
          .pickImages();
    }

    if (newImages.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child:
        CircularProgressIndicator(),
      ),
    );

    try {
      final startOrder =
          _pages?.length ?? 0;

      for (int i = 0;
      i < newImages.length;
      i++) {

        final permanentFile =
        await scannerService
            .saveImageToPermanentStorage(
          newImages[i],
        );

        await widget.repository.addPage(
          PageModel(
            documentId:
            widget.document.id!,
            imagePath:
            permanentFile.path,
            pageOrder:
            startOrder + i,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }

      _loadPages();
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding:
      const EdgeInsets.all(16),
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: _pages!.length,
      itemBuilder:
          (context, index) {

        final page = _pages![index];

        return Hero(
          tag: 'page_${page.id}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                  22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.25),
                  blurRadius: 12,
                  offset:
                  const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [

                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                      22),
                  child: Image.file(
                    File(page.imagePath),
                    fit: BoxFit.cover,
                    width:
                    double.infinity,
                    height:
                    double.infinity,
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [

                      /// OCR
                      GestureDetector(
                        onTap: () async {
                          await _extractText(
                            page.imagePath,
                          );
                        },
                        child: Container(
                          padding:
                          const EdgeInsets
                              .all(10),
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.white,
                            shape:
                            BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .text_snippet_outlined,
                            size: 18,
                            color:
                            Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(
                          width: 8),

                      /// EDIT
                      GestureDetector(
                        onTap:
                            () async {

                          final File?
                          editedImage =
                          await Navigator
                              .push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                  StudioScreen(
                                    image: File(
                                      page.imagePath,
                                    ),
                                  ),
                            ),
                          );

                          if (editedImage !=
                              null) {

                            final updatedPage =
                            page.copyWith(
                              imagePath:
                              editedImage
                                  .path,
                            );

                            await widget
                                .repository
                                .updatePage(
                              updatedPage,
                            );

                            _loadPages();
                          }
                        },
                        child: Container(
                          padding:
                          const EdgeInsets
                              .all(10),
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.white,
                            shape:
                            BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .edit_outlined,
                            size: 18,
                            color:
                            Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(
                          width: 8),

                      /// DELETE
                      GestureDetector(
                        onTap:
                            () async {

                          await widget
                              .repository
                              .deletePage(
                            page.id!,
                          );

                          _loadPages();
                        },
                        child: Container(
                          padding:
                          const EdgeInsets
                              .all(10),
                          decoration:
                          BoxDecoration(
                            color: Colors
                                .redAccent,
                            shape:
                            BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .delete_outline,
                            size: 18,
                            color:
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
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
      padding:
      const EdgeInsets.all(16),
      itemCount: _pages!.length,
      onReorder:
          (oldIndex, newIndex) async {

        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }

          final item =
          _pages!.removeAt(oldIndex);

          _pages!.insert(
            newIndex,
            item,
          );
        });

        for (int i = 0;
        i < _pages!.length;
        i++) {

          final updatedPage =
          _pages![i].copyWith(
            pageOrder: i,
          );

          await widget.repository
              .updatePage(updatedPage);
        }
      },
      itemBuilder:
          (context, index) {

        final page = _pages![index];

        return Container(
          key: ValueKey(page.id),
          margin:
          const EdgeInsets.only(
              bottom: 12),
          decoration: BoxDecoration(
            color:
            const Color(0xFF1E293B),
            borderRadius:
            BorderRadius.circular(
                18),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius:
              BorderRadius.circular(
                  10),
              child: Image.file(
                File(page.imagePath),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              'Page ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            trailing: const Icon(
              Icons.drag_handle,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}