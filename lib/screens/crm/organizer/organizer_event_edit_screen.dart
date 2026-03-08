import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase/firestore_schema.dart';
import '../../../services/organizer_crm_service.dart';

/// Создание/редактирование мероприятия организатором.
class OrganizerEventEditScreen extends StatefulWidget {
  const OrganizerEventEditScreen({
    super.key,
    required this.venues,
    this.eventId,
    this.eventData,
  });

  final List<Map<String, dynamic>> venues;
  final String? eventId;
  final Map<String, dynamic>? eventData;

  @override
  State<OrganizerEventEditScreen> createState() => _OrganizerEventEditScreenState();
}

class _OrganizerEventEditScreenState extends State<OrganizerEventEditScreen> {
  final OrganizerCrmService _crm = OrganizerCrmService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedVenueId;
  DateTime _dateTime = DateTime.now().add(const Duration(days: 1));
  final _maxParticipantsController = TextEditingController();
  int _maxParticipants = 15;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.venues.isNotEmpty && _selectedVenueId == null) {
      _selectedVenueId = widget.venues.first['id'] as String?;
    }
    final d = widget.eventData;
    if (d != null) {
      _titleController.text = d[kEventTitle]?.toString() ?? '';
      _descriptionController.text = d[kEventDescription]?.toString() ?? '';
      _addressController.text = d[kEventAddress]?.toString() ?? '';
      _cityController.text = d[kEventCity]?.toString() ?? '';
      _priceController.text = d[kEventPrice]?.toString() ?? '';
      _selectedVenueId = d[kEventVenueId]?.toString();
      _maxParticipants = (d[kEventMaxParticipants] as int?) ?? 15;
      _maxParticipantsController.text = '$_maxParticipants';
      final t = d[kEventDateTime];
      if (t is Timestamp) _dateTime = t.toDate();
    } else {
      _maxParticipantsController.text = '$_maxParticipants';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название мероприятия')));
      return;
    }
    final venueId = _selectedVenueId;
    if (venueId == null || venueId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите место проведения')));
      return;
    }
    setState(() => _saving = true);
    try {
      final venue = widget.venues.cast<Map<String, dynamic>?>().firstWhere((v) => v!['id'] == venueId, orElse: () => null);
      final maxP = int.tryParse(_maxParticipantsController.text.trim()) ?? 15;
      await _crm.saveEvent(
        eventId: widget.eventId,
        venueId: venueId,
        title: title,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        dateTime: _dateTime,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        price: _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
        maxParticipants: maxP,
        venueName: venue?['name']?.toString(),
        venueVerified: venue?['verified'] == true,
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
          widget.eventId != null ? 'Редактировать мероприятие' : 'Новое мероприятие',
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
          _field('Название *', _titleController),
          _dropdown('Место проведения', _selectedVenueId, widget.venues, (v) => setState(() => _selectedVenueId = v)),
          _dateTimePicker(),
          _field('Описание', _descriptionController, maxLines: 3),
          _field('Адрес', _addressController),
          _field('Город', _cityController),
          _field('Цена (например 1500 ₽)', _priceController),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const Text('Макс. участников: ', style: TextStyle(fontSize: 14)),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _maxParticipantsController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _maxParticipants = int.tryParse(v) ?? 15,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
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

  Widget _dropdown(String label, String? value, List<Map<String, dynamic>> venues, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButton<String>(
              value: value ?? (venues.isNotEmpty ? venues.first['id'] as String? : null),
              isExpanded: true,
              underline: const SizedBox(),
              items: venues.map((v) {
                final id = v['id'] as String?;
                final name = v['name']?.toString() ?? id ?? '—';
                return DropdownMenuItem(value: id, child: Text(name));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Дата и время', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Colors.white,
            title: Text('${_dateTime.day}.${_dateTime.month}.${_dateTime.year} ${_dateTime.hour.toString().padLeft(2, '0')}:${_dateTime.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dateTime,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_dateTime),
                );
                if (time != null && mounted) {
                  setState(() {
                    _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
