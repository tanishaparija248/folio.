import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import '../../core/color_filters.dart';
import 'package:image_cropper/image_cropper.dart';

class StudioScreen extends StatefulWidget {
  final File image;

  const StudioScreen({super.key, required this.image});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  final GlobalKey _renderKey = GlobalKey();
  late File _currentImage;
  List<double> _selectedFilter = FolioFilters.original;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
  }

  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentImage.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _currentImage = File(croppedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Studio'),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              try {
                RenderRepaintBoundary boundary = _renderKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                Uint8List pngBytes = byteData!.buffer.asUint8List();

                final directory = await getApplicationDocumentsDirectory();
                final path = '${directory.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
                final File imgFile = File(path);
                await imgFile.writeAsBytes(pngBytes);

                if (context.mounted) {
                  // Explicitly return the file to the caller
                  Navigator.pop(context, imgFile);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _renderKey,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(_selectedFilter),
                    child: Image.file(_currentImage),
                  ),
                  if (_isDrawing)
                    Signature(
                      controller: _signatureController,
                      height: double.infinity,
                      width: double.infinity,
                      backgroundColor: Colors.transparent,
                    ),
                ],
              ),
            ),
          ),
          _buildFilterBar(),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: FolioFilters.all.length,
        itemBuilder: (context, index) {
          String name = FolioFilters.all.keys.elementAt(index);
          List<double> filter = FolioFilters.all.values.elementAt(index);
          bool isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(filter),
                        child: Image.file(_currentImage, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolItem(
            icon: Icons.gesture,
            label: 'Sign',
            onTap: () => setState(() => _isDrawing = !_isDrawing),
            active: _isDrawing,
          ),
          _buildToolItem(
            icon: Icons.undo,
            label: 'Undo',
            onTap: () => _signatureController.undo(),
          ),
          _buildToolItem(
            icon: Icons.clear,
            label: 'Clear',
            onTap: () => _signatureController.clear(),
          ),
          _buildToolItem(
            icon: Icons.crop,
            label: 'Crop',
            onTap: _cropImage,
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? Theme.of(context).colorScheme.primary : Colors.black87,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Theme.of(context).colorScheme.primary : Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}