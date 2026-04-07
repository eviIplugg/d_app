import 'package:flutter/material.dart';
import '../services/cities_service.dart';

/// Экран выбора города России: поиск по списку и выбор.
class CityPickerScreen extends StatefulWidget {
  final String? initialCity;

  const CityPickerScreen({super.key, this.initialCity});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final CitiesService _citiesService = CitiesService();
  final TextEditingController _searchController = TextEditingController();
  List<String> _allCities = [];
  List<String> _filteredCities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _searchController.text = widget.initialCity!;
    }
  }

  Future<void> _loadCities() async {
    final list = await _citiesService.getCityNames();
    if (!mounted) return;
    setState(() {
      _allCities = list;
      _filteredCities = _applyFilter(list, _searchController.text);
      _loading = false;
    });
  }

  List<String> _applyFilter(List<String> list, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.from(list);
    return list.where((c) => c.toLowerCase().contains(q)).toList();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCities = _applyFilter(_allCities, _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: const Text(
          'Выберите город',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _onSearchChanged(),
              decoration: InputDecoration(
                hintText: 'Поиск города...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF81262B)))
                : ListView.builder(
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      return ListTile(
                        title: Text(city),
                        onTap: () => Navigator.pop(context, city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
