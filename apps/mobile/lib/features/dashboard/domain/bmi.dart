/// BMI is informational only — never a score, never used alone to select a
/// workout or nutrition plan. See
/// packages/docs/product/wellness-ethics-bible.md for the required framing
/// and disclaimer text this powers.
class BmiResult {
  const BmiResult({required this.value, required this.category});

  final double value;
  final String category;
}

const String bmiDisclaimer =
    'BMI is one general screening metric and may not reflect muscle mass, '
    'body composition, or individual health. Your consistency, strength, '
    'mobility, energy, and overall wellbeing matter too.';

/// Returns null when either input is missing — the dashboard shows a
/// graceful "add your height and weight" prompt in that case rather than a
/// fabricated number.
BmiResult? calculateBmi({double? heightCm, double? weightKg}) {
  if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
    return null;
  }
  final heightM = heightCm / 100;
  final value = weightKg / (heightM * heightM);
  return BmiResult(
    value: (value * 10).round() / 10,
    category: _category(value),
  );
}

String _category(double value) {
  if (value < 18.5) return 'Below typical range';
  if (value < 25) return 'Typical range';
  if (value < 30) return 'Above typical range';
  return 'Well above typical range';
}
