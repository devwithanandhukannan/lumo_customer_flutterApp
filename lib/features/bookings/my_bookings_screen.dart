import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../tracking/tracking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await ApiClient.getMyBookings();
      if (mounted) setState(() => _bookings = data);
    } catch (e) {
      if (mounted) {
        setState(() {
          // Fallback demo bookings
          _bookings = _demoBookings;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static final List<Map<String, dynamic>> _demoBookings = [
    {
      'id': 'bk-4f91b',
      'service_name': 'Home Deep Cleaning',
      'status': 'COMPLETED',
      'total_amount': '499',
      'scheduled_at': '2026-07-20T14:00:00Z',
      'start_otp': '4920',
      'end_otp': '8103',
    },
    {
      'id': 'bk-8c23d',
      'service_name': 'Electrical Wiring',
      'status': 'IN_PROGRESS',
      'total_amount': '599',
      'scheduled_at': '2026-07-23T10:00:00Z',
      'start_otp': '7411',
      'end_otp': '5392',
    },
    {
      'id': 'bk-1a75e',
      'service_name': 'Plumbing Repair',
      'status': 'REQUESTED',
      'total_amount': '349',
      'scheduled_at': '2026-07-25T16:00:00Z',
      'start_otp': '2819',
      'end_otp': '6047',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: _bookings.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: AppColors.textMuted, size: 48),
                          SizedBox(height: 12),
                          Text('No bookings yet',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 6),
                          Text('Book a service to see it here',
                              style: AppText.caption),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          _BookingCard(booking: _bookings[i]),
                    ),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final dynamic booking;
  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch ((booking['status'] as String? ?? '').toUpperCase()) {
      case 'COMPLETED':
        return AppColors.successGreen;
      case 'IN_PROGRESS':
        return AppColors.primary;
      case 'NAVIGATING':
        return AppColors.primary;
      case 'ACCEPTED':
        return AppColors.warningAmber;
      case 'REQUESTED':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] as String? ?? '').toUpperCase();
    final isActive =
        status == 'IN_PROGRESS' || status == 'NAVIGATING' || status == 'ACCEPTED';

    return GestureDetector(
      onTap: isActive
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackingScreen(
                    bookingId: booking['id']?.toString() ?? '',
                    serviceName: booking['service_name']?.toString() ?? 'Service',
                    status: status,
                    startOtp: booking['start_otp']?.toString() ?? '----',
                    endOtp: booking['end_otp']?.toString() ?? '----',
                    totalAmount: booking['total_amount']?.toString() ?? '0',
                  ),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary.withAlpha(80) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking['service_name']?.toString() ?? 'Service',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 6),
                Text(booking['id']?.toString() ?? '',
                    style: AppText.caption.copyWith(fontFamily: 'monospace')),
                const Spacer(),
                Text('₹${booking['total_amount']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 15)),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.touch_app, color: AppColors.primary, size: 14),
                  SizedBox(width: 6),
                  Text('Tap to track',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
