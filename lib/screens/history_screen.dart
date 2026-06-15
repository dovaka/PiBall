import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/wind_profile.dart';
import '../services/csv_export.dart';
import '../services/history_store.dart';
import '../services/units.dart';
import '../widgets/wind_profile_chart.dart';

class HistoryScreen extends StatefulWidget {
  final UnitSystem unitSystem;

  const HistoryScreen({super.key, required this.unitSystem});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WindProfile>? _profiles;

  Units get _u => Units(widget.unitSystem);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await HistoryStore.load();
    if (mounted) setState(() => _profiles = list);
  }

  String _when(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _profiles;
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: profiles == null
          ? const Center(child: CircularProgressIndicator())
          : profiles.isEmpty
              ? const Center(child: Text('No saved profiles yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: profiles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _tile(profiles[i]),
                ),
    );
  }

  Widget _tile(WindProfile p) {
    final top = p.layers.isNotEmpty ? p.layers.last : null;
    return Card(
      child: ListTile(
        title: Text(_when(p.timestampMs)),
        subtitle: Text(
          '${p.layers.length} layers'
          '${top != null ? ' · top ${_u.speedLabel(top.speedKts)} from ${top.headingDeg.toStringAsFixed(0)}°' : ''}',
        ),
        onTap: () => _showDetail(p),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'share') {
              await shareProfile(p, _u);
            } else if (v == 'delete') {
              await HistoryStore.delete(p.timestampMs);
              await _reload();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'share', child: Text('Share CSV')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _showDetail(WindProfile p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(_when(p.timestampMs),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            WindProfileChart(layers: p.layers, units: _u),
            const SizedBox(height: 12),
            for (final l in p.layers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_u.heightLabel(l.heightFt)),
                    Text('${l.headingDeg.toStringAsFixed(0)}°'),
                    Text(_u.speedLabel(l.speedKts)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => shareProfile(p, _u),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share CSV'),
            ),
          ],
        ),
      ),
    );
  }
}
