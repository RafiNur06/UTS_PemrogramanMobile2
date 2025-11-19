import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:geolocator/geolocator.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  String _locationName = 'Lokasi Anda';

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('id_ID', null);
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      // Cek dan minta izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Buka pengaturan untuk mengizinkan.');
      }

      // Dapatkan posisi saat ini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Koordinat lokasi
      final myCoordinates = Coordinates(position.latitude, position.longitude);

      // PERBAIKAN UTAMA: Gunakan metode perhitungan Kemenag (Indonesia)
      // dan timezone yang benar
      final params = CalculationMethod.singapore.getParameters();
      params.madhab = Madhab.shafi;
      
      // Untuk Indonesia, tambahkan penyesuaian waktu jika diperlukan
      // Bandung biasanya menggunakan offset +7 dari UTC
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      
      // Hitung waktu shalat dengan timezone lokal
      final prayerTimes = PrayerTimes(
        myCoordinates,
        DateComponents.from(now),
        params,
        utcOffset: offset,
      );

      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
        _locationName = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak bisa mendapatkan lokasi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFFFFE4E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '🕌 Jadwal Shalat Hari Ini',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B9D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _locationName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Prayer Times List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Memuat jadwal shalat... 🌙',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _prayerTimes == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 80,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Tidak bisa memuat jadwal 😢',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    'Pastikan GPS aktif dan izin lokasi diberikan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    _loadPrayerTimes();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Color(0xFFFF6B9D),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildPrayerCard(
                                'Subuh',
                                _prayerTimes!.fajr,
                                Icons.wb_twilight,
                                Color(0xFF9C27B0),
                              ),
                              _buildPrayerCard(
                                'Terbit',
                                _prayerTimes!.sunrise,
                                Icons.wb_sunny,
                                Color(0xFFFF9800),
                              ),
                              _buildPrayerCard(
                                'Dzuhur',
                                _prayerTimes!.dhuhr,
                                Icons.light_mode,
                                Color(0xFFFFC107),
                              ),
                              _buildPrayerCard(
                                'Ashar',
                                _prayerTimes!.asr,
                                Icons.wb_cloudy,
                                Color(0xFF2196F3),
                              ),
                              _buildPrayerCard(
                                'Maghrib',
                                _prayerTimes!.maghrib,
                                Icons.wb_twilight,
                                Color(0xFFFF5722),
                              ),
                              _buildPrayerCard(
                                'Isya',
                                _prayerTimes!.isha,
                                Icons.nightlight_round,
                                Color(0xFF3F51B5),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(String name, DateTime time, IconData icon, Color color) {
    final timeString = DateFormat('HH:mm').format(time);
    final now = DateTime.now();
    
    // Cek apakah waktu shalat saat ini sedang aktif
    // (dalam rentang 30 menit sebelum dan sesudah waktu shalat)
    final isActive = now.isAfter(time.subtract(const Duration(minutes: 30))) &&
        now.isBefore(time.add(const Duration(minutes: 30)));

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [color, color.withOpacity(0.7)]
              : [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.3) : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 35,
                color: isActive ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : color,
                    ),
                  ),
                  if (isActive)
                    Text(
                      '✨ Waktunya Shalat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}