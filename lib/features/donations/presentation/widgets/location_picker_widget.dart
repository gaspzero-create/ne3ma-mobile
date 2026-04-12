import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/location_provider.dart';

class LocationPickerWidget extends ConsumerStatefulWidget {
  const LocationPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialLat,
    this.initialLng,
    this.showHint = true,
  });

  final void Function(double lat, double lng) onLocationSelected;
  final double? initialLat;
  final double? initialLng;
  final bool showHint;

  @override
  ConsumerState<LocationPickerWidget> createState() =>
      _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends ConsumerState<LocationPickerWidget> {
  late MapController _mapController;
  late LatLng        _selectedPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final loc = ref.read(locationProvider);
    _selectedPoint = LatLng(
      widget.initialLat ?? loc.safeLat,
      widget.initialLng ?? loc.safeLng,
    );
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    debugPrint('📍 LocationPicker: Tapped ${point.latitude}, ${point.longitude}');
    setState(() => _selectedPoint = point);
    widget.onLocationSelected(point.latitude, point.longitude);
  }

  void _resetToMyLocation() {
    final loc = ref.read(locationProvider);
    final pos = LatLng(loc.safeLat, loc.safeLng);
    setState(() => _selectedPoint = pos);
    _mapController.move(pos, 15);
    widget.onLocationSelected(pos.latitude, pos.longitude);
    debugPrint('📍 LocationPicker: Reset to current location');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHint) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Tap on the map to select pickup location',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Map ───────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom:   14,
                onTap:         _onMapTap,
              ),
              children: [

                // ── OpenStreetMap tiles (free) ──────
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ne3ma',
                ),

                // ── Selected marker ─────────────────
                MarkerLayer(
                  markers: [
                    Marker(
                      point:  _selectedPoint,
                      width:  50,
                      height: 50,
                      child:  Column(
                        children: [
                          Container(
                            width:  36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:  AppColors.primary,
                              shape:  BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:     Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset:    const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size:  20,
                            ),
                          ),
                          // ── Pin tail ────────────────
                          Container(
                            width:  3,
                            height: 10,
                            color:  AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _resetToMyLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Use my current location',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Selected coords ────────────────────────
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size:  14,
              color: AppColors.primaryMid,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${_selectedPoint.latitude.toStringAsFixed(5)}, '
                '${_selectedPoint.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 12,
                  color:    AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
