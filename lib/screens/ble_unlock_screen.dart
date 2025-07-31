import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'unlock_success_screen.dart';
import 'unlock_error_screen.dart';
import 'qr_scanner_screen.dart';
import '/widgets/app_bar_with_nav.dart';
import '/widgets/occupancy_error_dialog.dart';
import '../widgets/copa_fact_banner.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

final String bleMacAddress = "AC:15:18:E9:C7:7E";
final String copa_id = "copa_sta_1";

Future<void> sendFCMTokenToServer(String copaId) async {
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    final String url = "http://34.8.253.98:80/unlocked";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"copa_id": copaId, "fcm_token": fcmToken}),
    );
    if (response.statusCode == 200) {
      print("✅ FCM Token Sent After Unlock!");
    } else {
      print("❌ Failed to Send FCM Token: \${response.body}");
    }
  } else {
    print("❌ Could not retrieve FCM token.");
  }
}

class BLEUnlockScreen extends StatefulWidget {
  final String qrData;
  const BLEUnlockScreen(this.qrData, {super.key});

  @override
  State<BLEUnlockScreen> createState() => _BLEUnlockScreenState();
}

class _BLEUnlockScreenState extends State<BLEUnlockScreen> {
  String status = "Almost there!";
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? rxCharacteristic; // for sending commands
  BluetoothCharacteristic? txCharacteristic; // for receiving responses
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

  void showErrorDialog() {
    setState(() {
      status = "Error: COPA is currently in use.";
    });
    OccupancyErrorDialog.show(context);
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
    debugPrint("🔍 Scanning for ESP32 (\$bleMacAddress)...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        final localName = result.advertisementData.advName ?? "";
        debugPrint(
            "🔍 Found device: ${result.device.remoteId}, Name: $localName");

        if (localName.toLowerCase().contains("copa")) {
          debugPrint("✅ Found COPA device! Connecting...");
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
      if (rxCharacteristic == null) {
        navigateToError("❌ Unlock characteristic missing!");
        return;
      }
      await rxCharacteristic!.write(utf8.encode("unlock"));
      debugPrint("🚪 Unlock command sent successfully!");
    } catch (e) {
      debugPrint("❌ Failed to send unlock command: \$e");
      navigateToError("❌ Unlock Failed! Try Again.");
    }
  }

  void listenForResponses(BluetoothCharacteristic txChar) async {
    try {
      await txChar.setNotifyValue(true);
      txChar.value.listen((response) {
        String message = String.fromCharCodes(response);
        debugPrint("📩 Received: $message");

        setState(() {
          status = message;
        });

        if (message.contains("currently in use")) {
          showErrorDialog();
        } else if (message.contains("Success")) {
          sendFCMTokenToServer(copa_id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const UnlockSuccessScreen()),
          );
        }
      });
    } catch (e) {
      debugPrint("❌ Failed to listen for responses: $e");
      navigateToError("❌ Could not subscribe to notifications");
    }
  }

  Future<void> connectToDevice() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint("🔗 Attempt \$attempt to connect to ESP32...");
        await targetDevice!.connect();
        debugPrint("✅ Connected to ESP32!");

        List<BluetoothService> services =
            await targetDevice!.discoverServices();
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            final uuid = characteristic.uuid.toString().toUpperCase();

            if (uuid == "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
              rxCharacteristic = characteristic; // For sending commands
              debugPrint("✍️ RX characteristic found (write)");
            } else if (uuid == "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") {
              txCharacteristic = characteristic; // For receiving responses
              debugPrint("📣 TX characteristic found (notify)");
            }
          }
        }

        if (rxCharacteristic != null && txCharacteristic != null) {
          listenForResponses(txCharacteristic!);
          sendUnlockCommand();
          return;
        } else {
          navigateToError("❌ Required BLE characteristics not found!");
        }
      } catch (e) {
        debugPrint("❌ Attempt \$attempt failed: \$e");
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
      backgroundColor: const Color(0xFF101014),
      body: Stack(
        children: [
          const CopaFactBanner(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/ble_unlocking.json',
                  width: 200,
                  height: 200,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
