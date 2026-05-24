import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/scanner/scanner_bloc.dart';
import '../../blocs/scanner/scanner_event.dart';
import '../../blocs/scanner/scanner_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';

const Color primaryColor = Color(0xFF5B67FF);
const Color subtitleColor = Color(0xFFA6A0C2);

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
            const SnackBar(
              backgroundColor: primaryColor,
              content: Text('Document Saved Successfully'),
            ),
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
          backgroundColor: const Color(0xFF12101C),

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            title: Text(
              _isReorderMode ? 'Reorder Pages' : 'Review Scans',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),

            actions: [
              if (state is ScannerImagesPicked) ...[
                IconButton(
                  icon: Icon(
                    _isReorderMode
                        ? Icons.grid_view_rounded
                        : Icons.reorder_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      _isReorderMode = !_isReorderMode;
                    });
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.check_rounded),
                  onPressed: () => _showFolderSelection(context),
                ),
              ],
            ],
          ),

          body: _ScannerBody(
            state: state,
            nameController: _nameController,
            isReorderMode: _isReorderMode,
          ),

          floatingActionButton: _ScannerActions(state: state),
        );
      },
    );
  }

  // ================= FOLDER SELECTION =================
  void _showFolderSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (ctx) {
        return BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoaded) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Select Folder',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),

                  const Divider(color: Color(0xFF312A46)),

                  Expanded(
                    child: ListView.builder(
                      itemCount: state.folders.length,
                      itemBuilder: (ctx, index) {
                        final folder = state.folders[index];

                        return ListTile(
                          leading: const Icon(
                            Icons.folder_rounded,
                            color: primaryColor,
                          ),
                          title: Text(
                            folder.name,
                            style: const TextStyle(color: Colors.white),
                          ),

                          onTap: () {
                            final scannerState =
                                context.read<ScannerBloc>().state;

                            if (scannerState is ScannerImagesPicked) {
                              context.read<ScannerBloc>().add(
                                SaveDocument(
                                  name: _nameController.text,
                                  folderId: folder.id!,
                                ),
                              );
                            }

                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          },
        );
      },
    );
  }
}

// ================= SCANNER BODY =================
class _ScannerBody extends StatelessWidget {
  final ScannerState state;
  final TextEditingController nameController;
  final bool isReorderMode;

  const _ScannerBody({
    super.key,
    required this.state,
    required this.nameController,
    required this.isReorderMode,
  });

  @override
  Widget build(BuildContext context) {
    if (state is ScannerLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (state is ScannerImagesPicked) {
      final pickedState = state as ScannerImagesPicked;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Document Name',
                labelStyle: TextStyle(color: subtitleColor),
              ),
            ),
          ),

          Expanded(
            child: GridView.builder(
              itemCount: pickedState.images.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return Image.file(pickedState.images[index]);
              },
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Text(
        'No scans yet',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

// ================= SCANNER ACTIONS =================
class _ScannerActions extends StatelessWidget {
  final ScannerState state;

  const _ScannerActions({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'gallery',
          onPressed: () {
            context.read<ScannerBloc>().add(PickImages());
          },
          child: const Icon(Icons.photo_library),
        ),

        const SizedBox(height: 12),

        FloatingActionButton(
          heroTag: 'camera',
          onPressed: () {
            context.read<ScannerBloc>().add(TakePhoto());
          },
          child: const Icon(Icons.camera_alt),
        ),
      ],
    );
  }
}