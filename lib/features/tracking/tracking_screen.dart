import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TrackingScreen extends StatelessWidget {
  final String bookingId;
  final String serviceName;
  final String status;
  final String startOtp;
  final String endOtp;
  final String totalAmount;

  const TrackingScreen({
    super.key,
    required this.bookingId,
    required this.serviceName,
    required this.status,
    required this.startOtp,
    required this.endOtp,
    required this.totalAmount,
  });

  Color get _statusColor {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return AppColors.warningAmber;
      case 'ACCEPTED':
        return AppColors.primary;
      case 'NAVIGATING':
        return AppColors.primary;
      case 'IN_PROGRESS':
        return AppColors.successGreen;
      case 'COMPLETED':
        return AppColors.successGreen;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(bookingId,
                style: const TextStyle(
                    fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: _statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _statusColor)),
                          ],
                        ),
                      ),
                      Text('₹$totalAmount',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(serviceName, style: AppText.heading3),
                  const SizedBox(height: 16),
                  // Provider info
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF10B981),
                        child: Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Priya Sharma',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 15)),
                          Text('Police Verified · ★ 4.9 · 142 jobs',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.successGreen)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // OTP Cards
            Row(
              children: [
                Expanded(
                  child: _OtpCard(
                    label: 'START JOB OTP',
                    otp: startOtp,
                    color: AppColors.primary,
                    subtitle: 'Share when pro arrives',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OtpCard(
                    label: 'END JOB OTP',
                    otp: endOtp,
                    color: AppColors.successGreen,
                    subtitle: 'Share after job done',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Live Map Placeholder
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined, color: AppColors.textMuted, size: 40),
                    const SizedBox(height: 8),
                    const Text('Live GPS tracking',
                        style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Provider ETA: ~12 minutes',
                        style: AppText.caption.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Safety note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emergencyRedSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.emergencyRedBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.emergencyRed, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Emergency SOS button available at bottom. Tap once to broadcast your location to our Safety Control Center.',
                      style: TextStyle(color: AppColors.emergencyRed, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpCard extends StatelessWidget {
  final String label;
  final String otp;
  final Color color;
  final String subtitle;

  const _OtpCard({
    required this.label,
    required this.otp,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(otp,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: color)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
