import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/battery_status.dart';

/// Service for handling Bluetooth Low Energy scanning for AirPods
class BleService {
  // Apple's company ID for manufacturer data
  static const int appleCompanyId = 0x004C;

  // Reactive properties for UI updates
  final ValueNotifier<AirPodsBatteryStatus> batteryStatus = ValueNotifier(
    AirPodsBatteryStatus.unknown(),
  );
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  final ValueNotifier<BluetoothAdapterState> adapterState = ValueNotifier(
    BluetoothAdapterState.unknown,
  );

  // Private properties
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  Timer? _scanTimeout;

  /// Initialize the BLE service
  Future<void> initialize() async {
    print('BleService: Starting initialization...');

    if (!await FlutterBluePlus.isSupported) {
      print('BleService: Bluetooth not supported!');
      developer.log(
        'Bluetooth not supported by this device',
        name: 'BleService',
      );
      return;
    }

    print('BleService: Bluetooth is supported');

    // Set log level for debugging
    if (kDebugMode) {
      print('BleService: Setting debug log level');
      FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
    }

    // Listen to adapter state changes
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      print('BleService: Adapter state changed: $state');
      developer.log('Adapter state changed: $state', name: 'BleService');
      adapterState.value = state;

      if (state == BluetoothAdapterState.on) {
        print('BleService: Bluetooth is ON - starting scan');
        developer.log('Bluetooth is ON - starting scan', name: 'BleService');
        startScan(); // Auto-start scanning when Bluetooth is ready
      } else {
        print('BleService: Bluetooth is OFF - stopping scan');
        developer.log('Bluetooth is OFF - stopping scan', name: 'BleService');
        stopScan(); // Stop scanning if Bluetooth is turned off
      }
    });

    // Get initial adapter state
    adapterState.value = await FlutterBluePlus.adapterState.first;
    print('BleService: Initial adapter state: ${adapterState.value}');
    developer.log(
      'Initial adapter state: ${adapterState.value}',
      name: 'BleService',
    );

    // If Bluetooth is already on, start scanning immediately
    if (adapterState.value == BluetoothAdapterState.on) {
      print('BleService: Bluetooth already ON - starting initial scan');
      developer.log(
        'Bluetooth already ON - starting initial scan',
        name: 'BleService',
      );
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay
      startScan();
    }
  }

  /// Check if Bluetooth is enabled and ready
  Future<bool> isBluetoothReady() async {
    return adapterState.value == BluetoothAdapterState.on;
  }

  /// Turn on Bluetooth (Android only)
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      developer.log('Failed to turn on Bluetooth: $e', name: 'BleService');
    }
  }

  /// Start scanning for AirPods
  Future<void> startScan() async {
    print('BleService: startScan() called');

    if (!(await isBluetoothReady())) {
      print('BleService: Bluetooth not ready');
      developer.log('Bluetooth not ready', name: 'BleService');
      return;
    }

    if (isScanning.value) {
      print('BleService: Already scanning');
      developer.log('Already scanning', name: 'BleService');
      return;
    }

    try {
      print('BleService: Starting scan...');

      // Stop any existing scan
      await stopScan();

      // Reset battery status to unknown
      batteryStatus.value = AirPodsBatteryStatus.unknown();

      // Start scanning
      isScanning.value = true;
      print('BleService: Setting scan to active');

      // Set up scan subscription with comprehensive logging
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          print('BleService: Received ${results.length} scan results');

          for (final r in results) {
            final manufacturerData = r.advertisementData.manufacturerData;

            // Log ALL devices we find for debugging
            if (manufacturerData.isNotEmpty) {
              print(
                'BleService: Found device ${r.device.remoteId} with manufacturer data: ${manufacturerData.entries.map((e) => "${e.key}: ${e.value.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}").join(", ")}',
              );
            }

            // Check for Apple's manufacturer ID (0x004C = 76 decimal)
            if (manufacturerData.containsKey(appleCompanyId)) {
              final data = manufacturerData[appleCompanyId];

              print(
                'BleService: Found Apple device: ${r.device.remoteId} with data: ${data?.map((e) => e.toRadixString(16).padLeft(2, "0")).join(" ")}',
              );
              print(
                'BleService: Data length: ${data?.length}, RSSI: ${r.rssi}dB',
              );

              // Basic validation - must have enough data for AirPods
              if (data == null || data.length < 16) {
                print(
                  'BleService: Apple device data too short: ${data?.length}',
                );
                continue;
              }

              // Try to parse as AirPods data
              try {
                _parseAirPodsData(data, r.rssi);
              } catch (e) {
                print('BleService: Error parsing AirPods data: $e');
              }
            }
          }
        },
        onError: (error) {
          print('BleService: Scan error: $error');
          developer.log('Scan error: $error', name: 'BleService');
        },
      );

      // Start the actual scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidScanMode: AndroidScanMode.lowLatency,
      );

      print('BleService: Scan started successfully');
      developer.log('Scan started successfully', name: 'BleService');

      // Auto-restart scan for continuous updates
      _setupAutoRestart();
    } catch (e, stackTrace) {
      print('BleService: Failed to start scan: $e');
      isScanning.value = false;
      developer.log(
        'Failed to start scan: $e',
        name: 'BleService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Parse AirPods data from manufacturer data
  void _parseAirPodsData(List<int> data, int rssi) {
    print(
      'BleService: Parsing AirPods data: ${data.map((e) => e.toRadixString(16).padLeft(2, "0")).join(" ")}',
    );

    // Parse the data according to the protocol
    final isFlipped = (data[10] & 0x02) == 0;

    // Extract battery levels and charging status
    final leftData = data[isFlipped ? 12 : 13];
    final rightData = data[isFlipped ? 13 : 12];
    final caseData = data[15];

    // Convert raw battery values to percentages
    final leftBattery = _convertRawToBatteryLevel(leftData);
    final rightBattery = _convertRawToBatteryLevel(rightData);
    final caseBattery = _convertRawToBatteryLevel(caseData);

    // Extract charging status (bit field)
    final chargeStatus = data[14];
    final leftCharging = (chargeStatus & 0x01) != 0;
    final rightCharging = (chargeStatus & 0x02) != 0;
    final caseCharging = (chargeStatus & 0x04) != 0;

    print(
      'BleService: Parsed - Left: $leftBattery%, Right: $rightBattery%, Case: $caseBattery%',
    );
    print(
      'BleService: Charging - Left: $leftCharging, Right: $rightCharging, Case: $caseCharging',
    );

    // Update battery status
    batteryStatus.value = AirPodsBatteryStatus(
      leftPod: leftBattery,
      rightPod: rightBattery,
      caseBattery: caseBattery,
      isLeftCharging: leftCharging,
      isRightCharging: rightCharging,
      isCaseCharging: caseCharging,
    );

    developer.log(
      'AirPods found - L:${leftBattery == -1 ? "N/A" : "$leftBattery%"} '
      'R:${rightBattery == -1 ? "N/A" : "$rightBattery%"} '
      'C:${caseBattery == -1 ? "N/A" : "$caseBattery%"}',
      name: 'BleService',
    );
  }

  /// Convert raw battery value to percentage
  int _convertRawToBatteryLevel(int rawValue) {
    // Handle special case where 0xF (15) means "not available/disconnected"
    if (rawValue == 15) {
      return -1; // Use -1 to indicate "not available"
    }

    // Convert 0-10 range to 0-100 percentage
    return (rawValue * 10).clamp(0, 100);
  }

  /// Set up auto-restart for continuous scanning
  void _setupAutoRestart() {
    _scanTimeout = Timer(const Duration(seconds: 3), () {
      if (isScanning.value) {
        print('BleService: Auto-restarting scan for real-time updates');
        developer.log(
          'Auto-restarting scan for real-time updates',
          name: 'BleService',
        );
        startScan(); // Restart scan when timeout occurs
      }
    });
  }

  /// Stop scanning for AirPods
  Future<void> stopScan() async {
    print('BleService: Stopping scan');
    _scanSubscription?.cancel();
    _scanTimeout?.cancel();
    isScanning.value = false;

    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      developer.log('Error stopping scan: $e', name: 'BleService');
    }
  }

  /// Force scan (for manual testing)
  Future<void> forceScan() async {
    print('BleService: Force scan requested');
    await stopScan();
    await startScan();
  }

  /// Restart the BLE service
  Future<void> restart() async {
    await stopScan();
    await startScan();
  }

  /// Check Bluetooth permissions and start scanning if ready
  Future<void> checkAndStartScan() async {
    if (await isBluetoothReady()) {
      await startScan();
    } else {
      await turnOnBluetooth();
    }
  }

  /// Dispose of resources
  void dispose() {
    stopScan();
    _adapterStateSubscription?.cancel();
    batteryStatus.dispose();
    isScanning.dispose();
    adapterState.dispose();
  }
}
