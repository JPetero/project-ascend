import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString, MaxLength } from 'class-validator';

export enum PurchasePlatformDto {
  IOS = 'IOS',
  ANDROID = 'ANDROID',
}

export class VerifyPurchaseDto {
  @ApiProperty({ enum: PurchasePlatformDto })
  @IsEnum(PurchasePlatformDto)
  platform!: PurchasePlatformDto;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  productId!: string;

  // iOS: the base64 App Store receipt (StoreKit's
  // `Transaction.jsonRepresentation`/legacy receipt). Android: the
  // purchase token from `in_app_purchase`'s `PurchaseDetails.verificationData`.
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(8000)
  receipt!: string;
}
