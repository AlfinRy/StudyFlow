import 'package:flutter/material.dart';

/// Logo aplikasi StudyFlow (asset `assets/images/logo-studyflow.png`).
///
/// Logo berlatar transparan dan didominasi warna biru, sehingga tampil baik
/// di atas hero card navy maupun permukaan terang. Pakai [size] untuk sisi
/// gambar (logo kotak). Konstruktor `const` agar bisa dipakai di tree const.
///
/// **Catatan ukuran:** [size] default (40) dipakai oleh pemanggil yang TIDAK
/// mengirim `size:` (top bar & halaman login) — ubah default di sini untuk
/// memperbesar/memperkecil logo di lokasi tersebut. Pemanggil besar (splash &
/// register) mengirim `size:` sendiri, jadi ubah di tempat masing-masing.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  /// Sisi gambar (width = height = [size]).
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo-studyflow.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Logo StudyFlow',
      excludeFromSemantics: false,
    );
  }
}
