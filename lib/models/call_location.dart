/// # CallLocation
/// 
/// Data model holding coordinates (latitude, longitude) and reverse geocoded address.
/// 
/// ## Learning Note
/// Decoupling location details into its own data model makes it easy to pass location
/// parameters across services (e.g. from GPS tracker to database records) and simplifies
/// integration with maps widgets.
class CallLocation {
  final double latitude;
  final double longitude;
  final String? address;

  CallLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  /// Deserialization.
  factory CallLocation.fromMap(Map<String, dynamic> map) {
    return CallLocation(
      latitude: map['latitude'] as double? ?? 0.0,
      longitude: map['longitude'] as double? ?? 0.0,
      address: map['address'] as String?,
    );
  }

  /// Serialization.
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}
