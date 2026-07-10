import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Avatar profil serbaguna. Menangani tiga sumber `photoUrl`:
/// - `null`/kosong → inisial nama.
/// - data URI base64 (`data:image/...;base64,...`) → `Image.memory`.
/// - URL http/https → `NetworkImage`.
///
/// Dipakai untuk menampilkan avatar baik dari URL maupun hasil unggah foto
/// yang disimpan sebagai base64 di Firestore. Lihat PROGRESS.md (Fase 10b).
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 34,
    this.backgroundColor = AppColors.accent,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;

  ImageProvider? _provider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma < 0) return null;
      try {
        return MemoryImage(base64Decode(url.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: _provider(url),
      child: hasPhoto
          ? null
          : Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
