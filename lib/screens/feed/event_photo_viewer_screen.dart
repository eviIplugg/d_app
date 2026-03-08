import 'package:flutter/material.dart';

/// Полноэкранный просмотр фото с счётчиком «N из M» и кнопкой закрытия.
class EventPhotoViewerScreen extends StatelessWidget {
  const EventPhotoViewerScreen({
    super.key,
    required this.photoUrls,
    this.initialIndex = 0,
  });

  final List<String> photoUrls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            itemCount: photoUrls.length,
            controller: PageController(initialPage: initialIndex.clamp(0, photoUrls.length - 1)),
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  child: Image.network(
                    photoUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.white54),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      if (photoUrls.isNotEmpty)
                        Text(
                          '${initialIndex + 1} из ${photoUrls.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
