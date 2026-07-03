import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../domain/study_material.dart';

/// Akses data materi dari Hive box `materials` (offline-first).
class MaterialRepository {
  MaterialRepository(this._box);

  final Box<dynamic> _box;
  static const _uuid = Uuid();

  /// Semua materi, terbaru di atas.
  List<StudyMaterial> getAll() {
    final items = _box.values
        .map((v) => StudyMaterial.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Tambah materi. Meng-generate id jika kosong.
  Future<StudyMaterial> add(StudyMaterial material) async {
    final id = material.id.isEmpty ? _uuid.v4() : material.id;
    final item = material.id.isEmpty ? material.copyWith(id: id) : material;
    await _box.put(id, item.toMap());
    return item;
  }

  Future<void> update(StudyMaterial material) async =>
      _box.put(material.id, material.toMap());

  Future<void> remove(String id) async => _box.delete(id);
}
