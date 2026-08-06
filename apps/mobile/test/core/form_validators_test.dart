import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/validation/form_validators.dart';

void main() {
  group('requiredText', () {
    test('rejects empty or whitespace-only input', () {
      expect(requiredText(null), 'Required');
      expect(requiredText(''), 'Required');
      expect(requiredText('   '), 'Required');
    });

    test('accepts any non-empty text', () {
      expect(requiredText('hi'), isNull);
    });
  });

  group('requiredNumber', () {
    test('rejects empty input and non-numeric text', () {
      expect(requiredNumber(''), 'Required');
      expect(requiredNumber('abc'), 'Enter a number');
    });

    test('accepts a valid decimal', () {
      expect(requiredNumber('12.5'), isNull);
    });
  });

  group('requiredInt', () {
    test('rejects empty input and non-integer text', () {
      expect(requiredInt(''), 'Required');
      expect(requiredInt('12.5'), 'Enter a whole number');
    });

    test('supports a custom message', () {
      expect(requiredInt('abc', message: 'Custom'), 'Custom');
    });

    test('accepts a valid whole number', () {
      expect(requiredInt('42'), isNull);
    });
  });

  group('requiredPositiveInt', () {
    test('rejects zero and negative values', () {
      expect(requiredPositiveInt('0'), 'Enter a whole number');
      expect(requiredPositiveInt('-5'), 'Enter a whole number');
    });

    test('accepts a positive whole number', () {
      expect(requiredPositiveInt('30'), isNull);
    });
  });

  group('optionalPositiveNumber', () {
    test('allows empty input', () {
      expect(optionalPositiveNumber(null), isNull);
      expect(optionalPositiveNumber(''), isNull);
    });

    test('rejects a non-positive or non-numeric value', () {
      expect(optionalPositiveNumber('0'), 'Enter a positive number');
      expect(optionalPositiveNumber('abc'), 'Enter a positive number');
    });

    test('accepts a positive decimal', () {
      expect(optionalPositiveNumber('5.5'), isNull);
    });
  });
}
