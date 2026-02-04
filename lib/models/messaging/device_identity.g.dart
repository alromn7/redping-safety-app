// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_identity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceIdentityAdapter extends TypeAdapter<DeviceIdentity> {
  @override
  final int typeId = 2;

  @override
  DeviceIdentity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceIdentity(
      userId: fields[0] as String,
      deviceId: fields[1] as String,
      publicKey: fields[2] as String,
      signingKey: fields[3] as String,
      lastSeen: fields[4] as int,
      availableTransports: (fields[5] as List).cast<String>(),
      metadata: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DeviceIdentity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.deviceId)
      ..writeByte(2)
      ..write(obj.publicKey)
      ..writeByte(3)
      ..write(obj.signingKey)
      ..writeByte(4)
      ..write(obj.lastSeen)
      ..writeByte(5)
      ..write(obj.availableTransports)
      ..writeByte(6)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceIdentityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
