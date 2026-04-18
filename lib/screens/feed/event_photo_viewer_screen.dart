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
    if (photoUrls.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Нет фото', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text('Нет изображений для просмотра', style: TextStyle(color: Colors.white70))),
      );
    }
    final maxIndex = photoUrls.length - 1;
    final page = initialIndex.clamp(0, maxIndex < 0 ? 0 : maxIndex);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            itemCount: photoUrls.length,
            controller: PageController(initialPage: page),
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
                      Text(
                        '${page + 1} из ${photoUrls.length}',
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
