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

  static final List<Map<String, dynamic>> _demoBookings = [
    {
      'id': 'bk-4f91b',
      'service_name': 'Home Deep Cleaning',
      'status': 'ACCEPTED',
      'total_amount': '499',
      'scheduled_at': '2026-07-23T14:00:00Z',
      'start_otp': '4920',
      'end_otp': '8103',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('My Bookings'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _bookings.isEmpty
                  ? const Center(child: Text('No bookings yet', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final b = _bookings[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrackingScreen(
                                  bookingId: b['id']?.toString() ?? '',
                                  serviceName: b['service_name']?.toString() ?? 'Service',
                                  status: b['status']?.toString() ?? 'ACCEPTED',
                                  startOtp: b['start_otp']?.toString() ?? '4920',
                                  endOtp: b['end_otp']?.toString() ?? '8103',
                                  totalAmount: b['total_amount']?.toString() ?? '499',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withAlpha(80))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(b['service_name']?.toString() ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15))),
                                    Text('₹${b['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Row(
                                  children: [
                                    Icon(Icons.map_rounded, color: AppColors.primary, size: 14),
                                    SizedBox(width: 6),
                                    Text('Tap for Live Google Maps Telemetry', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
