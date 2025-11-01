import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'unlock_success_screen.dart';
import 'unlock_error_screen.dart';
import 'qr_scanner_screen.dart';
import '/widgets/app_bar_with_nav.dart';
import '/widgets/occupancy_error_dialog.dart';
import '../widgets/copa_fact_banner.dart';

// ===================  CONFIG  ===================

const String kCopaId = "copa_sta_1";

// Nordic UART Service (NUS)
const String kNusService = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
const String kNusRx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // write
const String kNusTx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // notify

// Payload (CRLF only)
final List<int> kUnlockCRLF = utf8.encode("unlock\r\n");

// Timings
const Duration kStartupDelay = Duration(milliseconds: 400);
const Duration kScanTimeout = Duration(seconds: 10);
const Duration kConnectTimeout = Duration(seconds: 10);
const Duration kNotifySettle = Duration(milliseconds: 180);
const Duration kRetryDelay1 = Duration(milliseconds: 700); // fast retry (CRLF)
const Duration kRetryDelay2 =
    Duration(milliseconds: 1500); // second retry (CRLF)

// ===================  OPTIONAL: Server ping after success  ===================

Future<void> _sendFCMTokenToServer(String copaId) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    final res = await http.post(
      Uri.parse("http://34.8.253.98:80/unlocked"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"copa_id": copaId, "fcm_token": token}),
    );
    if (res.statusCode == 200) {
      debugPrint("✅ FCM token sent");
    } else {
      debugPrint("❌ FCM send failed: ${res.body}");
    }
  } catch (e) {
    debugPrint("❌ FCM error: $e");
  }
}

// ===================  Screen  ===================

class BLEUnlockScreen extends StatefulWidget {
  final String qrData;
  const BLEUnlockScreen(this.qrData, {super.key});

  @override
  State<BLEUnlockScreen> createState() => _BLEUnlockScreenState();
}

class _BLEUnlockScreenState extends State<BLEUnlockScreen> {
  // UI
  String status = "Almost there…";

  // BLE
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rx; // write
  BluetoothCharacteristic? _tx; // notify

  // Flow guards
  bool _started = false;
  bool _isConnecting = false;

  // Subscriptions / timers
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<int>>? _txSub;
  Timer? _scanTimer;
  Timer? _connectTimer;
  Timer? _retry1;
  Timer? _retry2;
  Timer? _hardTimeout;

  // Whether any TX was observed (to cancel retries instantly)
  bool _sawAnyTx = false;

  @override
  void initState() {
    super.initState();

    // Android 14: tiny delay + listen for adapter state to avoid false "off".
    Future.delayed(kStartupDelay, _kickoff);
    _adapterSub = FlutterBluePlus.adapterState.listen((s) {
      debugPrint("🔵 adapterState: $s");
      if (s == BluetoothAdapterState.on && !_started && mounted) {
        _started = true;
        _scanForCopa();
      }
    });
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }

  // -------------------- FLOW --------------------

