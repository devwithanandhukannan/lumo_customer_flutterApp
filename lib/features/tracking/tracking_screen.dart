import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
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
  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5-minute acceptance timer
  bool _loadingRoute = true;
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _submittingReview = false;

  static const LatLng _proLocation = LatLng(12.9716, 77.5946);
  static const LatLng _customerLocation = LatLng(12.9783, 77.6408);

  List<LatLng> _roadPoints = [_proLocation, _customerLocation];

  @override
  void initState() {
    super.initState();
    _fetchRoadPolyline();
    if (widget.status.toUpperCase() == 'REQUESTED') {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _reviewController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedCountdown {
    final mins = (_secondsRemaining / 60).floor().toString().padLeft(2, '0');
    final secs = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _fetchRoadPolyline() async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_proLocation.longitude},${_proLocation.latitude};'
        '${_customerLocation.longitude},${_customerLocation.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = data['routes']?[0]?['geometry']?['coordinates'] as List?;
        if (coords != null && coords.isNotEmpty) {
          final points = coords.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
          if (mounted) {
            setState(() {
              _roadPoints = points;
              _loadingRoute = false;
            });
          }
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRoute = false);
  }

  Set<Marker> get _markers => {
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

  Set<Polyline> get _polylines => {
        Polyline(
          polylineId: const PolylineId('road_route'),
          points: _roadPoints,
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

  void _showRatingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 24, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate Your Service Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('How was your service with Priya Sharma?', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 36,
                    icon: Icon(starNum <= _selectedRating ? Icons.star : Icons.star_border, color: AppColors.warningAmber),
                    onPressed: () => setModalState(() => _selectedRating = starNum),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                style: const TextStyle(color: Colors.white),
                decoration: lumoInputDecoration(hint: 'Add feedback comment (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _submittingReview
                      ? null
                      : () async {
                          setModalState(() => _submittingReview = true);
                          try {
                            await ApiClient.submitReview(
                              bookingId: widget.bookingId,
                              rating: _selectedRating,
                              comment: _reviewController.text.trim(),
                            );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⭐ Review submitted! Thank you.')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Review error: ${e.toString()}')),
                            );
                          } finally {
                            setModalState(() => _submittingReview = false);
                          }
                        },
                  child: _submittingReview
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SUBMIT RATING & REVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportModal() {
    final reasonCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.report_problem_rounded, color: AppColors.emergencyRed, size: 22),
                  SizedBox(width: 10),
                  Text('Report Safety or Service Issue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: lumoInputDecoration(hint: 'Describe issue (e.g. Pro late, behavior, damage)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: submitting
                      ? null
                      : () async {
                          if (reasonCtrl.text.trim().isEmpty) return;
                          setModalState(() => submitting = true);
                          try {
                            await ApiClient.reportBooking(bookingId: widget.bookingId, reason: reasonCtrl.text.trim());
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🚨 Report logged & escalated to LUMO Safety Control Center.')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Report error: ${e.toString()}')),
                            );
                          } finally {
                            setModalState(() => submitting = false);
                          }
                        },
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SUBMIT SAFETY REPORT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    double minLat = _proLocation.latitude < _customerLocation.latitude ? _proLocation.latitude : _customerLocation.latitude;
    double maxLat = _proLocation.latitude > _customerLocation.latitude ? _proLocation.latitude : _customerLocation.latitude;
    double minLng = _proLocation.longitude < _customerLocation.longitude ? _proLocation.longitude : _customerLocation.longitude;
    double maxLng = _proLocation.longitude > _customerLocation.longitude ? _proLocation.longitude : _customerLocation.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.005, minLng - 0.005),
      northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: AppColors.emergencyRed),
            onPressed: _showReportModal,
            tooltip: 'Report Safety or Service Issue',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.status.toUpperCase() == 'REQUESTED') ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warningAmber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: AppColors.warningAmber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Awaiting Professional Acceptance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          Text('Matching instant request dispatch. Expires in $_formattedCountdown', style: const TextStyle(fontSize: 11, color: AppColors.warningAmber)),
                        ],
                      ),
                    ),
                    Text(_formattedCountdown, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: AppColors.warningAmber)),
                  ],
                ),
              ),
            ],
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
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.successGreen,
                        child: Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Priya Sharma', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                              SizedBox(width: 4),
                              Icon(Icons.verified, color: AppColors.primary, size: 16),
                            ],
                          ),
                          Text('Police Clear Badge · ★ 4.9 · Verified Pro', style: TextStyle(fontSize: 11, color: AppColors.successGreen)),
                        ],
                      ),
                      const Spacer(),
                      if (widget.status.toUpperCase() == 'COMPLETED')
                        IconButton(
                          icon: const Icon(Icons.star, color: AppColors.warningAmber, size: 28),
                          onPressed: _showRatingModal,
                          tooltip: 'Add Rating & Review',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL PAYABLE (BASE + TRAVEL FEE)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('₹${widget.totalAmount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.successGreen)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.successGreenSoft, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Direct Settlement', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
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
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(12.9750, 77.6177),
                        zoom: 13,
                      ),
                      onMapCreated: (ctrl) {
                        _mapController = ctrl;
                        _fitMapBounds();
                      },
                      markers: _markers,
                      polylines: _polylines,
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                    ),
                    if (_loadingRoute)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black.withAlpha(180), borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                              SizedBox(width: 8),
                              Text('Calculating exact road navigation...', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.status.toUpperCase() == 'COMPLETED') ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.star_rate, color: Colors.white),
                  label: const Text('ADD RATING & REVIEW FOR SERVICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  onPressed: _showRatingModal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
