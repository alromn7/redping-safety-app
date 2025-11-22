// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
          MessageType.text,
      priority:
          $enumDecodeNullable(_$MessagePriorityEnumMap, json['priority']) ??
              MessagePriority.normal,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map(
                  (e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      replyToMessageId: json['replyToMessageId'] as String?,
      isDelivered: json['isDelivered'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      readByUsers: (json['readByUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      location: json['location'] == null
          ? null
          : LocationInfo.fromJson(json['location'] as Map<String, dynamic>),
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatId': instance.chatId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'senderAvatar': instance.senderAvatar,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$MessageTypeEnumMap[instance.type]!,
      'priority': _$MessagePriorityEnumMap[instance.priority]!,
      'attachments': instance.attachments,
      'replyToMessageId': instance.replyToMessageId,
      'isDelivered': instance.isDelivered,
      'isRead': instance.isRead,
      'readByUsers': instance.readByUsers,
      'editedAt': instance.editedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'metadata': instance.metadata,
      'location': instance.location,
      'isEncrypted': instance.isEncrypted,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.video: 'video',
  MessageType.audio: 'audio',
  MessageType.location: 'location',
  MessageType.file: 'file',
  MessageType.system: 'system',
  MessageType.emergency: 'emergency',
  MessageType.sosUpdate: 'sos_update',
  MessageType.hazardAlert: 'hazard_alert',
  MessageType.volunteerUpdate: 'volunteer_update',
  MessageType.announcement: 'announcement',
  MessageType.activation: 'activation',
  MessageType.withdrawal: 'withdrawal',
};

const _$MessagePriorityEnumMap = {
  MessagePriority.low: 'low',
  MessagePriority.normal: 'normal',
  MessagePriority.high: 'high',
  MessagePriority.urgent: 'urgent',
  MessagePriority.emergency: 'emergency',
};

ChatRoom _$ChatRoomFromJson(Map<String, dynamic> json) => ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: $enumDecode(_$ChatTypeEnumMap, json['type']),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      moderators: (json['moderators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActivity: json['lastActivity'] == null
          ? null
          : DateTime.parse(json['lastActivity'] as String),
      lastMessage: json['lastMessage'] == null
          ? null
          : ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      settings: json['settings'] as Map<String, dynamic>? ?? const {},
      location: json['location'] == null
          ? null
          : LocationInfo.fromJson(json['location'] as Map<String, dynamic>),
      radius: (json['radius'] as num?)?.toDouble(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$ChatRoomToJson(ChatRoom instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$ChatTypeEnumMap[instance.type]!,
      'participants': instance.participants,
      'moderators': instance.moderators,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActivity': instance.lastActivity?.toIso8601String(),
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
      'isActive': instance.isActive,
      'isEncrypted': instance.isEncrypted,
      'settings': instance.settings,
      'location': instance.location,
      'radius': instance.radius,
      'tags': instance.tags,
    };

const _$ChatTypeEnumMap = {
  ChatType.direct: 'direct',
  ChatType.group: 'group',
  ChatType.community: 'community',
  ChatType.emergency: 'emergency',
  ChatType.sarTeam: 'sar_team',
  ChatType.locationBased: 'location_based',
  ChatType.broadcast: 'broadcast',
};

ChatUser _$ChatUserFromJson(Map<String, dynamic> json) => ChatUser(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      status: $enumDecodeNullable(_$UserStatusEnumMap, json['status']) ??
          UserStatus.available,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      location: json['location'] == null
          ? null
          : LocationInfo.fromJson(json['location'] as Map<String, dynamic>),
      isOnline: json['isOnline'] as bool? ?? false,
      isEmergencyContact: json['isEmergencyContact'] as bool? ?? false,
      isSARTeamMember: json['isSARTeamMember'] as bool? ?? false,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ChatUserToJson(ChatUser instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'status': _$UserStatusEnumMap[instance.status]!,
      'lastSeen': instance.lastSeen.toIso8601String(),
      'location': instance.location,
      'isOnline': instance.isOnline,
      'isEmergencyContact': instance.isEmergencyContact,
      'isSARTeamMember': instance.isSARTeamMember,
      'roles': instance.roles,
      'preferences': instance.preferences,
    };

const _$UserStatusEnumMap = {
  UserStatus.available: 'available',
  UserStatus.busy: 'busy',
  UserStatus.away: 'away',
  UserStatus.emergency: 'emergency',
  UserStatus.offline: 'offline',
};

MessageAttachment _$MessageAttachmentFromJson(Map<String, dynamic> json) =>
    MessageAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String?,
      localPath: json['localPath'] as String?,
      type: $enumDecode(_$AttachmentTypeEnumMap, json['type']),
      fileSize: (json['fileSize'] as num).toInt(),
      mimeType: json['mimeType'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MessageAttachmentToJson(MessageAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'localPath': instance.localPath,
      'type': _$AttachmentTypeEnumMap[instance.type]!,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'thumbnailUrl': instance.thumbnailUrl,
      'metadata': instance.metadata,
    };

const _$AttachmentTypeEnumMap = {
  AttachmentType.image: 'image',
  AttachmentType.video: 'video',
  AttachmentType.audio: 'audio',
  AttachmentType.document: 'document',
  AttachmentType.location: 'location',
};
