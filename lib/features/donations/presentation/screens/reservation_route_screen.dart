import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/providers/location_provider.dart';
import 'package:ne3ma/features/donations/data/models/reservation_route_model.dart';
import 'package:ne3ma/features/donations/providers/donation_provider.dart';

class ReservationRouteScreen extends ConsumerStatefulWidget {
  const ReservationRouteScreen({
    super.key,
    required this.reservationId,
    required this.donationTitle,
    this.meetingZone,
    this.destinationLat,
    this.destinationLng,
  });

  final String reservationId;
  final String donationTitle;
  final String? meetingZone;
  final double? destinationLat;
  final double? destinationLng;

  @override
  ConsumerState<ReservationRouteScreen> createState() =>
      _ReservationRouteScreenState();
}

class _ReservationRouteScreenState extends ConsumerState<ReservationRouteScreen> {
  ReservationRouteModel? _route;
  bool _isLoading = true;
  String? _error;
  LatLng? _userPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoute());
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(locationProvider.notifier).fetchLocation();
      final location = ref.read(locationProvider);
      final userPoint = LatLng(location.safeLat, location.safeLng);

      final route = await ref.read(donationRepositoryProvider).getRouteForReservation(
        reservationId: widget.reservationId,
        currentLat: userPoint.latitude,
        currentLng: userPoint.longitude,
      );

      if (!mounted) return;
      setState(() {
        _userPoint = userPoint;
        _route = route;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final location = ref.read(locationProvider);
      setState(() {
        _userPoint = LatLng(location.safeLat, location.safeLng);
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.destinationLat != null && widget.destinationLng != null
        ? LatLng(widget.destinationLat!, widget.destinationLng!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'Pickup Route',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: destination == null
          ? const Center(
              child: Text(
                'Donation location unavailable',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const mapHeight = 620.0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SizedBox(
                        height: mapHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryMid,
                                  ),
                                )
                              : FlutterMap(
                                  options: MapOptions(
                                    initialCenter: _centerForMap(destination),
                                    initialZoom: _route == null ? 13.5 : 12.5,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.example.ne3ma',
                                    ),
                                    if (_polylinePoints(destination).isNotEmpty)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: _polylinePoints(destination),
                                            strokeWidth: 5,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    MarkerLayer(
                                      markers: [
                                        if (_userPoint != null)
                                          Marker(
                                            point: _userPoint!,
                                            width: 54,
                                            height: 54,
                                            child: const _RouteMarker(
                                              icon: Icons.my_location_rounded,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        Marker(
                                          point: destination,
                                          width: 60,
                                          height: 60,
                                          child: const _RouteMarker(
                                            icon: Icons.location_on_rounded,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _SummaryChip(
                                  icon: Icons.route_rounded,
                                  label: _distanceText(_route?.distance),
                                ),
                                const SizedBox(width: 10),
                                _SummaryChip(
                                  icon: Icons.schedule_rounded,
                                  label: _durationText(_route?.duration),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.donationTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.meetingZone ?? 'Meeting zone',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Live route could not be loaded, showing direct path instead.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  LatLng _centerForMap(LatLng destination) {
    if (_userPoint == null) return destination;
    return LatLng(
      (_userPoint!.latitude + destination.latitude) / 2,
      (_userPoint!.longitude + destination.longitude) / 2,
    );
  }

  List<LatLng> _polylinePoints(LatLng destination) {
    final geometry = _route?.geometry;
    if (geometry != null && geometry.isNotEmpty) {
      final decoded = _decodePolyline(geometry);
      if (decoded.isNotEmpty) return decoded;
    }
    if (_userPoint != null) {
      return [_userPoint!, destination];
    }
    return [destination];
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  String _distanceText(double? rawDistance) {
    if (rawDistance == null || rawDistance <= 0) return 'Route';
    if (rawDistance >= 1000) {
      return '${(rawDistance / 1000).toStringAsFixed(1)} km';
    }
    return '${rawDistance.toStringAsFixed(0)} m';
  }

  String _durationText(double? rawDuration) {
    if (rawDuration == null || rawDuration <= 0) return 'Time';
    final totalMinutes = (rawDuration / 60).round();
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
    }
    return '$totalMinutes min';
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
