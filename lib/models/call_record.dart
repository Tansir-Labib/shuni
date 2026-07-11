/// # CallDirection
/// 
/// Enum representing the direction of a call.
enum CallDirection {
  incoming,
  outgoing;

  /// Serialization: converts the enum value to a String representation.
  String toJson() => name;

  /// Deserialization: maps a String back to a CallDirection enum.
  static CallDirection fromJson(String value) {
    return values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CallDirection.incoming,
    );
  }
}

/// # CallRecord
/// 
/// Data model representing a recorded call and all associated metadata.
/// 
/// ## Learning Note
/// In Flutter applications, data models are typically declared with final immutable properties.
/// If we need to edit a record, we use the `copyWith` method to clone it with updated values.
/// This prevents side-effects in state management and maintains a single-source-of-truth.
class CallRecord {
  final int? id;
  final String phoneNumber;
  final String contactName;
  final DateTime dateTime;
  final int durationSeconds;
  final CallDirection direction;
  final String audioFilePath;
  final int fileSizeBytes;
  
  // Location details (can be null if GPS was disabled or failed)
  final double? latitude;
  final double? longitude;
  final String? address;
  
  // User annotations
  final bool isBookmarked;
  final String? notes;
  
  // Call type indicators
  final bool isVoip;

  CallRecord({
    this.id,
    required this.phoneNumber,
    required this.contactName,
    required this.dateTime,
    required this.durationSeconds,
    required this.direction,
    required this.audioFilePath,
    required this.fileSizeBytes,
    this.latitude,
    this.longitude,
    this.address,
    this.isBookmarked = false,
    this.notes,
    this.isVoip = false,
  });

  /// Clones the record with optional overridden properties.
  CallRecord copyWith({
    int? id,
    String? phoneNumber,
    String? contactName,
    DateTime? dateTime,
    int? durationSeconds,
    CallDirection? direction,
    String? audioFilePath,
    int? fileSizeBytes,
    double? latitude,
    double? longitude,
    String? address,
    bool? isBookmarked,
    String? notes,
    bool? isVoip,
  }) {
    return CallRecord(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      dateTime: dateTime ?? this.dateTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      direction: direction ?? this.direction,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      notes: notes ?? this.notes,
      isVoip: isVoip ?? this.isVoip,
    );
  }

  /// Deserialization: Maps database row (Map<String, dynamic>) to a [CallRecord] object.
  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id'] as int?,
      phoneNumber: map['phone_number'] as String? ?? 'Unknown',
      contactName: map['contact_name'] as String? ?? 'Unknown',
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time_ms'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      direction: CallDirection.fromJson(map['direction'] as String? ?? 'incoming'),
      audioFilePath: map['audio_file_path'] as String? ?? '',
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      address: map['address'] as String?,
      isBookmarked: (map['is_bookmarked'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      isVoip: (map['is_voip'] as int? ?? 0) == 1,
    );
  }

  /// Serialization: Maps [CallRecord] to a database-friendly Map<String, dynamic> layout.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'contact_name': contactName,
      'date_time_ms': dateTime.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'direction': direction.toJson(),
      'audio_file_path': audioFilePath,
      'file_size_bytes': fileSizeBytes,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'is_bookmarked': isBookmarked ? 1 : 0,
      'notes': notes,
      'is_voip': isVoip ? 1 : 0,
    };
  }
}
