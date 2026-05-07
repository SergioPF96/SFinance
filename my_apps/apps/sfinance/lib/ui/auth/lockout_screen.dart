import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import '../../providers/auth_provider.dart';

class LockoutScreen extends ConsumerStatefulWidget {
  const LockoutScreen({super.key});

  @override
  ConsumerState<LockoutScreen> createState() => _LockoutScreenState();
}

class _LockoutScreenState extends ConsumerState<LockoutScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final authState = ref.read(authProvider);
    if (authState is! AuthStateLockedOut) {
      _timer?.cancel();
      return;
    }
    final remaining = authState.expiresAt.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      ref.read(authProvider.notifier).clearLockout();
    } else {
      setState(() => _remaining = remaining);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Too many wrong PINs',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Please wait before trying again.'),
            const SizedBox(height: 24),
            Text(
              _format(_remaining),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }
}
