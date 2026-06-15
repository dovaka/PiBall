import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_settings.dart';
import '../models/reading.dart';
import '../models/wind_layer.dart';
import '../models/wind_profile.dart';
import '../services/csv_export.dart';
import '../services/cue.dart';
import '../services/history_store.dart';
import '../services/orientation_service.dart';
import '../services/settings_store.dart';
import '../services/units.dart';
import '../services/wind_calculator.dart';
import '../theme.dart';
import '../widgets/wind_profile_chart.dart';
import 'aim_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppSettings _settings = const AppSettings();
  final OrientationService _orient = OrientationService();
  StreamSubscription<AzEl>? _orientSub;

  AzEl? _live;
  double _avgAz = 0, _avgEl = 0;

  final List<Reading> _readings = [];
  List<WindLayer> _results = const [];
  bool _saved = false;
  bool _showChart = false;

  bool _running = false;
  bool _starting = false;
  DateTime? _launchTime;
  DateTime? _nextRead;
  DateTime? _nextWarn;
  int _lastCount = -1;
  Timer? _ticker;

  Units get _u => Units(_settings.units);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orient.start();
    _orientSub = _orient.stream.listen(
      (azEl) => setState(() => _live = azEl),
      onError: (_) {}, // sensor hiccups shouldn't crash the run
    );
    SettingsStore.load().then((s) {
      setState(() {
        _settings = s;
        _orient.declinationDeg = s.declinationDeg;
        Cue.voice = s.voiceCues;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _setWakelock(false);
    _orientSub?.cancel();
    _orient.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The OS drops the wakelock when we're backgrounded; re-assert on resume
    // if a run is still in progress.
    if (state == AppLifecycleState.resumed && _running) {
      _setWakelock(true);
    }
  }

  Duration get _interval => Duration(seconds: _settings.readIntervalSec);

  void _setWakelock(bool on) {
    (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((_) {});
  }

  // --- Recording state machine -------------------------------------------

  void _start() {
    setState(() {
      _readings.clear();
      _results = const [];
      _saved = false;
      _showChart = false;
      _running = true;
      _starting = true;
      _avgAz = _live?.azimuth ?? 0;
      _avgEl = _live?.elevation ?? 0;
      _lastCount = -1;
    });
    final lead = Duration(milliseconds: _settings.preToneMs);
    final launch = DateTime.now().add(lead * 2);
    _nextRead = launch;
    _nextWarn = launch.subtract(lead);
    _ticker = Timer.periodic(const Duration(milliseconds: 100), _onTick);
    _setWakelock(true);
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    _setWakelock(false);
    setState(() => _running = false);
  }

  void _reset() {
    setState(() {
      _readings.clear();
      _results = const [];
      _saved = false;
      _showChart = false;
      _launchTime = null;
    });
  }

  Future<void> _calculate() async {
    final results = computeWinds(_readings, _settings.ascentRateFtPerMin);
    setState(() => _results = results);
    if (results.isEmpty || _saved) return;
    _saved = true;

    double? lat, lon;
    try {
      final pos = await Geolocator.getLastKnownPosition();
      lat = pos?.latitude;
      lon = pos?.longitude;
    } catch (_) {
      // no location — save without it
    }
    await HistoryStore.add(_profile(results, lat, lon));
  }

  WindProfile _profile(List<WindLayer> layers, double? lat, double? lon) {
    return WindProfile(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      ascentRateFtPerMin: _settings.ascentRateFtPerMin,
      readings: List.of(_readings),
      layers: layers,
      lat: lat,
      lon: lon,
    );
  }

  void _captureNow() {
    if (!_running) return;
    _doRead(DateTime.now());
    setState(() {});
  }

  void _deleteReading(int index) {
    setState(() {
      _readings.removeAt(index);
      _results = _results.isEmpty
          ? const []
          : computeWinds(_readings, _settings.ascentRateFtPerMin);
      _saved = false;
    });
  }

  void _onTick(Timer _) {
    final live = _live;
    if (live != null) {
      final a = _settings.averaging;
      if (a > 0 && a < 1) {
        _avgAz = smoothAngleDeg(_avgAz, live.azimuth, a);
        _avgEl = a * _avgEl + (1 - a) * live.elevation;
      } else {
        _avgAz = live.azimuth;
        _avgEl = live.elevation;
      }
    }

    final now = DateTime.now();

    if (_nextRead != null) {
      final secs = _nextRead!.difference(now).inMilliseconds / 1000.0;
      for (final n in [3, 2, 1]) {
        if (secs <= n && secs > n - 1 && _lastCount != n) {
          Cue.count(n);
          _lastCount = n;
          break;
        }
      }
    }

    if (_nextWarn != null && !now.isBefore(_nextWarn!)) {
      Cue.warn();
      _nextWarn = _nextWarn!.add(_interval);
    }
    if (_nextRead != null && !now.isBefore(_nextRead!)) {
      _doRead(now);
      _nextRead = _nextRead!.add(_interval);
      _lastCount = -1;
    }
    setState(() {});
  }

  void _doRead(DateTime now) {
    Cue.read();
    final double t;
    if (_starting) {
      _starting = false;
      _launchTime = now;
      t = 0;
      _avgAz = _live?.azimuth ?? _avgAz;
      _avgEl = _live?.elevation ?? _avgEl;
    } else {
      t = now.difference(_launchTime!).inMilliseconds / 1000.0;
    }
    _readings.add(Reading(t, _avgAz, _avgEl));
  }

  Future<void> _shareCurrent() async {
    await shareProfile(_profile(_results, null, null), _u);
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(settings: _settings)),
    );
    if (updated == null) return;
    await SettingsStore.save(updated);
    setState(() {
      _settings = updated;
      _orient.declinationDeg = updated.declinationDeg;
      Cue.voice = updated.voiceCues;
    });
  }

  // --- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PiBall'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AimScreen(orient: _orient)),
            ),
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Aim',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HistoryScreen(unitSystem: _settings.units)),
            ),
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
          IconButton(
            onPressed: _running ? null : _openSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _liveCard(),
            if (_live != null && !isFieldPlausible(_live!.fieldUT))
              _calibrationBanner(),
            const SizedBox(height: 12),
            _statusRow(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (_readings.isNotEmpty || _running) _observationsCard(),
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _resultsCard(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _liveCard() {
    final live = _live;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _bigReadout('AZIMUTH',
                  live == null ? '—' : live.azimuth.toStringAsFixed(0), '°T'),
            ),
            Container(
                width: 1, height: 64, color: Theme.of(context).dividerColor),
            Expanded(
              child: _bigReadout('ELEVATION',
                  live == null ? '—' : live.elevation.toStringAsFixed(0), '°'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigReadout(String label, String value, String unit) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: kMonoLarge.copyWith(fontSize: 52, color: scheme.onSurface),
            children: [
              TextSpan(text: value),
              TextSpan(
                  text: unit,
                  style:
                      TextStyle(fontSize: 22, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _calibrationBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Compass interference — move away from metal/electronics and '
              'wave the phone in a figure-8 to recalibrate.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow() {
    final String label;
    final IconData icon;
    if (_running) {
      final secs = _nextRead == null
          ? 0
          : _nextRead!.difference(DateTime.now()).inMilliseconds / 1000.0;
      final next = secs > 0 ? secs.ceil() : 0;
      label = _starting
          ? 'Aim at the balloon — launch in ${next}s'
          : 'Recording · next sighting in ${next}s';
      icon = Icons.fiber_manual_record;
    } else if (_readings.isEmpty) {
      label = 'Ready';
      icon = Icons.adjust;
    } else {
      label = '${_readings.length} sightings captured';
      icon = Icons.check_circle_outline;
    }
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: _running ? scheme.error : scheme.primary),
        const SizedBox(width: 8),
        Expanded(
            child:
                Text(label, style: Theme.of(context).textTheme.titleSmall)),
        if (_running)
          TextButton.icon(
            onPressed: _captureNow,
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('Capture'),
          ),
      ],
    );
  }

  Widget _observationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Observations',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _obsHeader(),
            const Divider(),
            for (var i = 0; i < _readings.length; i++)
              _obsRow(i, _readings[i]),
            if (_running)
              _pendingRow(),
          ],
        ),
      ),
    );
  }

  Widget _obsHeader() {
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Row(
      children: [
        Expanded(flex: 2, child: Text('#', style: style)),
        Expanded(flex: 3, child: Text('TIME (s)', style: style)),
        Expanded(flex: 3, child: Text('AZ (°T)', style: style)),
        Expanded(flex: 3, child: Text('EL (°)', style: style)),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _obsRow(int i, Reading r) {
    final style = kMonoLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('${i + 1}', style: style)),
          Expanded(flex: 3, child: Text(r.time.toStringAsFixed(0), style: style)),
          Expanded(flex: 3, child: Text(r.az.toStringAsFixed(1), style: style)),
          Expanded(flex: 3, child: Text(r.el.toStringAsFixed(1), style: style)),
          SizedBox(
            width: 40,
            child: _running
                ? const SizedBox.shrink()
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () => _deleteReading(i),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Delete sighting',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _pendingRow() {
    final base = kMonoLarge.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('•', style: base)),
          Expanded(flex: 3, child: Text(_starting ? '—' : '…', style: base)),
          Expanded(flex: 3, child: Text(_avgAz.toStringAsFixed(1), style: base)),
          Expanded(flex: 3, child: Text(_avgEl.toStringAsFixed(1), style: base)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _resultsCard() {
    final scheme = Theme.of(context).colorScheme;
    final hasLowEl = _results.any((l) => l.lowElevation);
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Winds aloft',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: scheme.onPrimaryContainer,
                  onPressed: () => setState(() => _showChart = !_showChart),
                  icon: Icon(_showChart ? Icons.table_rows : Icons.show_chart),
                  tooltip: _showChart ? 'Show table' : 'Show chart',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  color: scheme.onPrimaryContainer,
                  onPressed: _shareCurrent,
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Share CSV',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_showChart)
              WindProfileChart(layers: _results, units: _u)
            else
              _resultsTable(scheme),
            if (hasLowEl) ...[
              const SizedBox(height: 8),
              Text('* low elevation — unreliable',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.error, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultsTable(ColorScheme scheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _resHead('HEIGHT')),
            Expanded(child: _resHead('FROM')),
            Expanded(child: _resHead('SPEED')),
          ],
        ),
        Divider(color: scheme.onPrimaryContainer.withValues(alpha: 0.3)),
        for (final w in _results)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(child: _resCell(_u.heightLabel(w.heightFt), w.lowElevation)),
                Expanded(
                    child: _resCell(
                        '${w.headingDeg.toStringAsFixed(0)}°${w.lowElevation ? ' *' : ''}',
                        w.lowElevation)),
                Expanded(child: _resCell(_u.speedLabel(w.speedKts), w.lowElevation)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _resHead(String t) => Text(
        t,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer
                .withValues(alpha: 0.8),
            letterSpacing: 1.1),
      );

  Widget _resCell(String t, bool lowEl) => Text(
        t,
        style: kMonoLarge.copyWith(
          fontSize: 16,
          color: lowEl
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );

  Widget _bottomBar() {
    final String label;
    final VoidCallback onTap;
    final bool danger;
    if (_running) {
      label = 'Stop';
      onTap = _stop;
      danger = true;
    } else if (_readings.isEmpty) {
      label = 'Start';
      onTap = _start;
      danger = false;
    } else {
      label = 'Calculate';
      onTap = _calculate;
      danger = false;
    }

    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onTap,
                style: danger
                    ? FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError)
                    : null,
                child: Text(label),
              ),
            ),
            if (!_running && _readings.isNotEmpty) ...[
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 60)),
                child: const Text('Reset'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
