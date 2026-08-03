import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  // ============================================================
  // متغیرهای نقشه
  // ============================================================
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  Set<Marker> _markers = {};
  Circle? _pulseCircle;
  bool _isLoading = true;
  bool _hasPermission = false;
  LatLng? _currentPosition;
  Timer? _pulseTimer;

  // ============================================================
  // متدهای چرخه حیات
  // ============================================================
  @override
  void initState() {
    super.initState();
    _checkPermissionAndLocation();
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ============================================================
  // بررسی دسترسی و دریافت موقعیت (معادل setupLocation در اندروید)
  // ============================================================
  Future<void> _checkPermissionAndLocation() async {
    setState(() => _isLoading = true);

    // درخواست دسترسی موقعیت
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      _hasPermission = true;
      _getCurrentLocation();
    } else if (status.isDenied) {
      _showSnackBar('⚠️ دسترسی به موقعیت رد شد. لطفاً مجوز را فعال کنید.', Colors.orange);
      setState(() => _isLoading = false);
    } else if (status.isPermanentlyDenied) {
      _showSnackBar('⚠️ دسترسی به موقعیت به طور دائم رد شده. لطفاً از تنظیمات فعال کنید.', Colors.red);
      setState(() => _isLoading = false);
      openAppSettings();
    }
  }

  // ============================================================
  // دریافت موقعیت فعلی (معادل GpsMyLocationProvider در اندروید)
  // ============================================================
  Future<void> _getCurrentLocation() async {
    try {
      // بررسی آیا موقعیت فعال است
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('⚠️ لطفاً موقعیت مکانی را روشن کنید', Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _currentPosition = LatLng(position.latitude, position.longitude);

      // تنظیم دوربین روی موقعیت فعلی (معادل mapView.getController().setCenter)
      _cameraPosition = CameraPosition(
        target: _currentPosition!,
        zoom: 18.0,
      );

      // ایجاد مارکر (معادل initMarker در اندروید)
      _createMarker(_currentPosition!);

      // ایجاد پالس (معادل initPulse در اندروید)
      _createPulseCircle(_currentPosition!);

      setState(() => _isLoading = false);

      // حرکت خودکار دوربین به موقعیت (معادل mapView.getController().setCenter)
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 18.0,
          ),
        ),
      );

      _showSnackBar('📍 موقعیت شما روی نقشه مشخص شد', Colors.green);

      // شروع دریافت موقعیت لحظه‌ای (معادل GpsMyLocationProvider.startLocationProvider)
      _startLocationUpdates();

    } catch (e) {
      _showSnackBar('❌ خطا در دریافت موقعیت: $e', Colors.red);
      setState(() => _isLoading = false);

      // موقعیت پیش‌فرض (تهران)
      _currentPosition = const LatLng(35.6892, 51.3890);
      _cameraPosition = CameraPosition(
        target: _currentPosition!,
        zoom: 12.0,
      );
      _createMarker(_currentPosition!);
      _createPulseCircle(_currentPosition!);
      setState(() {});
    }
  }

  // ============================================================
  // دریافت موقعیت لحظه‌ای (معادل GpsMyLocationProvider در اندروید)
  // ============================================================
  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // هر 3 متر تغییر موقعیت
      timeLimit: Duration(seconds: 5),
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        if (mounted) {
          _updateLocation(LatLng(position.latitude, position.longitude));
        }
      },
      onError: (error) {
        print('❌ خطا در دریافت موقعیت لحظه‌ای: $error');
      },
    );
  }

  // ============================================================
  // ایجاد مارکر (معادل initMarker در اندروید)
  // ============================================================
  void _createMarker(LatLng position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: position,
        infoWindow: const InfoWindow(
          title: '📍 موقعیت من',
          snippet: 'شما اینجا هستید',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        // برای استفاده از آیکون سفارشی:
        // icon: BitmapDescriptor.fromAssetImage(
        //   ImageConfiguration(size: Size(48, 48)),
        //   'assets/icons/ic_my_location.png',
        // ),
      ),
    );
    setState(() {});
  }

  // ============================================================
  // ایجاد پالس (موج سبز دور مارکر) - معادل PulseOverlay در اندروید
  // ============================================================
  void _createPulseCircle(LatLng position) {
    _pulseCircle = Circle(
      circleId: const CircleId('pulse_circle'),
      center: position,
      radius: 30,
      strokeWidth: 2,
      strokeColor: const Color.fromARGB(255, 46, 125, 50),
      fillColor: const Color.fromARGB(100, 46, 125, 50),
    );
    _startPulseAnimation();
  }

  // ============================================================
  // انیمیشن پالس (موج سبز متحرک) - معادل PulseOverlay.start() در اندروید
  // ============================================================
  void _startPulseAnimation() {
    double radius = 30;
    int alpha = 100;

    _pulseTimer?.cancel();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_pulseCircle == null || _currentPosition == null) {
        timer.cancel();
        return;
      }

      radius += 2;
      alpha -= 3;

      if (radius > 120 || alpha < 0) {
        radius = 30;
        alpha = 100;
      }

      _pulseCircle = Circle(
        circleId: const CircleId('pulse_circle'),
        center: _currentPosition!,
        radius: radius,
        strokeWidth: 2,
        strokeColor: Color.fromARGB(alpha, 46, 125, 50),
        fillColor: Color.fromARGB((alpha * 0.6).toInt(), 46, 125, 50),
      );

      // به‌روزرسانی نقشه
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // به‌روزرسانی موقعیت (معادل updateLocation در اندروید)
  // ============================================================
  void _updateLocation(LatLng newPosition) {
    setState(() {
      _currentPosition = newPosition;
      _createMarker(newPosition);
      _pulseCircle = Circle(
        circleId: const CircleId('pulse_circle'),
        center: newPosition,
        radius: 30,
        strokeWidth: 2,
        strokeColor: const Color.fromARGB(255, 46, 125, 50),
        fillColor: const Color.fromARGB(100, 46, 125, 50),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: newPosition, zoom: 18.0),
      ),
    );
  }

  // ============================================================
  // بازگشت به موقعیت فعلی (معادل دکمه my location در اندروید)
  // ============================================================
  void _goToCurrentLocation() async {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 18.0,
          ),
        ),
      );
      _showSnackBar('📍 بازگشت به موقعیت شما', Colors.blue);
    } else {
      _showSnackBar('⚠️ موقعیت شما یافت نشد', Colors.orange);
      _getCurrentLocation();
    }
  }

  // ============================================================
  // نمایش پیام (معادل Toast در اندروید)
  // ============================================================
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // ساخت نقشه
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '📍 موقعیت من روی نقشه',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // دکمه بروزرسانی موقعیت
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _goToCurrentLocation,
            tooltip: 'موقعیت من',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
            SizedBox(height: 16),
            Text(
              '⏳ در حال دریافت موقعیت...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          // ============================================================
          // Google Map (معادل MapView در اندروید)
          // ============================================================
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(35.6892, 51.3890),
              zoom: 15.0,
            ),
            markers: _markers,
            circles: _pulseCircle != null ? {_pulseCircle!} : {},
            myLocationEnabled: _hasPermission,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            mapType: MapType.normal,
            onCameraMove: (position) {
              // ردیابی حرکت دوربین (اختیاری)
            },
          ),

          // ============================================================
          // دکمه شناور بازگشت به موقعیت (معادل FAB در اندروید)
          // ============================================================
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              child: const Icon(Icons.my_location),
              tooltip: 'موقعیت من',
              mini: false,
              elevation: 6,
            ),
          ),

          // ============================================================
          // نشانگر موقعیت با پالس (برای شبیه‌سازی PulseOverlay در اندروید)
          // ============================================================
          if (_currentPosition != null)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '📍 شما اینجا هستید',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}