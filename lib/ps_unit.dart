// lib/ps_unit.dart
class PSUnit {
  final int id;
  final String name;

  bool isUsed = false;
  bool isPaid = false;

  DateTime? startTime;
  DateTime? endTime;
  int remainingSeconds = 0; // updated by timer

  String rentalType = ""; // "perjam" / "harian"
  String? jaminan; // only for harian

  // store chosen duration to calculate price / show in detail
  int chosenMinutes = 0; // total minutes selected for the rental

  PSUnit({
    required this.id,
    required this.name,
  });

  /// Calculate price using rule:
  /// price = fullHours * 5000 + remainingMinutes * 100
  int getPrice() {
    final totalMinutes = chosenMinutes;
    final hours = totalMinutes ~/ 60;
    final rem = totalMinutes % 60;
    return (hours * 5000) + (rem * 100);
  }
}
