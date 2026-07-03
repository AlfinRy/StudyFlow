import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/hive_service.dart';
import 'data/material_repository.dart';
import 'domain/study_material.dart';

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository(HiveService.instance.materials);
});

/// State reaktif untuk seluruh daftar materi.
final materialListProvider =
    NotifierProvider<MaterialListNotifier, List<StudyMaterial>>(
        MaterialListNotifier.new);

class MaterialListNotifier extends Notifier<List<StudyMaterial>> {
  late final MaterialRepository _repo;

  @override
  List<StudyMaterial> build() {
    _repo = ref.watch(materialRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> add(StudyMaterial material) async {
    await _repo.add(material);
    state = _repo.getAll();
  }

  Future<void> update(StudyMaterial material) async {
    await _repo.update(material);
    state = _repo.getAll();
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();
}
