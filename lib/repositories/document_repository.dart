import '../core/database_helper.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../models/page_model.dart';

class DocumentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// GET ALL FOLDERS
  Future<List<Folder>> getFolders() =>
      _dbHelper.getAllFolders();

  /// CREATE FOLDER
  Future<int> createFolder(String name) {
    final folder = Folder(
      name: name,
      createdAt: DateTime.now(),
    );

    return _dbHelper.insertFolder(folder);
  }

  /// RECENT DOCUMENTS
  Future<List<Document>> getRecentDocuments() =>
      _dbHelper.getRecentDocuments();

  /// DOCUMENTS IN FOLDER
  Future<List<Document>> getDocumentsInFolder(int folderId) =>
      _dbHelper.getDocumentsByFolder(folderId);

  /// CREATE DOCUMENT
  Future<int> createDocument(
      int folderId,
      String name,
      String ocrText,
      ) {
    final doc = Document(
      folderId: folderId,
      name: name,
      createdAt: DateTime.now(),
      ocrText: ocrText,
    );

    return _dbHelper.insertDocument(doc);
  }

  /// ADD PAGE
  Future<int> addPage(PageModel page) =>
      _dbHelper.insertPage(page);

  /// GET PAGES
  Future<List<PageModel>> getPages(int documentId) =>
      _dbHelper.getPagesByDocument(documentId);

  /// DELETE DOCUMENT
  Future<int> deleteDocument(int id) =>
      _dbHelper.deleteDocument(id);

  /// DELETE FOLDER
  Future<int> deleteFolder(int id) =>
      _dbHelper.deleteFolder(id);

  /// UPDATE PAGE
  Future<int> updatePage(PageModel page) =>
      _dbHelper.updatePage(page);

  /// DELETE PAGE
  Future<int> deletePage(int id) =>
      _dbHelper.deletePage(id);

  // ======================================================
  // ✅ NEW: RENAME SUPPORT (THIS FIXES YOUR ERROR)
  // ======================================================

  Future<void> renameFolder(int id, String newName) async {
    await _dbHelper.renameFolder(id, newName);
  }

  Future<void> renameDocument(int id, String newName) async {
    await _dbHelper.renameDocument(id, newName);
  }
}