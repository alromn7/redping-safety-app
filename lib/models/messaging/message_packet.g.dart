// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_packet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessagePacketAdapter extends TypeAdapter<MessagePacket> {
  @override
  final int typeId = 1;

  @override
  MessagePacket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessagePacket(
      messageId: fields[0] as String,
      conversationId: fields[1] as String,
      senderId: fields[2] as String,
      deviceId: fields[3] as String,
      type: fields[4] as String,
      encryptedPayload: fields[5] as String,
      signature: fields[6] as String,
      timestamp: fields[7] as int,
      priority: fields[8] as String,
      preferredTransport: fields[9] as String,
      ttl: fields[10] as int,
      hopCount: fields[11] as int,
      metadata: (fields[12] as Map).cast<String, dynamic>(),
      recipients: (fields[13] as List).cast<String>(),
      status: fields[14] as String?,
      transportUsed: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessagePacket obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.deviceId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.encryptedPayload)
      ..writeByte(6)
      ..write(obj.signature)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.preferredTransport)
      ..writeByte(10)
      ..write(obj.ttl)
      ..writeByte(11)
      ..write(obj.hopCount)
      ..writeByte(12)
      ..write(obj.metadata)
      ..writeByte(13)
      ..write(obj.recipients)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.transportUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagePacketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
