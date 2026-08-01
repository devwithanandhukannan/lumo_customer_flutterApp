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

  bool _isActiveStatus(String status) {
    final s = status.toUpperCase();
    return s == 'REQUESTED' ||
        s == 'ACCEPTED' ||
        s == 'ACCEPTED_PAYMENT_PENDING' ||
        s == 'CONFIRMED' ||
        s == 'NAVIGATING' ||
        s == 'ARRIVED' ||
        s == 'IN_PROGRESS' ||
        s == 'START_OTP_VERIFIED';
  }

  List<dynamic> get _activeBookings =>
      _bookings.where((b) => _isActiveStatus((b['status'] ?? '').toString())).toList();

  List<dynamic> get _historyBookings =>
      _bookings.where((b) => !_isActiveStatus((b['status'] ?? '').toString())).toList();

  void _openTrackingScreen(Map<String, dynamic> b) {
    final status = (b['status'] ?? 'REQUESTED').toString().toUpperCase();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingScreen(
          bookingId: b['id']?.toString() ?? '',
          serviceName: b['service_name']?.toString() ?? 'Service',
          status: status,
          startOtp: b['start_otp']?.toString() ?? '0000',
          endOtp: b['end_otp']?.toString() ?? '0000',
          totalAmount: b['total_amount']?.toString() ?? '0',
        ),
      ),
    ).then((_) => _load());
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking Request?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.', style: AppText.body),
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

  Future<void> _reportIssue(String bookingId) async {
    final controller = TextEditingController();
    bool reporting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: AppColors.emergencyRed),
              SizedBox(width: 8),
              Text('Report Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Describe the issue experienced during this service:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: lumoInputDecoration(hint: 'Enter details (e.g. late arrival, incomplete service)'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
              onPressed: reporting
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setDialogState(() => reporting = true);
                      try {
                        await ApiClient.reportBooking(bookingId: bookingId, reason: controller.text.trim());
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ Report submitted to LUMO Safety Control Center')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      } finally {
                        setDialogState(() => reporting = false);
                      }
                    },
              child: reporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  static final List<Map<String, dynamic>> _demoBookings = [
    {
      'id': 'bk-4f91b',
      'service_name': 'Home Deep Cleaning',
      'status': 'ACCEPTED_PAYMENT_PENDING',
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

  Widget _buildBookingList(List<dynamic> list, {required bool isActiveTab}) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(22)),
                  child: Icon(
                    isActiveTab ? Icons.sensors_rounded : Icons.history_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isActiveTab ? 'No Active Bookings' : 'No Booking History',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  isActiveTab ? 'Your active service requests will appear here' : 'Completed and past service history',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final b = list[i];
        final bookingId = b['id']?.toString() ?? '';
        final status = (b['status'] ?? '').toString();
        final canCancel = status.toUpperCase() == 'REQUESTED' || status.toUpperCase() == 'ACCEPTED';

        return _BookingCard(
          booking: b,
          isActive: isActiveTab,
          onTap: () => _openTrackingScreen(b),
          onCancel: canCancel ? () => _cancelBooking(bookingId) : null,
          onReport: () => _reportIssue(bookingId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: 'Refresh Bookings',
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('⚡ Live & Active (${_activeBookings.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('📜 History (${_historyBookings.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: _buildBookingList(_activeBookings, isActiveTab: true),
                  ),
                  RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: _buildBookingList(_historyBookings, isActiveTab: false),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback onReport;

  const _BookingCard({
    required this.booking,
    required this.isActive,
    required this.onTap,
    this.onCancel,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] ?? 'REQUESTED').toString().toUpperCase();
    final proName = booking['pro_name'] ?? booking['professional']?['name'];
    final proRating = booking['pro_rating'] ?? booking['professional']?['rating'];

    Color statusColor;
    IconData statusIcon;
    String statusDisplayText = status;

    switch (status) {
      case 'REQUESTED':
        statusColor = AppColors.warningAmber;
        statusIcon = Icons.hourglass_top_rounded;
        statusDisplayText = 'AWAITING PRO';
        break;
      case 'ACCEPTED':
      case 'ACCEPTED_PAYMENT_PENDING':
        statusColor = AppColors.primary;
        statusIcon = Icons.bolt_rounded;
        statusDisplayText = 'PRO ACCEPTED · PAY FEE';
        break;
      case 'CONFIRMED':
        statusColor = AppColors.primary;
        statusIcon = Icons.check_circle_rounded;
        statusDisplayText = 'CONFIRMED & DISPATCHED';
        break;
      case 'NAVIGATING':
      case 'ARRIVED':
        statusColor = AppColors.primary;
        statusIcon = Icons.navigation_rounded;
        statusDisplayText = 'PRO EN ROUTE';
        break;
      case 'IN_PROGRESS':
      case 'START_OTP_VERIFIED':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.play_circle_fill_rounded;
        statusDisplayText = 'JOB IN PROGRESS';
        break;
      case 'COMPLETED':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.done_all_rounded;
        statusDisplayText = 'COMPLETED';
        break;
      case 'CANCELLED':
      case 'EXPIRED':
        statusColor = AppColors.emergencyRed;
        statusIcon = Icons.cancel_rounded;
        statusDisplayText = status;
        break;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.info_outline_rounded;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: isActive ? 4 : 1,
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive ? statusColor.withAlpha(120) : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Service Icon, Name, Date, Amount, Status Badge
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: statusColor.withAlpha(24), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.home_repair_service_rounded, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['service_name']?.toString() ?? 'Service',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking['scheduled_at']?.toString() ?? '',
                          style: AppText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${booking['total_amount']}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 10, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusDisplayText,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Assigned Professional snippet
              if (proName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(proName.toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 12),
                              ],
                            ),
                            if (proRating != null) Text('⭐ $proRating · Verified Professional', style: AppText.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Interactive Action Bar
              Row(
                children: [
                  // Primary Action Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? AppColors.primary : AppColors.surface,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: isActive ? 2 : 0,
                      ),
                      icon: Icon(
                        isActive ? Icons.sensors_rounded : Icons.info_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isActive
                            ? (status == 'ACCEPTED_PAYMENT_PENDING' ? 'PAY PLATFORM FEE & TRACK' : 'OPEN TELEMETRY & TRACK')
                            : 'VIEW DETAILS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),

                  // Optional Cancel / Report buttons
                  if (onCancel != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emergencyRed,
                        side: BorderSide(color: AppColors.emergencyRed.withAlpha(80)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: onReport,
                    tooltip: 'Report Issue',
                    icon: const Icon(Icons.flag_outlined, color: AppColors.textMuted, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
