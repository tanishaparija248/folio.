import 'package:equatable/equatable.dart';

class Document extends Equatable {
  final int? id;
  final int folderId;
  final String name;
  final DateTime createdAt;

  /// NEW
  final String ocrText;

  const Document({
    this.id,
    required this.folderId,
    required this.name,
    required this.createdAt,

    /// NEW
    required this.ocrText,
  });

  Document copyWith({
    int? id,
    int? folderId,
    String? name,
    DateTime? createdAt,

    /// NEW
    String? ocrText,
  }) {
    return Document(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,

      /// NEW
      ocrText: ocrText ?? this.ocrText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),

      /// NEW
      'ocrText': ocrText,
    };
  }

  factory Document.fromMap(
      Map<String, dynamic> map) {
    return Document(
      id: map['id'] as int?,
      folderId: map['folderId'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),

      /// NEW
      ocrText:
      map['ocrText'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    folderId,
    name,
    createdAt,

    /// NEW
    ocrText,
  ];
}