import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/battery_status.dart';
import '../services/ble_service.dart';
import '../widgets/airpods_view.dart';

/// Main screen that displays AirPods battery status
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final BleService _bleService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeBleService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground, restart scanning if needed
        if (_isInitialized) {
          _checkBluetoothAndStartScan();
        }
        break;
      case AppLifecycleState.paused:
        // App is in background, stop scanning to save battery
        if (_isInitialized) {
          _bleService.stopScan();
        }
        break;
      default:
        break;
    }
  }

  /// Initialize the BLE service
  Future<void> _initializeBleService() async {
    print('HomeScreen: Starting BLE service initialization...');
    _bleService = BleService();
    await _bleService.initialize();
    print('HomeScreen: BLE service initialized');

    setState(() {
      _isInitialized = true;
    });

    // Check Bluetooth status and start scanning
    await _checkBluetoothAndStartScan();
    print('HomeScreen: Bluetooth check and scan start completed');
  }

  /// Check Bluetooth status and start scanning if ready
  Future<void> _checkBluetoothAndStartScan() async {
    print('HomeScreen: Checking Bluetooth and starting scan...');
    if (!_isInitialized) {
      print('HomeScreen: BLE service not initialized yet');
      return;
    }

    final isReady = await _bleService.isBluetoothReady();
    print('HomeScreen: Bluetooth ready: $isReady');

    if (isReady) {
      print('HomeScreen: Starting scan...');
      await _bleService.startScan();
      print('HomeScreen: Scan started');
    } else {
      print('HomeScreen: Bluetooth not ready, trying to turn on...');
      // Try to turn on Bluetooth on Android
      await _bleService.turnOnBluetooth();
      print('HomeScreen: Bluetooth turn on attempted');
    }
  }

  /// Handle refresh action
  Future<void> _handleRefresh() async {
    if (!_isInitialized) return;
    await _bleService.restart();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'AirPods Battery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Refresh Button
          ValueListenableBuilder<bool>(
            valueListenable: _bleService.isScanning,
            builder: (context, isScanning, child) {
              return IconButton(
                onPressed: isScanning ? null : _handleRefresh,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<BluetoothAdapterState>(
        valueListenable: _bleService.adapterState,
        builder: (context, adapterState, child) {
          // Check Bluetooth state
          if (adapterState != BluetoothAdapterState.on) {
            return _buildBluetoothOffView(adapterState);
          }

          // Bluetooth is on, show the main content
          return _buildMainContent();
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build the view when Bluetooth is off
  Widget _buildBluetoothOffView(BluetoothAdapterState state) {
    String message;
    String description;
    IconData icon;

    switch (state) {
      case BluetoothAdapterState.unavailable:
        message = 'Bluetooth Unavailable';
        description = 'This device does not support Bluetooth.';
        icon = Icons.bluetooth_disabled;
        break;
      case BluetoothAdapterState.unauthorized:
        message = 'Bluetooth Permission Required';
        description = 'Please grant Bluetooth permissions to use this app.';
        icon = Icons.bluetooth_disabled;
        break;
      case BluetoothAdapterState.off:
        message = 'Bluetooth is Off';
        description = 'Please enable Bluetooth to scan for AirPods.';
        icon = Icons.bluetooth_disabled;
        break;
      default:
        message = 'Bluetooth Status Unknown';
        description = 'Checking Bluetooth status...';
        icon = Icons.bluetooth_searching;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),

            const SizedBox(height: 24),

            Text(
              message,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            if (state == BluetoothAdapterState.off)
              ElevatedButton.icon(
                onPressed: () async {
                  await _bleService.turnOnBluetooth();
                },
                icon: const Icon(Icons.bluetooth),
                label: const Text('Enable Bluetooth'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build the main content when Bluetooth is ready
  Widget _buildMainContent() {
    return ValueListenableBuilder<AirPodsBatteryStatus>(
      valueListenable: _bleService.batteryStatus,
      builder: (context, batteryStatus, child) {
        if (batteryStatus.hasValidData) {
          // Show AirPods with battery data
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top,
                child: AirPodsView(batteryStatus: batteryStatus),
              ),
            ),
          );
        } else {
          // Show loading/scanning view
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top,
                child: const AirPodsLoadingView(),
              ),
            ),
          );
        }
      },
    );
  }

  /// Build floating action button for debug scanning
  Widget? _buildFloatingActionButton() {
    return ValueListenableBuilder<BluetoothAdapterState>(
      valueListenable: _bleService.adapterState,
      builder: (context, state, child) {
        if (state == BluetoothAdapterState.on) {
          return FloatingActionButton(
            onPressed: () async {
              await _bleService.forceScan();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manual scan triggered'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Icon(Icons.bluetooth_searching),
            tooltip: 'Force Scan',
          );
        }
        return const SizedBox.shrink(); // Return empty widget instead of null
      },
    );
  }
}
