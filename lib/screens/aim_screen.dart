import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/orientation_service.dart';
import '../theme.dart';

/// Full-screen camera preview with a crosshair and live azimuth/elevation, to
/// help aim the phone precisely at the balloon. Falls back to a plain reticle
/// if no camera is available (e.g. web/desktop).
class AimScreen extends StatefulWidget {
  final OrientationService orient;

  const AimScreen({super.key, required this.orient});

  @override
  State<AimScreen> createState() => _AimScreenState();
}

class _AimScreenState extends State<AimScreen> {
  CameraController? _cam;
  String? _camError;
  AzEl? _live;
  StreamSubscription<AzEl>? _sub;

  @override
  void initState() {
    super.initState();
    _live = widget.orient.latest;
    _sub = widget.orient.stream.listen((v) {
      if (mounted) setState(() => _live = v);
    });
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _camError = 'No camera on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _cam = controller);
    } catch (e) {
      if (mounted) setState(() => _camError = 'Camera unavailable: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _cam;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Aim'),
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cam != null && cam.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: cam.value.previewSize?.height ?? 1,
                height: cam.value.previewSize?.width ?? 1,
                child: CameraPreview(cam),
              ),
            )
          else
            Center(
              child: Text(
                _camError ?? 'Starting camera…',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          CustomPaint(painter: _ReticlePainter(), child: const SizedBox.expand()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: _readout(),
          ),
        ],
      ),
    );
  }

  Widget _readout() {
    final live = _live;
    final style = kMonoLarge.copyWith(fontSize: 34, color: Colors.white);
    Widget cell(String label, String value) => Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value, style: style),
          ],
        );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          cell('AZ °T', live == null ? '—' : live.azimuth.toStringAsFixed(0)),
          cell('EL °', live == null ? '—' : live.elevation.toStringAsFixed(0)),
        ],
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, 26, p);
    const gap = 8.0, arm = 22.0;
    canvas.drawLine(c.translate(-gap - arm, 0), c.translate(-gap, 0), p);
    canvas.drawLine(c.translate(gap, 0), c.translate(gap + arm, 0), p);
    canvas.drawLine(c.translate(0, -gap - arm), c.translate(0, -gap), p);
    canvas.drawLine(c.translate(0, gap), c.translate(0, gap + arm), p);
    canvas.drawCircle(c, 1.5, p..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => false;
}
