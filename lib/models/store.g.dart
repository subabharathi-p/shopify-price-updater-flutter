// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoreAdapter extends TypeAdapter<Store> {
  @override
  final int typeId = 0;

  @override
  Store read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Store(
      storeName: fields[0] as String,
      shopDomain: fields[1] as String,
      accessToken: fields[2] as String,
      currency: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Store obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.storeName)
      ..writeByte(1)
      ..write(obj.shopDomain)
      ..writeByte(2)
      ..write(obj.accessToken)
      ..writeByte(3)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
