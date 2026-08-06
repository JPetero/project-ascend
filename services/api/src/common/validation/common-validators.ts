import { applyDecorators } from '@nestjs/common';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsNumber, Max, Min, registerDecorator, ValidationOptions } from 'class-validator';

/** A bounded, required numeric range — the same `@IsNumber() @Min() @Max()`
 * trio repeated across nearly every DTO in this codebase (macro targets,
 * plan exercise targets, water amounts, ...), collapsed into one
 * decorator so the bounds are declared once per field instead of three
 * times. */
export function IsBoundedNumber(min: number, max: number): PropertyDecorator {
  return applyDecorators(IsNumber(), Min(min), Max(max));
}

/** Same as [IsBoundedNumber] but for integer-only fields (set counts,
 * ratings, quantities). */
export function IsBoundedInt(min: number, max: number): PropertyDecorator {
  return applyDecorators(IsInt(), Min(min), Max(max));
}

/** A 1–10 rating scale (RPE-style) — reusable anywhere "rate this 1 to
 * 10" applies, not just workout RPE (a future session-difficulty,
 * sleep-quality, or mood rating could use the exact same shape). Accepts
 * @ApiPropertyOptional's description override since the framing differs
 * per field. */
export function IsRatingScale(description: string): PropertyDecorator {
  return applyDecorators(
    ApiPropertyOptional({ description, minimum: 1, maximum: 10 }),
    IsNumber(),
    Min(1),
    Max(10),
  );
}

/**
 * Rejects a date string more than [maxDaysInFuture] days ahead of now —
 * catches an obviously wrong client clock or a typo'd year without
 * being so strict that a same-day-in-a-different-timezone log gets
 * rejected. Used for anything logged "as of now or recently" (a
 * completed workout set, a meal entry) — not for genuinely future-dated
 * fields like a goal target date, which should use ordinary `@IsDateString`
 * plus its own explicit business validation instead.
 */
export function IsNotFarFutureDate(
  maxDaysInFuture: number,
  validationOptions?: ValidationOptions,
): PropertyDecorator {
  return function (object: object, propertyName: string | symbol) {
    registerDecorator({
      name: 'isNotFarFutureDate',
      target: object.constructor,
      propertyName: propertyName as string,
      options: validationOptions,
      constraints: [maxDaysInFuture],
      validator: {
        validate(value: unknown, args) {
          if (typeof value !== 'string') return false;
          const parsed = new Date(value);
          if (Number.isNaN(parsed.getTime())) return false;
          const [maxDays] = (args?.constraints ?? [0]) as [number];
          const limit = new Date();
          limit.setDate(limit.getDate() + maxDays);
          return parsed.getTime() <= limit.getTime();
        },
        defaultMessage(args) {
          const [maxDays] = args?.constraints as [number];
          return `${String(args?.property)} cannot be more than ${maxDays} day(s) in the future`;
        },
      },
    });
  };
}
