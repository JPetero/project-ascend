/// Shared `TextFormField` validators — every editor screen (custom food,
/// macro targets, cardio logging, ...) needs the same handful of "required",
/// "must be a number", "must be a whole number" checks; this is the one
/// place that logic lives instead of each screen writing its own copy.
/// See services/api/src/common/validation/common-validators.ts for the
/// backend-side equivalent (bounded numeric ranges enforced server-side —
/// these client validators are a fast-feedback layer, not the source of
/// truth for what's ultimately accepted).
library;

String? requiredText(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  return null;
}

String? requiredNumber(String? value) {
  final requiredError = requiredText(value);
  if (requiredError != null) return requiredError;
  if (double.tryParse(value!) == null) return 'Enter a number';
  return null;
}

String? requiredInt(String? value, {String message = 'Enter a whole number'}) {
  final requiredError = requiredText(value);
  if (requiredError != null) return requiredError;
  if (int.tryParse(value!) == null) return message;
  return null;
}

String? requiredPositiveInt(
  String? value, {
  String message = 'Enter a whole number',
}) {
  final error = requiredInt(value, message: message);
  if (error != null) return error;
  if (int.parse(value!) <= 0) return message;
  return null;
}

String? optionalPositiveNumber(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = double.tryParse(value);
  if (parsed == null || parsed <= 0) return 'Enter a positive number';
  return null;
}
