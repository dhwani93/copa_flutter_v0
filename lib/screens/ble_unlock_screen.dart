import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'unlock_success_screen.dart'; // Success screen
import 'unlock_error_screen.dart'; // Error screen

final String bleMacAddress = "AC:15:18:E9:C7:7E"; // ESP32 BLE MAC

// 🔑 BLE Unlock Screen
class BLEUnlockScreen extends StatefulWidget {
  final String qrData;
  const BLEUnlockScreen(this.qrData, {super.key});

  @override
  State<BLEUnlockScreen> createState() => _BLEUnlockScreenState();
}

class _BLEUnlockScreenState extends State<BLEUnlockScreen> {
  String status = "Unlocking...";
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? unlockCharacteristic;
  bool isConnecting = false; // Prevent multiple scans

  @override
  void initState() {
    super.initState();
    scanAndConnect();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  void scanAndConnect() async {
    if (isConnecting) return; // Prevent multiple scans
    isConnecting = true;

    await requestPermissions();
    debugPrint("🔍 Scanning for ESP32 ($bleMacAddress)...");

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.remoteId.toString().toUpperCase() == bleMacAddress) {
          debugPrint("✅ Found ESP32! Connecting...");
          targetDevice = result.device;
          FlutterBluePlus.stopScan();
          connectToDevice();
          return;
        }
      }
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && targetDevice == null) {
        _navigateToError("❌ ESP32 Not Found! Retry...");
      }
    });
  }

  Future<void> connectToDevice() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint("🔗 Attempt $attempt to connect to ESP32...");
        await targetDevice!.connect();
        debugPrint("✅ Connected to ESP32!");

        List<BluetoothService> services =
            await targetDevice!.discoverServices();
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString() ==
                "abcd5678-1234-5678-1234-abcdef987654") {
              unlockCharacteristic = characteristic;
              debugPrint("🔑 Unlock characteristic found!");
              sendUnlockCommand();
              return;
            }
          }
        }
        _navigateToError("❌ Unlock characteristic not found!");
      } catch (e) {
        debugPrint("❌ Attempt $attempt failed: $e");
        if (attempt == 3) {
          _navigateToError("❌ Connection Failed After 3 Attempts");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void sendUnlockCommand() async {
    try {
      if (unlockCharacteristic == null) {
        _navigateToError("❌ Unlock characteristic missing!");
        return;
      }

      await unlockCharacteristic!.write(utf8.encode("unlock"));
      debugPrint("🚪 Unlock command sent successfully!");

      if (targetDevice != null) {
        await targetDevice!.disconnect();
        debugPrint("🔌 Disconnected from ESP32!");
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UnlockSuccessScreen()),
        );
      }
    } catch (e) {
      debugPrint("❌ Failed to send unlock command: $e");
      _navigateToError("❌ Unlock Failed! Try Again.");
    }
  }

  void _navigateToError(String message) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UnlockErrorScreen(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unlock Porta Potty"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the home screen
          },
        ),
      ),
      body: Center(
        child: Text(
          status,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
