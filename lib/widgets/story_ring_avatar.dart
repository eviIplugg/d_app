import 'package:flutter/material.dart';

/// Аватар с маленьким градиентным кружком над ним (есть история) и опциональной обводкой.
class StoryRingAvatar extends StatelessWidget {
  const StoryRingAvatar({
    super.key,
    required this.radius,
    this.photoUrl,
    required this.hasStory,
    this.resizeWidth,
  });

  final double radius;
  final String? photoUrl;
  final bool hasStory;
  final int? resizeWidth;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final n = NetworkImage(photoUrl!);
      image = resizeWidth != null ? ResizeImage(n, width: resizeWidth!, height: resizeWidth!) : n;
    }

    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage: image,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Icon(Icons.person, size: radius * 1.1, color: Colors.grey)
          : null,
    );

    final decorated = hasStory
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF81262B), width: 2),
            ),
            child: avatar,
          )
        : avatar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasStory)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF81262B), Color(0xFFE91E63)]),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        decorated,
      ],
    );
  }
}
