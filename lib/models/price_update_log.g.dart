// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_update_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceUpdateLogAdapter extends TypeAdapter<PriceUpdateLog> {
  @override
  final int typeId = 1;

  @override
  PriceUpdateLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceUpdateLog(
      productId: fields[0] as String,
      variantId: fields[1] as String,
      productName: fields[2] as String,
      variantName: fields[3] as String,
      oldPrice: fields[4] as double,
      newPrice: fields[5] as double,
      success: fields[6] as bool,
      timestamp: fields[7] as DateTime,
      runId: fields[8] as String?,
      updateType: fields[9] as String,
      storeDomain: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PriceUpdateLog obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.variantId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.variantName)
      ..writeByte(4)
      ..write(obj.oldPrice)
      ..writeByte(5)
      ..write(obj.newPrice)
      ..writeByte(6)
      ..write(obj.success)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.runId)
      ..writeByte(9)
      ..write(obj.updateType)
      ..writeByte(10)
      ..write(obj.storeDomain);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceUpdateLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
