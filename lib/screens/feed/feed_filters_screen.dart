import 'package:flutter/material.dart';
import '../../services/feed_service.dart';

/// Фильтры ленты: кого показывать, дистанция, возраст, рост, интересы и т.д.
class FeedFiltersScreen extends StatefulWidget {
  const FeedFiltersScreen({super.key});

  @override
  State<FeedFiltersScreen> createState() => _FeedFiltersScreenState();
}

class _FeedFiltersScreenState extends State<FeedFiltersScreen> {
  String _whoToShow = 'men';
  bool _nearUs = false;
  bool _forMyAge = false;
  bool _verifiedOnly = false;
  bool _hasChildren = false;
  double _distanceMin = 2, _distanceMax = 16;
  double _ageMin = 18, _ageMax = 25;
  double _heightMin = 144, _heightMax = 185;
  final Set<String> _activities = {};
  final Set<String> _languages = {'Русский', 'Английский'};
  String _datingGoal = 'friendship';
  final Set<String> _smoking = {};
  final Set<String> _alcohol = {};
  final Set<String> _education = {};
  final Set<String> _zodiac = {};

  static const List<String> _activityOptions = ['Работа', 'Отдых', 'Спорт', 'Прогулки с собаками', 'Настольные игры'];
  static const List<String> _languageOptions = ['Русский', 'Английский', 'Испанский'];
  static const List<String> _smokingOptions = ['Курю', 'Не курю', 'На вечеринках'];
  static const List<String> _alcoholOptions = ['Пью', 'Не пью', 'На вечеринках'];
  static const List<String> _educationOptions = ['Профильное', 'Бакалавриат', 'Магистратура', 'Без образования'];
  static const List<String> _zodiacOptions = ['Овен', 'Телец', 'Близнецы', 'Рак', 'Лев', 'Дева', 'Весы', 'Скорпион', 'Стрелец', 'Козерог', 'Водолей', 'Рыбы'];

  void _reset() {
    setState(() {
      _whoToShow = 'men';
      _nearUs = false;
      _forMyAge = false;
      _verifiedOnly = false;
      _hasChildren = false;
      _distanceMin = 2;
      _distanceMax = 16;
      _ageMin = 18;
      _ageMax = 25;
      _heightMin = 144;
      _heightMax = 185;
      _activities.clear();
      _languages.clear();
      _languages.addAll(['Русский', 'Английский']);
      _datingGoal = 'friendship';
      _smoking.clear();
      _alcohol.clear();
      _education.clear();
      _zodiac.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Фильтры',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text('Сбросить', style: TextStyle(color: cs.primary)),
          ),
          TextButton(
            onPressed: () {
              FeedService().currentFilter = {
                'gender': _whoToShow,
                'ageMin': _ageMin.round(),
                'ageMax': _ageMax.round(),
                'distanceMax': _distanceMax.round(),
                'verifiedOnly': _verifiedOnly,
              };
              Navigator.pop(context);
            },
            child: Text('Готово', style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
          ),
        ],
      ),
      body: Theme(
        data: theme.copyWith(
          sliderTheme: theme.sliderTheme.copyWith(
            activeTrackColor: cs.primary,
            inactiveTrackColor: cs.outlineVariant,
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
            thumbColor: cs.primary,
            overlayColor: WidgetStateColor.resolveWith((s) => cs.primary.withValues(alpha: 0.12)),
          ),
        ),
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Кого показывать', [
            _radio('Мужчин', 'men'),
            _radio('Женщин', 'women'),
            _radio('Всех', 'everyone'),
          ]),
          _section('', [
            _switch('Рядом с нами', _nearUs, (v) => setState(() => _nearUs = v)),
            _switch('Для вашего возраста', _forMyAge, (v) => setState(() => _forMyAge = v)),
            _switch('Только с верификацией', _verifiedOnly, (v) => setState(() => _verifiedOnly = v)),
            _switch('Наличие детей', _hasChildren, (v) => setState(() => _hasChildren = v)),
          ]),
          _section('Дистанция (км)', [
            RangeSlider(
              values: RangeValues(_distanceMin, _distanceMax),
              min: 0,
              max: 100,
              divisions: 50,
              onChanged: (v) => setState(() {
                _distanceMin = v.start;
                _distanceMax = v.end;
              }),
            ),
            Text(
              '${_distanceMin.round()} – ${_distanceMax.round()} км',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ]),
          _section('Возраст', [
            RangeSlider(
              values: RangeValues(_ageMin, _ageMax),
              min: 18,
              max: 60,
              divisions: 42,
              onChanged: (v) => setState(() {
                _ageMin = v.start;
                _ageMax = v.end;
              }),
            ),
            Text(
              '${_ageMin.round()} – ${_ageMax.round()}',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ]),
          _section('Рост', [
            RangeSlider(
              values: RangeValues(_heightMin, _heightMax),
              min: 140,
              max: 220,
              divisions: 80,
              onChanged: (v) => setState(() {
                _heightMin = v.start;
                _heightMax = v.end;
              }),
            ),
            Text(
              '${_heightMin.round()} – ${_heightMax.round()} см',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ]),
          _section('Активности', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activityOptions.map((e) => _chip(e, _activities)).toList(),
            ),
          ]),
          _section('Языки', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languageOptions.map((e) => _checkChip(e, _languages)).toList(),
            ),
          ]),
          _section('Цели знакомства', [
            _goalRadio('Дружба', 'friendship'),
            _goalRadio('Общение', 'communication'),
            _goalRadio('Отношения', 'relationship'),
          ]),
          _section('Курение', [
            Wrap(spacing: 8, runSpacing: 8, children: _smokingOptions.map((e) => _checkChip(e, _smoking)).toList()),
          ]),
          _section('Алкоголь', [
            Wrap(spacing: 8, runSpacing: 8, children: _alcoholOptions.map((e) => _checkChip(e, _alcohol)).toList()),
          ]),
          _section('Уровень образования', [
            Wrap(spacing: 8, runSpacing: 8, children: _educationOptions.map((e) => _checkChip(e, _education)).toList()),
          ]),
          _section('Знак зодиака', [
            Wrap(spacing: 8, runSpacing: 8, children: _zodiacOptions.map((e) => _checkChip(e, _zodiac)).toList()),
          ]),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
            ),
          ...children,
        ],
      ),
    );
  }

  Widget _radio(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return RadioListTile<String>(
      title: Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface)),
      value: value,
      // ignore: deprecated_member_use
      groupValue: _whoToShow,
      // ignore: deprecated_member_use
      onChanged: (v) => setState(() => _whoToShow = v ?? _whoToShow),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _goalRadio(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final v = label == 'Дружба' ? 'friendship' : label == 'Общение' ? 'communication' : 'relationship';
    return RadioListTile<String>(
      title: Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface)),
      value: v,
      // ignore: deprecated_member_use
      groupValue: _datingGoal,
      // ignore: deprecated_member_use
      onChanged: (val) => setState(() => _datingGoal = val ?? _datingGoal),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      title: Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _chip(String label, Set<String> set) {
    final selected = set.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() {
        if (v) {
          set.add(label);
        } else {
          set.remove(label);
        }
      }),
    );
  }

  Widget _checkChip(String label, Set<String> set) {
    final selected = set.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() {
        if (v) {
          set.add(label);
        } else {
          set.remove(label);
        }
      }),
    );
  }
}
