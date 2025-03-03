import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'unlock_success_screen.dart'; // Success screen
import 'unlock_error_screen.dart'; // Error screen
import 'qr_scanner_screen.dart'; // QR Scanner screen
import '/widgets/app_bar_with_nav.dart';

final String bleMacAddress = "AC:15:18:E9:C7:7E"; // ESP32 BLE MAC

class BLEUnlockScreen extends StatefulWidget {
  final String qrData;
  const BLEUnlockScreen(this.qrData, {super.key});

  @override
  State<BLEUnlockScreen> createState() => _BLEUnlockScreenState();
}

class _BLEUnlockScreenState extends State<BLEUnlockScreen> {
  String status = "Almost there!";
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? unlockCharacteristic;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    scanAndConnect();
  }

  void navigateToError(String message) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UnlockErrorScreen(message)),
      );
    }
  }

  void showErrorDialog(String message) {
    setState(() {
      status = "Error: COPA is currently in use.";
    });
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.66,
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning,
                        color: const Color.fromARGB(255, 214, 186, 61),
                        size: 25),
                    SizedBox(height: 20),
                    Text("Attention",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 40),
                    Text(message, textAlign: TextAlign.center),
                    SizedBox(height: 100),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => QRScannerScreen()),
                        );
                      },
                      child: Text("OK",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ));
  }

  Future<void> requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  void scanAndConnect() async {
    if (isConnecting) return;
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
        navigateToError("❌ ESP32 Not Found! Retry...");
      }
    });
  }

  void sendUnlockCommand() async {
    try {
      if (unlockCharacteristic == null) {
        navigateToError("❌ Unlock characteristic missing!");
        return;
      }
      await unlockCharacteristic!.write(utf8.encode("unlock"));
      debugPrint("🚪 Unlock command sent successfully!");
    } catch (e) {
      debugPrint("❌ Failed to send unlock command: $e");
      navigateToError("❌ Unlock Failed! Try Again.");
    }
  }

  void listenForResponses() async {
    if (unlockCharacteristic == null) return;
    unlockCharacteristic!.setNotifyValue(true);
    unlockCharacteristic!.value.listen((response) {
      String message = String.fromCharCodes(response);
      setState(() {
        status = message;
      });
      if (message.contains("currently in use")) {
        showErrorDialog(
            "Someone is inside, please try in sometime.\n There is another COPA 3 minutes from here.");
      } else if (message.contains("Success: Unlock command received")) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UnlockSuccessScreen()),
        );
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
              listenForResponses();
              sendUnlockCommand();
              return;
            }
          }
        }
        showErrorDialog("❌ Unlock characteristic not found!");
      } catch (e) {
        debugPrint("❌ Attempt $attempt failed: $e");
        if (attempt == 3) {
          navigateToError("❌ Connection Failed After 3 Attempts");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 25),
            SizedBox(
              width: 80,
              height: 80,
              child: const CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              status,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
