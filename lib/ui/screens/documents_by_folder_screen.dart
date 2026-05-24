import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/folder_model.dart';
import '../../models/document_model.dart';
import '../../repositories/document_repository.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../widgets/document_list_tile.dart';
import 'document_detail_screen.dart';

const Color primaryColor = Color(0xFF5B67FF);
const Color cardColor = Color(0xFF1F1B2E);

class DocumentsByFolderScreen extends StatefulWidget {
  final Folder folder;

  const DocumentsByFolderScreen({
    super.key,
    required this.folder,
  });

  @override
  State<DocumentsByFolderScreen>
  createState() =>
      _DocumentsByFolderScreenState();
}

class _DocumentsByFolderScreenState
    extends State<
        DocumentsByFolderScreen> {

  @override
  Widget build(BuildContext context) {
    final repository =
    context.read<
        DocumentRepository>();

    return Container(
      decoration:
      const BoxDecoration(
        gradient: LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xFF12101C),
            Color(0xFF141B34),
            Color(0xFF0F0B18),
          ],
        ),
      ),

      child: Scaffold(
        backgroundColor:
        Colors.transparent,

        appBar: AppBar(
          backgroundColor:
          Colors.transparent,

          elevation: 0,

          foregroundColor:
          Colors.white,

          title: Text(
            widget.folder.name,

            style:
            const TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),

        body:
        FutureBuilder<
            List<Document>>(
          future: repository
              .getDocumentsInFolder(
            widget.folder.id!,
          ),

          builder:
              (context, snapshot) {
            if (snapshot
                .connectionState ==
                ConnectionState
                    .waiting) {
              return const Center(
                child:
                CircularProgressIndicator(
                  color:
                  primaryColor,
                ),
              );
            }

            if (!snapshot
                .hasData ||
                snapshot
                    .data!
                    .isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,

                  children: [
                    Container(
                      padding:
                      const EdgeInsets
                          .all(24),

                      decoration:
                      BoxDecoration(
                        shape:
                        BoxShape
                            .circle,

                        color:
                        primaryColor
                            .withOpacity(
                            0.08),

                        boxShadow: const [
                          BoxShadow(
                            color:
                            primaryColor,
                            blurRadius:
                            18,
                            spreadRadius:
                            0.5,
                          ),
                        ],
                      ),

                      child:
                      const Icon(
                        Icons
                            .folder_open_rounded,

                        size: 72,

                        color:
                        primaryColor,
                      ),
                    ),

                    const SizedBox(
                        height: 24),

                    const Text(
                      'No documents\ninside this folder',

                      textAlign:
                      TextAlign
                          .center,

                      style:
                      TextStyle(
                        color: Colors
                            .white,
                        fontWeight:
                        FontWeight
                            .w700,
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(
                        height: 10),

                    const Text(
                      'Your scanned files\nwill appear here',

                      textAlign:
                      TextAlign
                          .center,

                      style:
                      TextStyle(
                        color: Color(
                            0xFFA6A0C2),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            final docs =
            snapshot.data!;

            return ListView.separated(
              padding:
              const EdgeInsets
                  .all(20),

              itemCount:
              docs.length,

              separatorBuilder:
                  (_, __) =>
              const SizedBox(
                height: 14,
              ),

              itemBuilder:
                  (context, index) {
                final doc =
                docs[index];

                return Hero(
                  tag:
                  'doc_${doc.id}',

                  child: Container(
                    decoration:
                    BoxDecoration(
                      color:
                      cardColor,

                      borderRadius:
                      BorderRadius
                          .circular(
                          22),

                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withOpacity(
                              0.25),

                          blurRadius:
                          12,

                          offset:
                          const Offset(
                              0,
                              6),
                        ),
                      ],
                    ),

                    child:
                    DocumentListTile(
                      doc: doc,

                      onTap: () {
                        Navigator
                            .push(
                          context,

                          MaterialPageRoute(
                            builder:
                                (context) =>
                                DocumentDetailScreen(
                                  document:
                                  doc,
                                  repository:
                                  repository,
                                ),
                          ),
                        );
                      },

                      onDelete: () {
                        context
                            .read<
                            DashboardBloc>()
                            .add(
                          DeleteDocument(
                            doc.id!,
                          ),
                        );

                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}