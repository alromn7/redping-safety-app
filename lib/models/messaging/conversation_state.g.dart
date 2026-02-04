// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationStateAdapter extends TypeAdapter<ConversationState> {
  @override
  final int typeId = 3;

  @override
  ConversationState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationState(
      conversationId: fields[0] as String,
      participants: (fields[1] as List).cast<String>(),
      sharedSecret: fields[2] as String?,
      lastSyncTimestamp: fields[3] as int,
      participantSyncMarkers: (fields[4] as Map).cast<String, int>(),
      isEncrypted: fields[5] as bool,
      metadata: (fields[6] as Map).cast<String, dynamic>(),
      lastMessageId: fields[7] as String?,
      keyRotationTimestamp: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationState obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.conversationId)
      ..writeByte(1)
      ..write(obj.participants)
      ..writeByte(2)
      ..write(obj.sharedSecret)
      ..writeByte(3)
      ..write(obj.lastSyncTimestamp)
      ..writeByte(4)
      ..write(obj.participantSyncMarkers)
      ..writeByte(5)
      ..write(obj.isEncrypted)
      ..writeByte(6)
      ..write(obj.metadata)
      ..writeByte(7)
      ..write(obj.lastMessageId)
      ..writeByte(8)
      ..write(obj.keyRotationTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
