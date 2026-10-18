import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/core/yolo_model_manager.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  final YOLOViewController _controller = YOLOViewController();

  late final String _modelId;
  StreamSubscription<DownloadProgress>? _downloadSub;

  double _confidence = 0.4;
  int _detectionCount = 0;
  double _fps = 0;
  bool _modelReady = false;
  bool _torchOn = false;
  String? _error;
  double _downloadFraction = 0;

  @override
  void initState() {
    super.initState();
    _modelId = YOLO.defaultOfficialModel() ?? 'yolo26n';
    _downloadSub = YOLOModelManager.downloadProgress.listen((progress) {
      if (!mounted) return;
      setState(() => _downloadFraction = progress.fraction);
    });
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  Future<void> _onConfidenceChanged(double value) async {
    setState(() => _confidence = value);
    await _controller.setConfidenceThreshold(value);
  }

  Future<void> _flipCamera() async {
    await _controller.switchCamera();
    _controller.resetTorchState();
    if (mounted) {
      setState(() => _torchOn = _controller.isTorchEnabled);
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) {
      setState(() => _torchOn = _controller.isTorchEnabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          YOLOView(
            modelPath: _modelId,
            task: YOLOTask.detect,
            controller: _controller,
            cameraResolution: '720p',
            confidenceThreshold: 0.4,
            onResult: (results) {
              if (!mounted) return;
              if (_detectionCount != results.length) {
                setState(() => _detectionCount = results.length);
              }
            },
            onPerformanceMetrics: (metrics) {
              if (!mounted) return;
              if ((metrics.fps - _fps).abs() >= 0.4) {
                setState(() => _fps = metrics.fps);
              }
            },
            onModelLoad: (path, task) {
              if (!mounted) return;
              setState(() {
                _modelReady = true;
                _error = null;
              });
            },
            onModelError: (error, path, task) {
              if (!mounted) return;
              setState(() {
                _modelReady = false;
                _error = error.toString();
              });
            },
          ),
          const _TopScrim(),
          const _BottomScrim(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _TopBar(
                    count: _detectionCount,
                    fps: _fps,
                    ready: _modelReady,
                  ),
                  const Spacer(),
                  _BottomBar(
                    confidence: _confidence,
                    torchOn: _torchOn,
                    onConfidenceChanged: _onConfidenceChanged,
                    onFlip: _flipCamera,
                    onTorch: _toggleTorch,
                  ),
                ],
              ),
            ),
          ),
          if (!_modelReady && _error == null) _LoadingOverlay(fraction: _downloadFraction),
          if (_error != null) _ErrorOverlay(message: _error!),
        ],
      ),
    );
  }
}

class _TopScrim extends StatelessWidget {
  const _TopScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC000000), Color(0x00000000)],
            ),
          ),
          child: SizedBox(height: 160, width: double.infinity),
        ),
      ),
    );
  }
}

class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xE6000000), Color(0x00000000)],
            ),
          ),
          child: SizedBox(height: 220, width: double.infinity),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.count,
    required this.fps,
    required this.ready,
  });

  final int count;
  final double fps;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Live Detect',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        _Chip(label: ready ? '${fps.toStringAsFixed(0)} FPS' : '…'),
        const SizedBox(width: 8),
        _Chip(label: '$count objects'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.confidence,
    required this.torchOn,
    required this.onConfidenceChanged,
    required this.onFlip,
    required this.onTorch,
  });

  final double confidence;
  final bool torchOn;
  final ValueChanged<double> onConfidenceChanged;
  final VoidCallback onFlip;
  final VoidCallback onTorch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text('Confidence', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: confidence,
                min: 0.25,
                max: 0.75,
                onChanged: onConfidenceChanged,
              ),
            ),
            Text(
              confidence.toStringAsFixed(2),
              style: const TextStyle(fontSize: 12, fontFeatures: [
                FontFeature.tabularFigures(),
              ]),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RoundButton(
              icon: Icons.flip_camera_android,
              label: 'Flip',
              onPressed: onFlip,
            ),
            _RoundButton(
              icon: torchOn ? Icons.flash_on : Icons.flash_off,
              label: 'Torch',
              selected: torchOn,
              onPressed: onTorch,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white12,
            foregroundColor: Colors.white,
            minimumSize: const Size(56, 56),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).clamp(0, 100).toStringAsFixed(0);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Preparing YOLO on this phone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              fraction > 0
                  ? 'Downloading model $percent% (one-time, then offline)'
                  : 'Loading detector…',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load the detector.\nNeed internet the first time so YOLO can download.\n\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4),
          ),
        ),
      ),
    );
  }
}
