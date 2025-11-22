// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'communication_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunicationLog _$CommunicationLogFromJson(Map<String, dynamic> json) =>
    CommunicationLog(
      id: json['id'] as String,
      type: json['type'] as String,
      messageType: json['messageType'] as String,
      sosId: json['sosId'] as String?,
      helpRequestId: json['helpRequestId'] as String?,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      recipientId: json['recipientId'] as String?,
      recipientPhone: json['recipientPhone'] as String,
      recipientName: json['recipientName'] as String,
      content: json['content'] as String,
      priority: json['priority'] as String? ?? 'high',
      status: json['status'] as String? ?? 'initiated',
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$CommunicationLogToJson(CommunicationLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'messageType': instance.messageType,
      'sosId': instance.sosId,
      'helpRequestId': instance.helpRequestId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'recipientId': instance.recipientId,
      'recipientPhone': instance.recipientPhone,
      'recipientName': instance.recipientName,
      'content': instance.content,
      'priority': instance.priority,
      'status': instance.status,
      'timestamp': instance.timestamp.toIso8601String(),
      'isRead': instance.isRead,
      'metadata': instance.metadata,
    };
