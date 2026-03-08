import 'package:flutter/material.dart';
import 'event_photo_viewer_screen.dart';

/// Сетка фото мероприятия (2 колонки). По тапу — полноэкранный просмотр «N из M».
class EventPhotoGridScreen extends StatelessWidget {
  const EventPhotoGridScreen({super.key, required this.photoUrls});

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Фото', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: photoUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => EventPhotoViewerScreen(
                    photoUrls: photoUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Image.network(
              photoUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
            ),
          );
        },
      ),
    );
  }
}
