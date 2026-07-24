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
    setState(() => _loading = true);
    try {
      final data = await ApiClient.getMyBookings();
      if (mounted) setState(() => _bookings = data);
    } catch (_) {
      if (mounted) setState(() => _bookings = _demoBookings);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this booking? This cannot be undone.', style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.cancelBooking(bookingId);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.emergencyRed, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  static final List<Map<String, dynamic>> _demoBookings = [
    {
      'id': 'bk-4f91b',
      'service_name': 'Home Deep Cleaning',
      'status': 'ACCEPTED',
      'total_amount': '1,250',
      'scheduled_at': 'Today, 3:00 PM',
      'start_otp': '4920',
      'end_otp': '8103',
      'professional': {
        'name': 'Ravi Kumar',
        'phone': '+91 9812345678',
        'rating': 4.9,
        'jobs_completed': 142,
        'verification_status': 'APPROVED',
      },
    },
    {
      'id': 'bk-5a02c',
      'service_name': 'AC Repair & Servicing',
      'status': 'REQUESTED',
      'total_amount': '799',
      'scheduled_at': 'Tomorrow, 11:00 AM',
      'start_otp': null,
      'end_otp': null,
      'professional': null,
    },
    {
      'id': 'bk-3d11e',
      'service_name': 'Bathroom Tile Grouting',
      'status': 'COMPLETED',
      'total_amount': '3,500',
      'scheduled_at': 'Jul 20, 2:30 PM',
      'start_otp': null,
      'end_otp': null,
      'professional': {
        'name': 'Mohammed Salim',
        'rating': 5.0,
        'verification_status': 'APPROVED',
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('My Bookings'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(22)),
                            child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Text('No Bookings Yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('Book a service from the home page', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _BookingCard(
                        booking: _bookings[i],
                        onTap: () {
                          final b = _bookings[i];
                          final status = b['status']?.toString() ?? 'REQUESTED';
                          if (status != 'COMPLETED' && status != 'CANCELLED') {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => TrackingScreen(
                                bookingId: b['id']?.toString() ?? '',
                                serviceName: b['service_name']?.toString() ?? 'Service',
                                status: status,
                                startOtp: b['start_otp']?.toString() ?? '0000',
                                endOtp: b['end_otp']?.toString() ?? '0000',
                                totalAmount: b['total_amount']?.toString() ?? '0',
                              ),
                            ));
                          }
                        },
                        onCancel: () {
                          final b = _bookings[i];
                          final status = b['status']?.toString() ?? '';
                          if (status == 'REQUESTED' || status == 'ACCEPTED') {
                            _cancelBooking(b['id']?.toString() ?? '');
                          }
                        },
                      ),
                    ),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  const _BookingCard({required this.booking, required this.onTap, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] ?? 'REQUESTED').toString().toUpperCase();
    final pro = booking['professional'] as Map<String, dynamic>?;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'ACCEPTED':
      case 'IN_PROGRESS':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'NAVIGATING':
        statusColor = AppColors.primary;
        statusIcon = Icons.navigation_rounded;
        break;
      case 'COMPLETED':
        statusColor = AppColors.warningAmber;
        statusIcon = Icons.done_all_rounded;
        break;
      case 'CANCELLED':
        statusColor = AppColors.emergencyRed;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.textMuted;
        statusIcon = Icons.hourglass_top_rounded;
    }

    final canCancel = status == 'REQUESTED' || status == 'ACCEPTED';
    final canTrack = status == 'ACCEPTED' || status == 'NAVIGATING' || status == 'IN_PROGRESS';

    return GestureDetector(
      onTap: canTrack ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withAlpha(80)),
          boxShadow: [BoxShadow(color: statusColor.withAlpha(15), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.home_repair_service_rounded, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking['service_name']?.toString() ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(booking['scheduled_at']?.toString() ?? '', style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${booking['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withAlpha(80))),
                      child: Row(children: [
                        Icon(statusIcon, size: 10, color: statusColor),
                        const SizedBox(width: 4),
                        Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),

            // Professional details (if assigned)
            if (pro != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(pro['name']?.toString() ?? 'Professional', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12)),
                      const SizedBox(width: 6),
                      if (pro['verification_status'] == 'APPROVED') const Icon(Icons.verified_rounded, color: AppColors.primary, size: 12),
                    ]),
                    if (pro['rating'] != null) Text('⭐ ${pro['rating']}  ·  ${pro['jobs_completed'] ?? ''} jobs', style: AppText.caption),
                  ])),
                  if (pro['phone'] != null) const Icon(Icons.phone_rounded, color: AppColors.primary, size: 16),
                ]),
              ),
              const SizedBox(height: 8),
            ],

            // Action row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                if (canTrack) Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.map_rounded, color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text('Live Track', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
                if (canTrack && canCancel) const SizedBox(width: 10),
                if (canCancel) Expanded(
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: AppColors.emergencyRedSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.emergencyRedBorder)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.cancel_outlined, color: AppColors.emergencyRed, size: 16),
                        SizedBox(width: 6),
                        Text('Cancel', style: TextStyle(color: AppColors.emergencyRed, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
