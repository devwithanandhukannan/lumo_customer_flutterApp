import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_theme.dart';

class TrackingScreen extends StatefulWidget {
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

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;

  static const LatLng _proLocation = LatLng(12.9716, 77.5946);
  static const LatLng _customerLocation = LatLng(12.9783, 77.6408);

  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('pro_marker'),
      position: _proLocation,
      infoWindow: const InfoWindow(title: 'Assigned Professional (Priya Sharma)', snippet: 'Police Verified · En Route'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('customer_marker'),
      position: _customerLocation,
      infoWindow: const InfoWindow(title: 'Your Service Address', snippet: 'Kochi / Bangalore'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ),
  };

  final Set<Polyline> _polylines = {
    const Polyline(
      polylineId: PolylineId('route'),
      points: [_proLocation, LatLng(12.9750, 77.6100), LatLng(12.9770, 77.6250), _customerLocation],
      color: AppColors.primary,
      width: 5,
    ),
  };

  Color get _statusColor {
    switch (widget.status.toUpperCase()) {
      case 'REQUESTED': return AppColors.warningAmber;
      case 'ACCEPTED': return AppColors.primary;
      case 'NAVIGATING': return AppColors.primary;
      case 'IN_PROGRESS': return AppColors.successGreen;
      case 'COMPLETED': return AppColors.successGreen;
      default: return AppColors.textMuted;
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
            const Text('Active Booking Telemetry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(widget.bookingId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted)),
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
            Container(
              padding: const EdgeInsets.all(18),
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
                        child: Text(widget.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor)),
                      ),
                      Text('₹${widget.totalAmount}', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(widget.serviceName, style: AppText.heading3),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.successGreen,
                        child: Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Priya Sharma', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                          Text('Police Clear Badge · ★ 4.9 · Verified Pro', style: TextStyle(fontSize: 11, color: AppColors.successGreen)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        const Text('START JOB OTP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        Text(widget.startOtp, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 6, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Text('Share when pro arrives', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.successGreen.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        const Text('END JOB OTP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        Text(widget.endOtp, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 6, color: AppColors.successGreen)),
                        const SizedBox(height: 4),
                        const Text('Share after job done', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(12.9750, 77.6177),
                    zoom: 13,
                  ),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  markers: _markers,
                  polylines: _polylines,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
