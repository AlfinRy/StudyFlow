import 'material_file_type.dart';

/// Satu entri materi pembelajaran (PRD §4.2 box `materials`).
///
/// Nama class `StudyMaterial` (bukan `Material`) untuk menghindari bentrok
/// dengan widget `Material` dari Flutter.
class StudyMaterial {
  const StudyMaterial({
    required this.id,
    required this.title,
    required this.category,
    required this.filePathOrUrl,
    required this.fileType,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final String filePathOrUrl;
  final MaterialFileType fileType;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'filePathOrUrl': filePathOrUrl,
        'fileType': fileType.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StudyMaterial.fromMap(Map<String, dynamic> map) => StudyMaterial(
        id: map['id'] as String,
        title: map['title'] as String,
        category: map['category'] as String,
        filePathOrUrl: map['filePathOrUrl'] as String,
        fileType: MaterialFileType.fromString(map['fileType'] as String?),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  StudyMaterial copyWith({
    String? id,
    String? title,
    String? category,
    String? filePathOrUrl,
    MaterialFileType? fileType,
    DateTime? createdAt,
  }) {
    return StudyMaterial(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      filePathOrUrl: filePathOrUrl ?? this.filePathOrUrl,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyMaterial &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          category == other.category &&
          filePathOrUrl == other.filePathOrUrl &&
          fileType == other.fileType &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, title, category, filePathOrUrl, fileType, createdAt);
}
