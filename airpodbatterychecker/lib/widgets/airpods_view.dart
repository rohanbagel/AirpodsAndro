import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../models/battery_status.dart';

/// Widget that displays a 3D AirPods model with battery information overlay
class AirPodsView extends StatelessWidget {
  final AirPodsBatteryStatus batteryStatus;

  const AirPodsView({super.key, required this.batteryStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade100, Colors.grey.shade200],
        ),
      ),
      child: Stack(
        children: [
          // 3D Model Viewer
          _build3DModel(),

          // Battery Information Overlay
          _buildBatteryOverlay(context),
        ],
      ),
    );
  }

  /// Build the 3D model viewer
  Widget _build3DModel() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 400,
        margin: const EdgeInsets.all(20),
        child: const ModelViewer(
          backgroundColor: Colors.transparent,
          src: 'assets/models/airpods.glb',
          alt: 'A 3D model of AirPods Pro',
          ar: false, // Disable AR for simplicity
          autoRotate: true,
          autoRotateDelay: 1000,
          rotationPerSecond: '30deg',
          interactionPrompt: InteractionPrompt.none,
          cameraControls: true,
          disableZoom: false,
          shadowIntensity: 1.0,
          shadowSoftness: 0.5,
          autoPlay: true,
        ),
      ),
    );
  }

  /// Build the battery information overlay
  Widget _buildBatteryOverlay(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          // Top spacing
          const SizedBox(height: 60),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'AirPods Pro Battery Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          // Battery status cards
          _buildBatteryCards(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Build battery status cards
  Widget _buildBatteryCards(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left AirPod
          _buildBatteryCard(
            'Left AirPod',
            batteryStatus.leftPod,
            batteryStatus.isLeftCharging,
            Colors.blue,
          ),

          // Case
          _buildBatteryCard(
            'Case',
            batteryStatus.caseBattery,
            batteryStatus.isCaseCharging,
            Colors.green,
          ),

          // Right AirPod
          _buildBatteryCard(
            'Right AirPod',
            batteryStatus.rightPod,
            batteryStatus.isRightCharging,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  /// Build individual battery card
  Widget _buildBatteryCard(
    String title,
    int batteryLevel,
    bool isCharging,
    Color accentColor,
  ) {
    final bool hasValidData = batteryLevel >= 0;
    final bool isNotAvailable = batteryLevel == -1;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Battery Icon and Level
            if (isNotAvailable) ...[
              // Not Available - Pod is disconnected/not in case
              Icon(
                Icons.bluetooth_disabled,
                size: 32,
                color: Colors.grey.shade400,
              ),

              const SizedBox(height: 8),

              Text(
                'N/A',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),

              Text(
                'Disconnected',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (hasValidData) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  // Battery Icon
                  _buildBatteryIcon(batteryLevel, accentColor),

                  // Charging Icon Overlay
                  if (isCharging)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.bolt, size: 12, color: Colors.amber),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Battery Percentage
              Text(
                '$batteryLevel%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getBatteryTextColor(batteryLevel),
                ),
              ),

              // Charging Status
              if (isCharging)
                Text(
                  'Charging',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ] else ...[
              // No Data Available (unknown state)
              Icon(
                Icons.battery_unknown,
                size: 32,
                color: Colors.grey.shade400,
              ),

              const SizedBox(height: 8),

              Text(
                'No Data',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build battery icon based on level
  Widget _buildBatteryIcon(int level, Color color) {
    IconData iconData;

    if (level >= 90) {
      iconData = Icons.battery_full;
    } else if (level >= 60) {
      iconData = Icons.battery_5_bar;
    } else if (level >= 40) {
      iconData = Icons.battery_4_bar;
    } else if (level >= 20) {
      iconData = Icons.battery_2_bar;
    } else {
      iconData = Icons.battery_1_bar;
    }

    return Icon(iconData, size: 32, color: color);
  }

  /// Get battery text color based on level
  Color _getBatteryTextColor(int level) {
    if (level >= 50) {
      return Colors.green.shade700;
    } else if (level >= 20) {
      return Colors.orange.shade700;
    } else {
      return Colors.red.shade700;
    }
  }
}

/// Loading widget for the AirPods view
class AirPodsLoadingView extends StatelessWidget {
  const AirPodsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade100, Colors.grey.shade200],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading Animation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Bluetooth Icon with Animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.4 * value),
                      child: Icon(
                        Icons.bluetooth_searching,
                        size: 60,
                        color: Colors.blue.withOpacity(0.5 + (0.5 * value)),
                      ),
                    );
                  },
                  onEnd: () {
                    // Animation completed
                  },
                ),

                const SizedBox(height: 20),

                // Loading Text
                Text(
                  'Searching for AirPods...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Open the case near your phone',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Progress Indicator
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
