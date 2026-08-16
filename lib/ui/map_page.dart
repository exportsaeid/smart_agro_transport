import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(35.6892, 51.3890); // تهران پیش‌فرض
  bool _isLoading = true;
  bool _locationReady = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStream;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
    _initLocation();
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ۱. سرویس لوکیشن روشن باشد
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'سرویس موقعیت مکانی خاموش است.\nلطفاً GPS را روشن کنید.';
        });
        return;
      }

      // ۲. مجوز
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'مجوز موقعیت مکانی رد شد.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'مجوز برای همیشه رد شده.\nاز تنظیمات گوشی فعال کنید.';
        });
        return;
      }

      // ۳. گرفتن موقعیت فعلی (سریع)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationReady = true;
        _isLoading = false;
      });

      // کمی صبر تا نقشه آماده شود بعد حرکت
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _mapController.move(_currentLocation, 16.0);
      }

      // ۴. استریم زنده (مثل نسخه اندروید)
      _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // هر ۵ متر یک‌بار
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'خطا در دریافت موقعیت:\n$e';
        });
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📍 موقعیت روی نقشه',
          style: TextStyle(fontFamily: 'Tahoma', color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              minZoom: 5,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // مهم: User-Agent واقعی (مثل اندروید)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_agro_transport',
                maxNativeZoom: 19,
                // اگر OSM کند بود می‌توانید از این استفاده کنید:
                // urlTemplate: 'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
              ),

              // پالس سبز اطراف موقعیت
              if (_locationReady)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentLocation,
                          radius: 18 + (32 * _pulseAnimation.value),
                          color: Colors.green.withOpacity(0.25 * (1 - _pulseAnimation.value)),
                          borderColor: Colors.green.withOpacity(0.4 * (1 - _pulseAnimation.value)),
                          borderStrokeWidth: 2,
                          useRadiusInMeter: false,
                        ),
                      ],
                    );
                  },
                ),

              // مارکر موقعیت
              if (_locationReady)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // لودینگ
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'در حال دریافت موقعیت...',
                      style: TextStyle(color: Colors.white, fontFamily: 'Tahoma'),
                    ),
                  ],
                ),
              ),
            ),

          // پیام خطا
          if (_errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: Colors.red[700],
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Tahoma',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          if (_errorMessage!.contains('همیشه')) {
                            Geolocator.openAppSettings();
                          } else if (_errorMessage!.contains('خاموش')) {
                            Geolocator.openLocationSettings();
                          } else {
                            _initLocation();
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        child: const Text('تلاش مجدد / تنظیمات', style: TextStyle(fontFamily: 'Tahoma')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        onPressed: () {
          if (_locationReady) {
            _mapController.move(_currentLocation, 16.0);
          } else {
            _initLocation();
          }
        },
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}