import 'dart:math' as math;
import 'package:flutter/material.dart';

class BirthdateScreen extends StatefulWidget {
  const BirthdateScreen({super.key});

  @override
  State<BirthdateScreen> createState() => _BirthdateScreenState();
}

class _BirthdateScreenState extends State<BirthdateScreen> {
  late DateTime _selectedDate;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;
  
  int _selectedDayIndex = 25; // 26 день (индекс 25)
  int _selectedMonthIndex = 9; // Октябрь
  int _selectedYearIndex = 0;

  final List<String> _months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  @override
  void initState() {
    super.initState();
    // Устанавливаем начальную дату: 26 октября 2007 (18 лет)
    _selectedDate = DateTime(2007, 10, 26);
    _dayController = FixedExtentScrollController(initialItem: 25);
    _monthController = FixedExtentScrollController(initialItem: 9); // Октябрь
    _yearController = FixedExtentScrollController();
    
    // Устанавливаем позицию для года
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentYear = DateTime.now().year;
      final maxYear = currentYear - 13;
      final yearIndex = maxYear - 2007;
      if (yearIndex >= 0) {
        _yearController.jumpToItem(yearIndex);
        _selectedYearIndex = yearIndex;
      }
    });
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _handleNext() {
    // TODO: Сохранить дату рождения и перейти на следующий экран
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const GenderScreen()),
    // );
  }

  void _updateDate() {
    final now = DateTime.now();
    final currentYear = now.year;
    final maxYear = currentYear - 13; // Минимум 13 лет

    final year = maxYear - _selectedYearIndex;
    final month = _selectedMonthIndex + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = math.min(_selectedDayIndex + 1, daysInMonth);
    
    // Корректируем день, если он превышает количество дней в месяце
    if (_selectedDayIndex >= daysInMonth) {
      _selectedDayIndex = daysInMonth - 1;
      if (_dayController.hasClients) {
        _dayController.jumpToItem(_selectedDayIndex);
      }
    }

    setState(() {
      _selectedDate = DateTime(year, month, day);
    });
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year;
    final minYear = currentYear - 100;
    final maxYear = currentYear - 13; // Минимум 13 лет
    final years = List.generate(maxYear - minYear + 1, (i) => maxYear - i);
    
    // Вычисляем количество дней в выбранном месяце и году
    final selectedYear = maxYear - _selectedYearIndex;
    final selectedMonth = _selectedMonthIndex;
    final daysInMonth = _getDaysInMonth(selectedYear, selectedMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress bar
            _buildHeader(step: 1, totalSteps: 4),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Дата рождения',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF81262B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Date picker
                    SizedBox(
                      height: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Day picker
                          Expanded(
                            child: _buildPicker(
                              controller: _dayController,
                              itemCount: daysInMonth,
                              builder: (context, index) {
                                final isSelected = index == _selectedDayIndex;
                                return Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected 
                                        ? const Color(0xFF81262B) 
                                        : Colors.grey.shade400,
                                  ),
                                );
                              },
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedDayIndex = index;
                                });
                                _updateDate();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Month picker
                          Expanded(
                            flex: 2,
                            child: _buildPicker(
                              controller: _monthController,
                              itemCount: 12,
                              builder: (context, index) {
                                final isSelected = index == _selectedMonthIndex;
                                return Text(
                                  _months[index],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected 
                                        ? const Color(0xFF81262B) 
                                        : Colors.grey.shade400,
                                  ),
                                );
                              },
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedMonthIndex = index;
                                });
                                _updateDate();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Year picker
                          Expanded(
                            child: _buildPicker(
                              controller: _yearController,
                              itemCount: years.length,
                              builder: (context, index) {
                                final isSelected = index == _selectedYearIndex;
                                return Text(
                                  '${years[index]}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected 
                                        ? const Color(0xFF81262B) 
                                        : Colors.grey.shade400,
                                  ),
                                );
                              },
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedYearIndex = index;
                                });
                                _updateDate();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Age display
                    Text(
                      '${_calculateAge(_selectedDate)} лет',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF81262B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81262B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Далее',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Widget Function(BuildContext, int) builder,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    return Stack(
      children: [
        // Выделение выбранного элемента
        Positioned(
          top: 75,
          left: 0,
          right: 0,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
        ),
        // Picker
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 50,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onSelectedItemChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: builder,
          ),
          renderChildrenOutsideViewport: false,
        ),
      ],
    );
  }

  Widget _buildHeader({required int step, required int totalSteps}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF333333),
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          // Progress bar
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: step / totalSteps,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF81262B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          // Step counter
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              '$step/$totalSteps',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
