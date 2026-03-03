import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:http/http.dart' as http;
import 'sqlite_helper.dart';

const syncTask = "com.maritime.syncTask";
const serverEndpoint = "https://your-admin-dashboard.com/api/webhook/location";
const String deviceId = "VESSEL_ALPHA_001"; // Typically fetched securely

// Entry point for the Workmanager background isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncTask) {
        await performLocationSync();
      }
      return Future.value(true);
    } catch (err) {
      print("Background task failed: $err");
      return Future.value(false); // Retries based on workmanager policy
    }
  });
}

Future<void> performLocationSync() async {
  // 1. Harvest Hardware Data
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  int batteryLevel = await Battery().batteryLevel;
  String timestamp = DateTime.now().toUtc().toIso8601String();

  Map<String, dynamic> currentPayload = {
    "device_id": deviceId,
    "timestamp": timestamp,
    "latitude": position.latitude,
    "longitude": position.longitude,
    "battery": batteryLevel,
  };

  // 2. Fetch any pending payloads that failed while offline
  List<Map<String, dynamic>> pendingQueue = 
      await DatabaseHelper.instance.getPendingPayloads();
  
  // Combine pending queue with the new current payload
  List<Map<String, dynamic>> payloadsToSend = [...pendingQueue, currentPayload];

  // 3. Attempt Sync to Server
  bool syncSuccessful = await _uploadToServer(payloadsToSend);

  if (syncSuccessful) {
    // 4. Success! Clear the queue.
    await DatabaseHelper.instance.clearQueue();
    // (Optional) Save 'last sync time' to SharedPreferences to update UI
  } else {
    // 5. Offline or Server Error! Save ONLY the new payload to local DB for next time.
    await DatabaseHelper.instance.insertPayload(currentPayload);
  }
}

Future<bool> _uploadToServer(List<Map<String, dynamic>> batch) async {
  try {
    final response = await http.post(
      Uri.parse(serverEndpoint),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer YOUR_SECURE_TOKEN"},
      body: jsonEncode({"batch": batch}),
    ).timeout(const Duration(seconds: 15));

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    // Catch SocketExceptions (No Internet) or timeouts
    return false;
  }
}

// Call this from main.dart to initialize the background job
void initializeBackgroundTracking() {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  
  Workmanager().registerPeriodicTask(
    "1",
    syncTask,
    frequency: const Duration(minutes: 30),
    constraints: Constraints(
      networkType: NetworkType.not_required, // Will run even offline to cache!
      requiresBatteryNotLow: true,           // Protects device battery
    ),
  );
}