  Future<void> _kickoff() async {
    await _requestPermissions();

  // Use adapterState.first to check adapter status (replacement for deprecated isOn)
  final adapterState = await FlutterBluePlus.adapterState.first;
  final isOn = adapterState == BluetoothAdapterState.on;
  debugPrint("🔵 isOn: $isOn");
  if (!isOn) return _fail("Please turn ON Bluetooth to continue.");

    // Some OEMs still want Location Services ON for scans (we don't hard-fail if off)
    final locSvc = await Permission.location.serviceStatus.isEnabled;
    if (!locSvc) {
      debugPrint("⚠️ Location services OFF — scanning may fail on some OEMs.");
    }

    if (!_started) {
      _started = true;
      _scanForCopa();
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    // Safety-net for OEMs (even on A12+)
    await Permission.location.request();
  }

  // -------------------- SCAN --------------------

  Future<void> _scanForCopa() async {
    if (!mounted) return;
    setState(() => status = "Scanning for nearby COPA…");
    debugPrint("🔍 startScan");

    await FlutterBluePlus.startScan(timeout: kScanTimeout);

    _scanSub = FlutterBluePlus.scanResults.listen((batch) async {
      for (final r in batch) {
        final name = r.advertisementData.advName;
        debugPrint("• ${r.device.remoteId}  name:$name  rssi:${r.rssi}");

        // Match by name "copa" (simple & robust for now)
        if (name.toLowerCase().contains("copa")) {
          debugPrint("✅ Found COPA: ${r.device.remoteId}");
          _device = r.device;

          await FlutterBluePlus.stopScan();
          await _scanSub?.cancel();
          _scanSub = null;

          _connectToDevice();
          return;
        }
      }
    });

    _scanTimer = Timer(kScanTimeout + const Duration(seconds: 2), () async {
      if (!mounted || _device != null) return;
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
      _scanSub = null;
      _fail(
          'ESP32 not found. Make sure it\'s powered and advertising "COPA-001".');
    });
  }

  // -------------------- CONNECT & DISCOVER --------------------

  Future<void> _connectToDevice() async {
    if (_device == null || _isConnecting) return;
    _isConnecting = true;

    setState(() => status = "Connecting to COPA…");
    debugPrint("🔗 Connecting to ${_device!.remoteId}");

    _connectTimer = Timer(kConnectTimeout, () async {
      try {
        await _device?.disconnect();
      } catch (_) {}
    });

    try {
      await _device!.connect(timeout: kConnectTimeout, autoConnect: false);
      debugPrint("✅ Connected");

      // MTU boost (ignored on iOS)
      try {
        await _device!.requestMtu(247);
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (_) {}

      await _discoverNus();
    } catch (e) {
      _fail("Connection failed: $e");
    } finally {
      _connectTimer?.cancel();
      _isConnecting = false;
    }
  }

  Future<void> _discoverNus() async {
    final services = await _device!.discoverServices();
    BluetoothCharacteristic? rx;
    BluetoothCharacteristic? tx;

    for (final s in services) {
      for (final c in s.characteristics) {
        final id = c.uuid.toString().toUpperCase();
        debugPrint("   char: $id  props: "
            "R:${c.properties.read} "
            "W:${c.properties.write} "
            "WR:${c.properties.writeWithoutResponse} "
            "N:${c.properties.notify} "
            "I:${c.properties.indicate}");
        if (id == kNusRx) rx = c;
        if (id == kNusTx) tx = c;
      }
    }

    if (rx == null || tx == null) {
      return _fail("Required BLE characteristics not found (NUS RX/TX).");
    }

    _rx = rx;
    _tx = tx;

    await _enableNotifyThenSend();
  }

  // -------------------- NOTIFY, WRITE, RETRIES --------------------

  Future<void> _enableNotifyThenSend() async {
    _sawAnyTx = false;

    // 1) Subscribe to TX
      try {
      await _tx!.setNotifyValue(true);
      _txSub?.cancel();
      // Use lastValueStream (replacement for deprecated .value getter)
      _txSub = _tx!.lastValueStream.listen(_onTxData, onError: (e) {
        _fail("Notify error: $e");
      });
      debugPrint("📣 TX notify enabled");
    } catch (e) {
      return _fail("Could not enable notifications: $e");
    }

    // 2) Small settle delay
    await Future.delayed(kNotifySettle);

    // 3) Send CRLF form first (firmware likely expects line-terminated frames)
    await _writeToRx(kUnlockCRLF, label: "unlock\\r\\n");

    // 4) Fast retries ONLY if we saw no TX at all (CRLF again)
    _retry1?.cancel();
    _retry1 = Timer(kRetryDelay1, () async {
      if (!mounted || _sawAnyTx) return;
      debugPrint("🔁 Retry #1 (unlock\\r\\n) – no TX yet");
      await _writeToRx(kUnlockCRLF, label: "unlock\\r\\n");
    });

    _retry2?.cancel();
    _retry2 = Timer(kRetryDelay2, () async {
      if (!mounted || _sawAnyTx) return;
      debugPrint("🔁 Retry #2 (unlock\\r\\n) – still no TX");
      await _writeToRx(kUnlockCRLF, label: "unlock\\r\\n");
    });

    // 5) Hard stop if still nothing after ~2.5s from first write
    _hardTimeout?.cancel();
    _hardTimeout = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted || _sawAnyTx) return;
      _fail("No response from device after unlock.\n"
          "• TX notify enabled: YES\n"
          "• Sent: 'unlock\\r\\n' (+ two quick retries)\n"
          "Firmware likely didn’t notify. Ask ESP32 to call notify() on success.");
    });
  }

  Future<void> _writeToRx(List<int> payload, {required String label}) async {
    if (_rx == null) return _fail("Unlock characteristic missing.");
    setState(() => status = "Sending unlock…");
    try {
      await _rx!.write(payload, withoutResponse: false);
      debugPrint("🚪 Unlock sent ($label)");
    } catch (e) {
      _fail("Write failed ($label): $e");
    }
  }

  void _onTxData(List<int> data) {
    final msg = String.fromCharCodes(data);
    if (!mounted) return;

    // We saw a TX — cancel pending retries immediately
    _sawAnyTx = true;
    _retry1?.cancel();
    _retry2?.cancel();
    _hardTimeout?.cancel();

    // Some stacks send an empty first notify after CCCD write — ignore it.
    if (msg.isEmpty) return;

    debugPrint("📩 NUS TX: $msg");
    setState(() => status = msg);

    final lower = msg.toLowerCase();
    final looksSuccess = lower.contains("success") ||
        lower.contains("ok") ||
        (lower.contains("unlock") && !lower.contains("error")); // tolerate echo

    if (lower.contains("currently in use") || lower.contains("occupied")) {
      _showOccupancyDialog();
    } else if (looksSuccess) {
      _onSuccess();
    } else if (lower.startsWith("error") || lower.startsWith("err:")) {
      _fail(msg);
    }
  }

  // -------------------- UX helpers --------------------

  void _onSuccess() async {
    await _sendFCMTokenToServer(kCopaId);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const UnlockSuccessScreen(
          locationName: 'Main St COPA',
          lastCleaned: '10 min ago',
        ),
      ),
    );
  }

  void _showOccupancyDialog() {
    setState(() => status = "COPA seems occupied.");
    OccupancyErrorDialog.show(context);
  }

  void _fail(String message) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => UnlockErrorScreen(errorMessage: message)),
    );
  }

  void _cancelAll() {
    _scanTimer?.cancel();
    _connectTimer?.cancel();
    _retry1?.cancel();
    _retry2?.cancel();
    _hardTimeout?.cancel();
    _scanSub?.cancel();
    _adapterSub?.cancel();
    _txSub?.cancel();
    try {
      FlutterBluePlus.stopScan();
    } catch (_) {}
    try {
      _device?.disconnect();
    } catch (_) {}
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      backgroundColor: const Color(0xFF101014),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/ble_unlocking.json',
                  width: 200,
                  height: 200,
                  repeat: true,
                  errorBuilder: (_, __, ___) =>
                      const CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                Text(
                  status,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QRScannerScreen()),
                    );
                  },
                  child: const Text("Scan different QR"),
                ),
              ],
            ),
          ),
          
          // Copa fact banner at bottom with ghostie smiley (same position as QR scanner V2)
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: CopaFactBanner(),
          ),
        ],
      ),
    );
  }
}
