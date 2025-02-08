import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

final String bleMacAddress = "AC:15:18:E9:C7:7E"; // ESP32 BLE MAC

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const QRScannerScreen(),
      theme: ThemeData(primarySwatch: Colors.lightBlue),
    );
  }
}

// 📸 QR Code Scanner with Button
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool showScanner = false;
  MobileScannerController scannerController = MobileScannerController();

  void _resetScanner() {
    setState(() {
      showScanner = false;
      scannerController = MobileScannerController(); // Reset the scanner
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SmartPotty")),
      body: Center(
        child: showScanner
            ? MobileScanner(
                controller: scannerController,
                onDetect: (BarcodeCapture barcodeCapture) {
                  final Barcode? barcode = barcodeCapture.barcodes.first;
                  final String? code = barcode?.rawValue;

                  if (code != null) {
                    debugPrint("✅ QR Code Scanned: $code");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BLEUnlockScreen(code),
                      ),
                    ).then(
                        (_) => _resetScanner()); // Reset scanner after return
                  } else {
                    debugPrint("❌ No valid QR code detected.");
                  }
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Press the button below to scan a QR code.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showScanner = true; // Show the camera scanner
                      });
                    },
                    child: const Text("Scan QR Code"),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }
}

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
          break;
        }
      }
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (targetDevice == null) {
        setState(() => status = "❌ ESP32 Not Found! Retry...");
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

        setState(() => status = "❌ Unlock characteristic not found!");
      } catch (e) {
        debugPrint("❌ Attempt $attempt failed: $e");
        if (attempt == 3) {
          setState(() => status = "❌ Connection Failed After 3 Attempts");
          debugPrint("❌ Giving up after 3 attempts.");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void sendUnlockCommand() async {
    try {
      await unlockCharacteristic!.write(utf8.encode("unlock"));
      debugPrint("🚪 Unlock command sent successfully!");

      if (targetDevice != null) {
        await targetDevice!.disconnect();
        debugPrint("🔌 Disconnected from ESP32!");
      }

      if (mounted) {
        // Navigate to Success Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UnlockSuccessScreen()),
        );
      }

      // // Navigate back to the main screen
      // if (mounted) {
      //   Navigator.popUntil(context, (route) => route.isFirst);
      // }
    } catch (e) {
      setState(() => status = "❌ Unlock Failed! Try Again.");
      debugPrint("❌ Failed to send unlock command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unlock Porta Potty")),
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

// 🎉 Unlock Success Screen
class UnlockSuccessScreen extends StatelessWidget {
  const UnlockSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🚪 Door Unlocked Successfully!",
              style: TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QRScannerScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
