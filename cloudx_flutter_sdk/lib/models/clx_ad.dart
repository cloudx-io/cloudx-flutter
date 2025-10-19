/// Ad metadata model
/// 
/// Represents metadata about a loaded ad.
/// Corresponds to CLXAd (iOS) and CloudXAd (Android) in the native SDKs.
library;

/// Represents metadata about a loaded ad.
/// 
/// Corresponds to:
/// - iOS: CLXAd
/// - Android: CloudXAd
/// 
/// Contains information about ad placement, bidder, and revenue.
/// All fields are optional as they may not be available depending on
/// the ad lifecycle state (e.g., during load failures).
class CLXAd {
  /// The placement name configured in the CloudX dashboard
  final String? placementName;
  
  /// The unique identifier for this placement
  final String? placementId;
  
  /// The ad network/bidder that won the auction (e.g., "admob", "applovin")
  final String? bidder;
  
  /// The external placement ID from the ad network (network-specific ID)
  final String? externalPlacementId;
  
  /// The eCPM revenue for this ad impression in USD
  final double? revenue;

  /// Creates a CLXAd instance.
  /// 
  /// Typically created internally by the SDK from native platform data.
  const CLXAd({
    this.placementName,
    this.placementId,
    this.bidder,
    this.externalPlacementId,
    this.revenue,
  });

  /// Creates a CLXAd from a map received from the platform channel.
  /// 
  /// Returns an empty CLXAd if [map] is null.
  factory CLXAd.fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const CLXAd();
    }

    return CLXAd(
      placementName: map['placementName'] as String?,
      placementId: map['placementId'] as String?,
      bidder: map['bidder'] as String?,
      externalPlacementId: map['externalPlacementId'] as String?,
      revenue: map['revenue'] != null ? (map['revenue'] as num).toDouble() : null,
    );
  }

  /// Converts this CLXAd to a map for platform channel communication.
  Map<String, dynamic> toMap() {
    return {
      'placementName': placementName,
      'placementId': placementId,
      'bidder': bidder,
      'externalPlacementId': externalPlacementId,
      'revenue': revenue,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CLXAd &&
        other.placementName == placementName &&
        other.placementId == placementId &&
        other.bidder == bidder &&
        other.externalPlacementId == externalPlacementId &&
        other.revenue == revenue;
  }

  @override
  int get hashCode {
    return Object.hash(
      placementName,
      placementId,
      bidder,
      externalPlacementId,
      revenue,
    );
  }

  @override
  String toString() {
    return 'CLXAd('
        'placementName: $placementName, '
        'placementId: $placementId, '
        'bidder: $bidder, '
        'externalPlacementId: $externalPlacementId, '
        'revenue: $revenue'
        ')';
  }

  /// Creates a copy of this CLXAd with the given fields replaced.
  CLXAd copyWith({
    String? placementName,
    String? placementId,
    String? bidder,
    String? externalPlacementId,
    double? revenue,
  }) {
    return CLXAd(
      placementName: placementName ?? this.placementName,
      placementId: placementId ?? this.placementId,
      bidder: bidder ?? this.bidder,
      externalPlacementId: externalPlacementId ?? this.externalPlacementId,
      revenue: revenue ?? this.revenue,
    );
  }
}

