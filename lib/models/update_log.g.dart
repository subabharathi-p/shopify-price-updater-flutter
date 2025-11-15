// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VariantDetailAdapter extends TypeAdapter<VariantDetail> {
  @override
  final int typeId = 3;

  @override
  VariantDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VariantDetail(
      variantId: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      variantName: fields[3] as String,
      oldPrice: fields[4] as double,
      newPrice: fields[5] as double,
      success: fields[6] as bool,
      beforePrice: fields[7] as double?,
      currentPrice: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, VariantDetail obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.variantId)
      ..writeByte(1)
      ..write(obj.productId)
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
      ..write(obj.beforePrice)
      ..writeByte(8)
      ..write(obj.currentPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UpdateLogSummaryAdapter extends TypeAdapter<UpdateLogSummary> {
  @override
  final int typeId = 2;

  @override
  UpdateLogSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UpdateLogSummary(
      runId: fields[0] as String,
      timestamp: fields[1] as DateTime,
      category: fields[2] as String,
      subCategory: fields[3] as String?,
      operation: fields[4] as String,
      valueType: fields[5] as String,
      value: fields[6] as double,
      rounding: fields[7] as String,
      total: fields[8] as int,
      success: fields[9] as int,
      failed: fields[10] as int,
      type: fields[11] as String,
      lastUpdated: fields[13] as DateTime?,
      variantDetails: (fields[12] as List?)?.cast<VariantDetail>(),
      storeDomain: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UpdateLogSummary obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.runId)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.subCategory)
      ..writeByte(4)
      ..write(obj.operation)
      ..writeByte(5)
      ..write(obj.valueType)
      ..writeByte(6)
      ..write(obj.value)
      ..writeByte(7)
      ..write(obj.rounding)
      ..writeByte(8)
      ..write(obj.total)
      ..writeByte(9)
      ..write(obj.success)
      ..writeByte(10)
      ..write(obj.failed)
      ..writeByte(11)
      ..write(obj.type)
      ..writeByte(12)
      ..write(obj.variantDetails)
      ..writeByte(13)
      ..write(obj.lastUpdated)
      ..writeByte(14)
      ..write(obj.storeDomain);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateLogSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
