import 'package:flutter/material.dart';
import 'background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeBackgroundTracking();
  runApp(const MaritimeApp());
}

class MaritimeApp extends StatelessWidget {
  const MaritimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vessel Tracker',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A192F), // Deep Navy
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF8F9FA)), // Clean White
          bodyMedium: TextStyle(color: Color(0xFFF8F9FA)),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF00E5FF), // Ocean Cyan
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHIP SYSTEMS', style: TextStyle(letterSpacing: 2.0)),
        backgroundColor: const Color(0xFF112240), // Matte Dark
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.satellite_alt, size: 80, color: Color(0xFF00E5FF)),
            const SizedBox(height: 20),
            const Text('TRACKING ACTIVE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
            const SizedBox(height: 40),
            // Huge manual SOS button
            ElevatedButton(
              onPressed: () {
                // Instantly trigger performLocationSync()
                performLocationSync();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('MANUAL PING / SOS', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
