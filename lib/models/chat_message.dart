import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'sos_session.dart';

part 'chat_message.g.dart';

/// Chat message model for community and emergency communication
@JsonSerializable()
class ChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessagePriority priority;
  final List<MessageAttachment> attachments;
  final String? replyToMessageId;
  final bool isDelivered;
  final bool isRead;
  final List<String> readByUsers;
  final DateTime? editedAt;
  final bool isDeleted;
  final Map<String, dynamic>? metadata;
  final LocationInfo? location;
  final bool isEncrypted;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.priority = MessagePriority.normal,
    this.attachments = const [],
    this.replyToMessageId,
    this.isDelivered = false,
    this.isRead = false,
    this.readByUsers = const [],
    this.editedAt,
    this.isDeleted = false,
    this.metadata,
    this.location,
    this.isEncrypted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    MessagePriority? priority,
    List<MessageAttachment>? attachments,
    String? replyToMessageId,
    bool? isDelivered,
    bool? isRead,
    List<String>? readByUsers,
    DateTime? editedAt,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
    LocationInfo? location,
    bool? isEncrypted,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      readByUsers: readByUsers ?? this.readByUsers,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
      location: location ?? this.location,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  bool get isEdited => editedAt != null;
  Duration get age => DateTime.now().difference(timestamp);
  bool get isEmergency => priority == MessagePriority.emergency;
  bool get hasAttachments => attachments.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    chatId,
    senderId,
    content,
    timestamp,
    type,
    priority,
    attachments,
    isDelivered,
    isRead,
  ];
}

/// Chat room/channel model
@JsonSerializable()
class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final List<String> participants;
  final List<String> moderators;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isActive;
  final bool isEncrypted;
  final Map<String, dynamic> settings;
  final LocationInfo? location;
  final double? radius;
  final List<String> tags;

  const ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.participants = const [],
    this.moderators = const [],
    required this.createdAt,
    this.lastActivity,
    this.lastMessage,
    this.unreadCount = 0,
    this.isActive = true,
    this.isEncrypted = false,
    this.settings = const {},
    this.location,
    this.radius,
    this.tags = const [],
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    ChatType? type,
    List<String>? participants,
    List<String>? moderators,
    DateTime? createdAt,
    DateTime? lastActivity,
    ChatMessage? lastMessage,
    int? unreadCount,
    bool? isActive,
    bool? isEncrypted,
    Map<String, dynamic>? settings,
    LocationInfo? location,
    double? radius,
    List<String>? tags,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      moderators: moderators ?? this.moderators,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      settings: settings ?? this.settings,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      tags: tags ?? this.tags,
    );
  }

  bool get hasUnreadMessages => unreadCount > 0;
  bool get isLocationBased => location != null;
  Duration get timeSinceLastActivity => lastActivity != null
      ? DateTime.now().difference(lastActivity!)
      : DateTime.now().difference(createdAt);

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    participants,
    lastActivity,
    unreadCount,
    isActive,
  ];
}

/// User profile for chat
@JsonSerializable()
class ChatUser extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final UserStatus status;
  final DateTime lastSeen;
  final LocationInfo? location;
  final bool isOnline;
  final bool isEmergencyContact;
  final bool isSARTeamMember;
  final List<String> roles;
  final Map<String, dynamic> preferences;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.status = UserStatus.available,
    required this.lastSeen,
    this.location,
    this.isOnline = false,
    this.isEmergencyContact = false,
    this.isSARTeamMember = false,
    this.roles = const [],
    this.preferences = const {},
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) =>
      _$ChatUserFromJson(json);
  Map<String, dynamic> toJson() => _$ChatUserToJson(this);

  ChatUser copyWith({
    String? id,
    String? name,
    String? avatar,
    UserStatus? status,
    DateTime? lastSeen,
    LocationInfo? location,
    bool? isOnline,
    bool? isEmergencyContact,
    bool? isSARTeamMember,
    List<String>? roles,
    Map<String, dynamic>? preferences,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
      isSARTeamMember: isSARTeamMember ?? this.isSARTeamMember,
      roles: roles ?? this.roles,
      preferences: preferences ?? this.preferences,
    );
  }

  String get displayName => name;
  String get initials =>
      name.split(' ').map((n) => n[0]).take(2).join().toUpperCase();
  bool get isSpecialRole =>
      isEmergencyContact || isSARTeamMember || roles.isNotEmpty;

  @override
  List<Object?> get props => [id, name, status, lastSeen, isOnline];
}

/// Message attachment
@JsonSerializable()
class MessageAttachment extends Equatable {
  final String id;
  final String fileName;
  final String? fileUrl;
  final String? localPath;
  final AttachmentType type;
  final int fileSize;
  final String? mimeType;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;

  const MessageAttachment({
    required this.id,
    required this.fileName,
    this.fileUrl,
    this.localPath,
    required this.type,
    required this.fileSize,
    this.mimeType,
    this.thumbnailUrl,
    this.metadata,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      _$MessageAttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$MessageAttachmentToJson(this);

  bool get isImage => type == AttachmentType.image;
  bool get isVideo => type == AttachmentType.video;
  bool get isAudio => type == AttachmentType.audio;
  bool get isDocument => type == AttachmentType.document;

  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  List<Object?> get props => [id, fileName, type, fileSize];
}

/// Enums
enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
  @JsonValue('location')
  location,
  @JsonValue('file')
  file,
  @JsonValue('system')
  system,
  @JsonValue('emergency')
  emergency,
  @JsonValue('sos_update')
  sosUpdate,
  @JsonValue('hazard_alert')
  hazardAlert,
  @JsonValue('volunteer_update')
  volunteerUpdate,
  @JsonValue('announcement')
  announcement,
  @JsonValue('activation')
  activation,
  @JsonValue('withdrawal')
  withdrawal,
}

enum MessagePriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
  @JsonValue('emergency')
  emergency,
}

enum ChatType {
  @JsonValue('direct')
  direct,
  @JsonValue('group')
  group,
  @JsonValue('community')
  community,
  @JsonValue('emergency')
  emergency,
  @JsonValue('sar_team')
  sarTeam,
  @JsonValue('location_based')
  locationBased,
  @JsonValue('broadcast')
  broadcast,
}

enum UserStatus {
  @JsonValue('available')
  available,
  @JsonValue('busy')
  busy,
  @JsonValue('away')
  away,
  @JsonValue('emergency')
  emergency,
  @JsonValue('offline')
  offline,
}

enum AttachmentType {
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
  @JsonValue('document')
  document,
  @JsonValue('location')
  location,
}
