import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/organizer_crm_service.dart';

/// Редактирование места проведения организатором.
class OrganizerVenueScreen extends StatefulWidget {
  const OrganizerVenueScreen({super.key, this.venueId, this.venueData});

  final String? venueId;
  final Map<String, dynamic>? venueData;

  @override
  State<OrganizerVenueScreen> createState() => _OrganizerVenueScreenState();
}

class _OrganizerVenueScreenState extends State<OrganizerVenueScreen> {
  final OrganizerCrmService _crm = OrganizerCrmService();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.venueData;
    if (d != null) {
      _nameController.text = d[kVenueName]?.toString() ?? '';
      _addressController.text = d[kVenueAddress]?.toString() ?? '';
      _cityController.text = d[kVenueCity]?.toString() ?? '';
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(imageQuality: 85, source: ImageSource.gallery);
    if (f == null) return;
    if (!mounted) return;
    setState(() => _photoPath = f.path);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название места')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _crm.saveVenue(
        venueId: widget.venueId,
        name: name,
        photoFilePath: _photoPath,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сохранено')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.venueId != null ? 'Редактировать место' : 'Добавить место',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('Фото места', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _field('Название', _nameController, required: true),
          _field('Адрес', _addressController),
          _field('Город', _cityController),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label + (required ? ' *' : ''), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
