import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../tracking/tracking_screen.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool femaleProPreferred;

  const BookingScreen({
    super.key,
    required this.service,
    this.femaleProPreferred = false,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _addressController = TextEditingController(text: 'Kochi, Kerala, India');
  bool _femaleProPreferred = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _femaleProPreferred = widget.femaleProPreferred;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      final res = await ApiClient.createBooking(
        serviceId: widget.service['id']?.toString() ?? '',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        addressText: _addressController.text.trim(),
        latitude: 9.9312,
        longitude: 76.2673,
        femaleProPreferred: _femaleProPreferred,
      );
      final booking = res['data'] ?? res;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(
            bookingId: booking['id']?.toString() ?? 'BKG-9921',
            serviceName: widget.service['name']?.toString() ?? 'Service',
            status: booking['status']?.toString() ?? 'ACCEPTED',
            startOtp: booking['start_otp']?.toString() ?? '4920',
            endOtp: booking['end_otp']?.toString() ?? '8103',
            totalAmount: booking['total_amount']?.toString() ?? widget.service['base_price']?.toString() ?? '499',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(
            bookingId: 'BKG-9921',
            serviceName: widget.service['name']?.toString() ?? 'Service',
            status: 'ACCEPTED',
            startOtp: '4920',
            endOtp: '8103',
            totalAmount: widget.service['base_price']?.toString() ?? '499',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.service['base_price']?.toString() ?? '0';
    final name = widget.service['name']?.toString() ?? 'Service';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Book Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.service['icon']?.toString() ?? '🔧', style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  Text(name, style: AppText.heading2),
                  const SizedBox(height: 8),
                  Text('₹$price', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('SERVICE ADDRESS', style: AppText.label),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: lumoInputDecoration(hint: 'Address', prefix: const Icon(Icons.location_on, color: AppColors.emergencyRed, size: 20)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Female Professional Preferred', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                  Switch(value: _femaleProPreferred, activeTrackColor: AppColors.primary, activeThumbColor: Colors.white, onChanged: (v) => setState(() => _femaleProPreferred = v)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isBooking
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('CONFIRM BOOKING (50KM DISPATCH)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
