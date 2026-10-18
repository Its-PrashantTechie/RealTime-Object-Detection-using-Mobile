import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'detect_screen.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  PermissionStatus? _status;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final status = await Permission.camera.status;
      if (!mounted) return;
      setState(() => _status = status);
      if (status.isGranted || status.isLimited) {
        return;
      }
      if (status.isDenied && !_requesting) {
        await _request();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = PermissionStatus.denied);
    }
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = PermissionStatus.denied);
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null || _requesting) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (status.isGranted || status.isLimited) {
      return const DetectScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(Icons.videocam_outlined, size: 56),
              const SizedBox(height: 20),
              Text(
                'Camera access needed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                status.isPermanentlyDenied
                    ? 'Camera permission is turned off. Enable it in system settings, then return to Live Detect.'
                    : 'Live Detect identifies everyday objects (person, phone, bottle, car, and more) on your camera feed. Nothing is uploaded.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: status.isPermanentlyDenied
                      ? openAppSettings
                      : _request,
                  child: Text(
                    status.isPermanentlyDenied
                        ? 'Open settings'
                        : 'Allow camera',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
