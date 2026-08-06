import { validate } from 'class-validator';
import {
  IsBoundedInt,
  IsBoundedNumber,
  IsNotFarFutureDate,
  IsRatingScale,
} from './common-validators';

class BoundedNumberFixture {
  @IsBoundedNumber(0, 100)
  value!: number;
}

class BoundedIntFixture {
  @IsBoundedInt(1, 20)
  value!: number;
}

class RatingFixture {
  @IsRatingScale('How hard did that feel?')
  rpe!: number;
}

class FutureDateFixture {
  @IsNotFarFutureDate(1)
  date!: string;
}

describe('common-validators', () => {
  it('IsBoundedNumber accepts values within range and rejects outside it', async () => {
    const inRange = Object.assign(new BoundedNumberFixture(), { value: 50 });
    expect(await validate(inRange)).toHaveLength(0);

    const tooHigh = Object.assign(new BoundedNumberFixture(), { value: 101 });
    expect(await validate(tooHigh)).not.toHaveLength(0);

    const tooLow = Object.assign(new BoundedNumberFixture(), { value: -1 });
    expect(await validate(tooLow)).not.toHaveLength(0);
  });

  it('IsBoundedInt rejects non-integers even within range', async () => {
    const fractional = Object.assign(new BoundedIntFixture(), { value: 5.5 });
    expect(await validate(fractional)).not.toHaveLength(0);

    const valid = Object.assign(new BoundedIntFixture(), { value: 5 });
    expect(await validate(valid)).toHaveLength(0);
  });

  it('IsRatingScale enforces the 1-10 bound', async () => {
    const tooHigh = Object.assign(new RatingFixture(), { rpe: 11 });
    expect(await validate(tooHigh)).not.toHaveLength(0);

    const valid = Object.assign(new RatingFixture(), { rpe: 7 });
    expect(await validate(valid)).toHaveLength(0);
  });

  it('IsNotFarFutureDate rejects a date further out than the allowed window', async () => {
    const farFuture = new Date();
    farFuture.setDate(farFuture.getDate() + 10);
    const invalid = Object.assign(new FutureDateFixture(), {
      date: farFuture.toISOString(),
    });
    expect(await validate(invalid)).not.toHaveLength(0);

    const today = Object.assign(new FutureDateFixture(), {
      date: new Date().toISOString(),
    });
    expect(await validate(today)).toHaveLength(0);
  });

  it('IsNotFarFutureDate rejects a non-date value', async () => {
    const invalid = Object.assign(new FutureDateFixture(), { date: 'not-a-date' });
    expect(await validate(invalid)).not.toHaveLength(0);
  });
});
