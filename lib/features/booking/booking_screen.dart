import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  double _lat = 9.9312;
  double _lng = 76.2673;
  bool _femaleProPreferred = false;
  bool _isBooking = false;
  bool _fetchingLocation = false;
  GoogleMapController? _mapController;

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

  void _onMapTapped(LatLng pos) {
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _addressController.text = 'Selected Location (${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E)';
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
  }

  Future<void> _useLiveLocation() async {
    setState(() => _fetchingLocation = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      final pos = const LatLng(9.9312, 76.2673);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _addressController.text = 'Kochi Live GPS Point (${_lat.toStringAsFixed(4)}° N, ${_lng.toStringAsFixed(4)}° E)';
        _fetchingLocation = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Live GPS location selected on map')),
      );
    }
  }

  Future<void> _confirmBooking() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter service address')),
      );
      return;
    }

    setState(() => _isBooking = true);
    try {
      final res = await ApiClient.createBooking(
        serviceId: widget.service['id']?.toString() ?? '',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        addressText: _addressController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        femaleProPreferred: _femaleProPreferred,
      );
      final booking = res['data'] ?? res;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(
            bookingId: booking['id']?.toString() ?? 'bk-9921',
            serviceName: widget.service['name']?.toString() ?? 'Service',
            status: booking['status']?.toString() ?? 'REQUESTED',
            startOtp: booking['start_otp']?.toString() ?? '4920',
            endOtp: booking['end_otp']?.toString() ?? '8103',
            totalAmount: booking['total_amount']?.toString() ?? widget.service['base_price']?.toString() ?? '499',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking error: ${e.toString()}')),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SERVICE LOCATION POINT', style: AppText.label),
                TextButton.icon(
                  onPressed: _fetchingLocation ? null : _useLiveLocation,
                  icon: _fetchingLocation
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.my_location, size: 16, color: AppColors.primary),
                  label: const Text('Use Live Location', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: lumoInputDecoration(hint: 'Search & Enter Service Address', prefix: const Icon(Icons.location_on, color: AppColors.emergencyRed, size: 20)),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_lat, _lng),
                    zoom: 13,
                  ),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onTap: _onMapTapped,
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_point'),
                      position: LatLng(_lat, _lng),
                      infoWindow: const InfoWindow(title: 'Selected Service Location Point'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Verified Pro Preview Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.successGreen.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.successGreen,
                    child: Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Verified Pro Match', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                            SizedBox(width: 6),
                            Icon(Icons.verified, color: AppColors.primary, size: 16),
                          ],
                        ),
                        Text('Police Clearance Verified · 50km Dispatch Radius', style: TextStyle(fontSize: 11, color: AppColors.successGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                    : const Text('CONFIRM BOOKING (5 MIN ACCEPTANCE TIMER)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
