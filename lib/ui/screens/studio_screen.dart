import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/color_filters.dart';
import 'package:image_cropper/image_cropper.dart';

class _TextAnnotation {
  String text;
  Offset position;
  Color color;
  double fontSize;

  _TextAnnotation({
    required this.text,
    required this.position,
    this.color = Colors.red,
    this.fontSize = 20,
  });
}

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
  Color _selectedPenColor = Colors.black;
  late SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );
  bool _isDrawing = false;
  double _brightness = 0.0;
  bool _showBrightness = false;
  bool _isTextMode = false;
  final List<_TextAnnotation> _annotations = [];

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  // ─── Color Matrix Helpers ───────────────────────────────────────────────────

  List<double> _getAdjustedFilter() {
    final b = _brightness;
    final brightnessMatrix = [
      1.0, 0.0, 0.0, 0.0, b * 255,
      0.0, 1.0, 0.0, 0.0, b * 255,
      0.0, 0.0, 1.0, 0.0, b * 255,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
    if (_selectedFilter == FolioFilters.original) {
      return brightnessMatrix;
    }
    return _multiplyColorMatrices(_selectedFilter, brightnessMatrix);
  }

  List<double> _multiplyColorMatrices(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0.0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) sum += a[i * 5 + 4];
        result[i * 5 + j] = sum;
      }
    }
    return result;
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

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
        IOSUiSettings(title: 'Crop Image'),
      ],
    );
    if (croppedFile != null) {
      setState(() => _currentImage = File(croppedFile.path));
    }
  }

  Future<void> _saveImage() async {
    try {
      RenderRepaintBoundary boundary =
      _renderKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imgFile = File(path);
      await imgFile.writeAsBytes(pngBytes);
      if (context.mounted) {
        Navigator.pop(context, imgFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _shareImage() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing to share...')),
      );
      RenderRepaintBoundary boundary =
      _renderKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/folio_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imgFile = File(path);
      await imgFile.writeAsBytes(pngBytes);
      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(imgFile.path)],
          text: 'Shared from Folio',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  void _onImageTap(TapDownDetails details) {
    if (!_isTextMode) return;
    _showAddTextDialog(details.localPosition);
  }

  void _showAddTextDialog(Offset position) {
    final textController = TextEditingController();
    Color selectedColor = Colors.red;
    double selectedSize = 20;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Text',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text input
                    TextField(
                      controller: textController,
                      autofocus: true,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. APPROVED, Verified...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Font size
                    const Text(
                      'Font Size',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.text_fields,
                            size: 16, color: Colors.black45),
                        Expanded(
                          child: Slider(
                            value: selectedSize,
                            min: 12,
                            max: 48,
                            divisions: 9,
                            label: selectedSize.toInt().toString(),
                            onChanged: (val) =>
                                setDialogState(() => selectedSize = val),
                          ),
                        ),
                        Text(
                          '${selectedSize.toInt()}px',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Color picker
                    const Text(
                      'Text Color',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Colors.red,
                        Colors.black,
                        Colors.blue,
                        Colors.green,
                        Colors.orange,
                        Colors.white,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.purple
                                    : Colors.grey.shade300,
                                width: selectedColor == color ? 2.5 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Preview
                    const Text(
                      'Preview',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        textController.text.isEmpty
                            ? 'Your text here'
                            : textController.text,
                        style: TextStyle(
                          color: selectedColor,
                          fontSize: selectedSize * 0.6,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black26,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (textController.text.trim().isNotEmpty) {
                      setState(() {
                        _annotations.add(_TextAnnotation(
                          text: textController.text.trim(),
                          position: position,
                          color: selectedColor,
                          fontSize: selectedSize,
                        ));
                      });
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAnnotationDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Text?'),
        content: Text('"${_annotations[index].text}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _annotations.removeAt(index));
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Studio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _shareImage,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: _saveImage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _renderKey,
              child: GestureDetector(
                onTapDown: _onImageTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image with filter + brightness
                    ColorFiltered(
                      colorFilter:
                      ColorFilter.matrix(_getAdjustedFilter()),
                      child: Image.file(
                        _currentImage,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),

                    // Text annotations
                    ..._annotations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final annotation = entry.value;
                      return Positioned(
                        left: annotation.position.dx,
                        top: annotation.position.dy,
                        child: GestureDetector(
                          onLongPress: () =>
                              _showDeleteAnnotationDialog(index),
                          child: Text(
                            annotation.text,
                            style: TextStyle(
                              color: annotation.color,
                              fontSize: annotation.fontSize,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Signature overlay
                    if (_isDrawing)
                      Signature(
                        controller: _signatureController,
                        height: double.infinity,
                        width: double.infinity,
                        backgroundColor: Colors.transparent,
                      ),

                    // Text mode hint
                    if (_isTextMode)
                      Positioned(
                        top: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Tap anywhere to add text',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Brightness slider
          if (_showBrightness) _buildBrightnessSlider(),

          // Filter bar
          _buildFilterBar(),

          // Toolbar
          _buildToolbar(),
        ],
      ),
    );
  }

  // ─── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildBrightnessSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.brightness_low, size: 20, color: Colors.black54),
          Expanded(
            child: Slider(
              value: _brightness,
              min: -0.5,
              max: 0.5,
              divisions: 20,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) => setState(() => _brightness = val),
            ),
          ),
          const Icon(Icons.brightness_high, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _brightness = 0.0),
            child:
            const Icon(Icons.refresh, size: 20, color: Colors.black54),
          ),
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
                    ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
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
                        child:
                        Image.file(_currentImage, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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

  Widget _buildPenColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Pen Color:',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Color tempColor = _selectedPenColor;
            showDialog(
              context: context,
              builder: (ctx) {
                return StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      title: const Text('Pick Pen Color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: tempColor,
                          onColorChanged: (color) {
                            setDialogState(() => tempColor = color);
                          },
                          enableAlpha: false,
                          labelTypes: const [],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedPenColor = tempColor;
                              _signatureController = SignatureController(
                                penStrokeWidth: 3,
                                penColor: tempColor,
                                exportBackgroundColor: Colors.transparent,
                              );
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _selectedPenColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Tap to change',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDrawing) ...[
            _buildPenColorPicker(),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolItem(
                icon: Icons.gesture,
                label: 'Sign',
                onTap: () => setState(() {
                  _isDrawing = !_isDrawing;
                  if (_isDrawing) _isTextMode = false;
                }),
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
                onTap: () => setState(() {
                  _signatureController.clear();
                  _annotations.clear();
                }),
              ),
              _buildToolItem(
                icon: Icons.crop,
                label: 'Crop',
                onTap: _cropImage,
              ),
              _buildToolItem(
                icon: Icons.brightness_6,
                label: 'Brightness',
                onTap: () =>
                    setState(() => _showBrightness = !_showBrightness),
                active: _showBrightness,
              ),
              _buildToolItem(
                icon: Icons.text_fields,
                label: 'Text',
                onTap: () => setState(() {
                  _isTextMode = !_isTextMode;
                  if (_isTextMode) _isDrawing = false;
                }),
                active: _isTextMode,
              ),
            ],
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
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.black87,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

