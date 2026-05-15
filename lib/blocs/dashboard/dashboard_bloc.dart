import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../repositories/document_repository.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DocumentRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<AddFolder>(_onAddFolder);
    on<DeleteDocument>(_onDeleteDocument);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final folders = await repository.getFolders();
      final recentDocs = await repository.getRecentDocuments();
      
      // Calculate storage usage
      final directory = await getApplicationDocumentsDirectory();
      final folioDir = Directory(p.join(directory.path, 'scans'));
      double totalSize = 0;
      if (await folioDir.exists()) {
        await for (var file in folioDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
      final storageString = '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';

      emit(DashboardLoaded(
        folders: folders, 
        recentDocuments: recentDocs,
        storageUsage: storageString,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onAddFolder(
    AddFolder event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.createFolder(event.name);
      add(LoadDashboard());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.deleteDocument(event.id);
      add(LoadDashboard());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
