import 'package:flutter/material.dart';

/// Фото заведения из каталога (URL) или нейтральный плейсхолдер.
/// Превью карты сюда не подставляется — карта только в блоке «Как добраться».
class PlaceCatalogCover extends StatelessWidget {
  const PlaceCatalogCover({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.iconSize = 52,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _EstablishmentPhotoPlaceholder(iconSize: iconSize),
      );
    }
    return _EstablishmentPhotoPlaceholder(iconSize: iconSize);
  }
}

class _EstablishmentPhotoPlaceholder extends StatelessWidget {
  const _EstablishmentPhotoPlaceholder({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E6E6E), Color(0xFF424242)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.storefront_rounded, size: iconSize, color: Colors.white24),
    );
  }
}
