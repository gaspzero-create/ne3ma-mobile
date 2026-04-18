import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final double? lat;
  final double? lng;
  final bool isLoading;
  final String? error;

  const LocationState({this.lat, this.lng, this.isLoading = false, this.error});

  bool get hasLocation => lat != null && lng != null;
  double get safeLat => lat ?? 35.193279; // Sidi Bel Abbes fallback
  double get safeLng => lng ?? -0.630094;

  LocationState copyWith({
    double? lat,
    double? lng,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  Future<void> fetchLocation() async {
    debugPrint('📍 LocationProvider: Fetching...');
    state = state.copyWith(isLoading: true, error: null);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ LocationProvider: Denied forever — using fallback');
        state = state.copyWith(isLoading: false, error: 'Permission denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      debugPrint('✅ LocationProvider: ${pos.latitude}, ${pos.longitude}');
      state = state.copyWith(
        isLoading: false,
        lat:
            35.193279, // Hardcoded for Sidi Bel Abbes testing (was pos.latitude)
        lng:
            -0.630094, // Hardcoded for Sidi Bel Abbes testing (was pos.longitude)
      );
    } catch (e) {
      debugPrint('❌ LocationProvider: $e — using fallback');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Called from map picker ──────────────────────
  void setManualLocation(double lat, double lng) {
    debugPrint('📍 LocationProvider: Manual set = $lat, $lng');
    state = state.copyWith(lat: lat, lng: lng);
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);
