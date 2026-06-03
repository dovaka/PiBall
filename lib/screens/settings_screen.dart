import 'package:flutter/material.dart';

import '../models/app_settings.dart';

/// Edits [AppSettings]. Returns the updated settings via Navigator.pop.
class SettingsScreen extends StatefulWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _s = widget.settings;

  late final _ascent = TextEditingController(
    text: _s.ascentRateFtPerMin.toStringAsFixed(0),
  );
  late final _decl = TextEditingController(
    text: _s.declinationDeg.toStringAsFixed(1),
  );

  @override
  void dispose() {
    _ascent.dispose();
    _decl.dispose();
    super.dispose();
  }

  void _commitText() {
    final ascent = double.tryParse(_ascent.text);
    final decl = double.tryParse(_decl.text);
    _s = _s.copyWith(
      ascentRateFtPerMin: (ascent != null && ascent > 0) ? ascent : null,
      declinationDeg: decl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _numberField(
            controller: _ascent,
            label: 'Ascent rate',
            suffix: 'ft / min',
            help: 'Balloon free-lift rate. Every height and speed scales with '
                'this — set it to your actual inflated rate.',
          ),
          const SizedBox(height: 16),
          _numberField(
            controller: _decl,
            label: 'Magnetic declination',
            suffix: '° East',
            help: 'Added to the compass bearing for true north. Look up your '
                'site (e.g. NOAA), East positive, West negative.',
          ),
          const SizedBox(height: 24),
          _sliderTile(
            label: 'Read interval',
            value: _s.readIntervalSec.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            display: '${_s.readIntervalSec} s',
            onChanged: (v) =>
                setState(() => _s = _s.copyWith(readIntervalSec: v.round())),
          ),
          _sliderTile(
            label: 'Warning cue lead',
            value: _s.preToneMs.toDouble(),
            min: 0,
            max: 3000,
            divisions: 6,
            display: '${(_s.preToneMs / 1000).toStringAsFixed(1)} s',
            onChanged: (v) => setState(
              () => _s = _s.copyWith(preToneMs: (v / 500).round() * 500),
            ),
          ),
          _sliderTile(
            label: 'Smoothing',
            value: _s.averaging,
            min: 0,
            max: 0.95,
            divisions: 19,
            display: _s.averaging == 0
                ? 'off'
                : _s.averaging.toStringAsFixed(2),
            onChanged: (v) =>
                setState(() => _s = _s.copyWith(averaging: v)),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              _commitText();
              Navigator.pop(context, _s);
            },
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String help,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            border: const OutlineInputBorder(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            help,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _sliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(display, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
