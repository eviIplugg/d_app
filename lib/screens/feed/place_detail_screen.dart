import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/place_item.dart';
import '../../services/yandex_places_service.dart';
import 'event_photo_viewer_screen.dart';
import 'widgets/place_catalog_cover.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final PlaceItem place;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late PlaceItem _place;
  bool _enriching = true;

  static const Color _burgundy = Color(0xFF81262B);
  static const Color _tagGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _enrich();
  }

  Future<void> _enrich() async {
    try {
      final enriched = await YandexPlacesService().fetchPlaceById(widget.place.id);
      if (!mounted || enriched == null) return;
      setState(() {
        _place = widget.place.copyWith(
          photoUrls: enriched.photoUrls.isNotEmpty ? enriched.photoUrls : widget.place.photoUrls,
          description: enriched.description ?? widget.place.description,
          address: enriched.address ?? widget.place.address,
          hours: enriched.hours ?? widget.place.hours,
          phones: enriched.phones ?? widget.place.phones,
          rating: enriched.rating ?? widget.place.rating,
          categories: enriched.categories.isNotEmpty ? enriched.categories : widget.place.categories,
        );
      });
    } catch (_) {
      // оставляем данные из списка
    } finally {
      if (mounted) setState(() => _enriching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gallery = _place.displayGalleryUrls;
    final coverUrl = _place.displayCoverImageUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share, color: Colors.white),
                onPressed: () => _sharePlace(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PlaceCatalogCover(imageUrl: coverUrl, fit: BoxFit.cover, iconSize: 72),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  if (_enriching)
                    const Positioned(
                      right: 16,
                      bottom: 24,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _place.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF333333), height: 1.2),
                  ),
                  if (_place.categories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _place.categories.take(3).map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _tagGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _tagGreen)),
                        );
                      }).toList(),
                    ),
                  ],
                  if (_place.rating != null || _place.distanceLabel.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_place.rating != null) ...[
                          const Icon(Icons.star_rounded, size: 22, color: Color(0xFFFFB300)),
                          const SizedBox(width: 4),
                          Text(
                            _place.rating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                          ),
                        ],
                        if (_place.rating != null && _place.distanceLabel.isNotEmpty) const SizedBox(width: 16),
                        if (_place.distanceLabel.isNotEmpty)
                          Text(_place.distanceLabel, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                  ],
                  if (_place.description != null && _place.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(_place.description!.trim(), style: TextStyle(fontSize: 15, height: 1.45, color: Colors.grey.shade800)),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Галерея', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                      if (gallery.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => EventPhotoViewerScreen(photoUrls: gallery),
                            ),
                          ),
                          child: const Text('Все фото'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (gallery.isEmpty)
                    Text(
                      'В каталоге 2GIS для этого места нет фото в выдаче вашего API-ключа.',
                      style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade700),
                    )
                  else
                    SizedBox(
                      height: 108,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: gallery.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => EventPhotoViewerScreen(photoUrls: gallery, initialIndex: i),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  gallery[i],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 22),
                  const Text('Как добраться', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        _place.mapPreviewUrl(width: 720, height: 400),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  if (_place.address != null && _place.address!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(Icons.place_outlined, _place.address!),
                  ],
                  if (_place.hours != null && _place.hours!.isNotEmpty) _infoRow(Icons.schedule, _place.hours!),
                  if (_place.phones != null && _place.phones!.isNotEmpty) _infoRow(Icons.call, _place.phones!),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _openYandexMaps(context),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Открыть в Яндекс.Картах'),
                    style: FilledButton.styleFrom(backgroundColor: _burgundy, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _open2Gis(context),
                    icon: const Icon(Icons.business_outlined),
                    label: const Text('Карточка в 2ГИС'),
                    style: OutlinedButton.styleFrom(foregroundColor: _burgundy, minimumSize: const Size.fromHeight(48)),
                  ),
                  if (_place.url != null && _place.url!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(context, _place.url!),
                      icon: const Icon(Icons.public),
                      label: const Text('Сайт'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Фото заведения — только из каталога 2GIS (поля вроде external_content), если ваш ключ и тариф их отдают. Схема проезда — отдельно ниже.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35))),
        ],
      ),
    );
  }

  Future<void> _sharePlace(BuildContext context) async {
    final link = 'https://yandex.ru/maps/?ll=${_place.lng}%2C${_place.lat}&z=16&pt=${_place.lng},${_place.lat},pm2rdm';
    await Clipboard.setData(ClipboardData(text: '${_place.name}\n$link'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ссылка скопирована в буфер обмена')));
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _openYandexMaps(BuildContext context) async {
    final uri = Uri.parse('https://yandex.ru/maps/?ll=${_place.lng}%2C${_place.lat}&z=16&pt=${_place.lng},${_place.lat},pm2rdm');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть карты'), backgroundColor: Colors.orange));
    }
  }

  Future<void> _open2Gis(BuildContext context) async {
    final uri = Uri.parse(_place.firmProfileUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть 2ГИС'), backgroundColor: Colors.orange));
    }
  }
}
