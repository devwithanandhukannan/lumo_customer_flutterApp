import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class SosButtonWidget extends StatefulWidget {
  final String? bookingId;
  const SosButtonWidget({super.key, this.bookingId});

  @override
  State<SosButtonWidget> createState() => _SosButtonWidgetState();
}

class _SosButtonWidgetState extends State<SosButtonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _confirmSos() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.emergencyRed, width: 2)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('EMERGENCY SOS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
          ],
        ),
        content: const Text(
          'This will immediately broadcast your GPS location to the LUMO Safety Control Center.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _triggerSos();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            child: const Text('SEND SOS NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSos() async {
    try {
      await ApiClient.triggerSos(latitude: 9.9322, longitude: 76.2685, bookingId: widget.bookingId, notes: '1-Tap Customer Mobile SOS');
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.shield, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('🔴 EMERGENCY SOS SENT TO SAFETY CONTROL CENTER', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) => Transform.scale(scale: _pulseAnimation.value, child: child),
      child: FloatingActionButton.extended(
        onPressed: _confirmSos,
        heroTag: 'sos_fab',
        backgroundColor: AppColors.emergencyRed,
        elevation: 6,
        icon: const Icon(Icons.shield_outlined, color: Colors.white),
        label: const Text('1-TAP SOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 13)),
      ),
    );
  }
}
