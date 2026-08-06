class WaterEntry {
  const WaterEntry({
    required this.id,
    required this.date,
    required this.amountMl,
    required this.loggedAt,
  });

  final String id;
  final DateTime date;
  final int amountMl;
  final DateTime loggedAt;

  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amountMl: json['amountMl'] as int,
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );
  }
}
