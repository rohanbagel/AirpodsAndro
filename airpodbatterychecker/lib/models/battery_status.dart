/// Data model for AirPods battery status
class AirPodsBatteryStatus {
  final int leftPod;
  final int rightPod;
  final int caseBattery;
  final bool isLeftCharging;
  final bool isRightCharging;
  final bool isCaseCharging;

  const AirPodsBatteryStatus({
    required this.leftPod,
    required this.rightPod,
    required this.caseBattery,
    required this.isLeftCharging,
    required this.isRightCharging,
    required this.isCaseCharging,
  });

  /// Creates an empty/unknown battery status
  factory AirPodsBatteryStatus.unknown() {
    return const AirPodsBatteryStatus(
      leftPod: -1,
      rightPod: -1,
      caseBattery: -1,
      isLeftCharging: false,
      isRightCharging: false,
      isCaseCharging: false,
    );
  }

  /// Creates a copy with updated values
  AirPodsBatteryStatus copyWith({
    int? leftPod,
    int? rightPod,
    int? caseBattery,
    bool? isLeftCharging,
    bool? isRightCharging,
    bool? isCaseCharging,
  }) {
    return AirPodsBatteryStatus(
      leftPod: leftPod ?? this.leftPod,
      rightPod: rightPod ?? this.rightPod,
      caseBattery: caseBattery ?? this.caseBattery,
      isLeftCharging: isLeftCharging ?? this.isLeftCharging,
      isRightCharging: isRightCharging ?? this.isRightCharging,
      isCaseCharging: isCaseCharging ?? this.isCaseCharging,
    );
  }

  /// Returns true if the status has valid battery data (excludes "not available" -1 values)
  bool get hasValidData =>
      (leftPod >= 0 || leftPod == -1) &&
      (rightPod >= 0 || rightPod == -1) &&
      (caseBattery >= 0 || caseBattery == -1);

  /// Returns true if at least one component has actual battery data (not -1 or unknown)
  bool get hasAnyBatteryData =>
      (leftPod >= 0) || (rightPod >= 0) || (caseBattery >= 0);

  /// Returns true if a specific component is connected (not -1)
  bool get isLeftPodConnected => leftPod >= 0;
  bool get isRightPodConnected => rightPod >= 0;
  bool get isCaseConnected => caseBattery >= 0;

  @override
  String toString() {
    String formatBattery(int level) => level == -1 ? 'N/A' : '$level%';

    return 'AirPodsBatteryStatus('
        'leftPod: ${formatBattery(leftPod)}, '
        'rightPod: ${formatBattery(rightPod)}, '
        'caseBattery: ${formatBattery(caseBattery)}, '
        'isLeftCharging: $isLeftCharging, '
        'isRightCharging: $isRightCharging, '
        'isCaseCharging: $isCaseCharging)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirPodsBatteryStatus &&
        other.leftPod == leftPod &&
        other.rightPod == rightPod &&
        other.caseBattery == caseBattery &&
        other.isLeftCharging == isLeftCharging &&
        other.isRightCharging == isRightCharging &&
        other.isCaseCharging == isCaseCharging;
  }

  @override
  int get hashCode {
    return Object.hash(
      leftPod,
      rightPod,
      caseBattery,
      isLeftCharging,
      isRightCharging,
      isCaseCharging,
    );
  }
}
