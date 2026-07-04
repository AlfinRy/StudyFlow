import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index tab yang aktif di MainShell (0=Beranda, 1=Jadwal, 2=Tugas, 3=Progres,
/// 4=Profil). Dipakai agar layar anak (mis. Beranda) bisa memindahkan tab,
/// mis. lewat tombol "Lihat semua".
final activeTabProvider = StateProvider<int>((ref) => 0);
