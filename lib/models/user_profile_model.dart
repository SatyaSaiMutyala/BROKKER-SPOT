/// Another user's public profile, as returned by
/// `GET /api/v1/user/profile/get-user/:id`.
///
/// That endpoint hands back the whole Mongo user document minus `password`, so
/// the fields below mirror the backend `User` schema. [orn] is the exception —
/// the schema does not carry it yet, so it parses to null and the screen shows
/// "-" until the field is added server-side.
class UserProfileModel {
  final String id;
  final String? name;
  final String? email;

  /// Where the user themselves is based.
  final String? country;

  /// Broker-only: the country they broker in. Falls back to [country] for
  /// display — see [displayCountry].
  final String? dealingCountry;
  final List<String> dealingCities;
  final List<String> dealingAreas;
  final List<String> knownLanguages;

  /// Years of experience.
  final int? experience;

  /// Broker licence number (rendered as "BRN").
  final String? bnrNumber;

  /// Office registration number. Not yet on the backend `User` schema, so this
  /// is null today and the screen shows "-" for it — parsed here so it lights
  /// up on its own once the field is added server-side.
  final String? orn;

  final String? userProfileImage;
  final String? brokerProfileImage;

  /// 1 = user, 2 = broker, 3 = both. Same bitmask the rest of the app uses.
  final int? role;
  final int? currentRole;

  /// "inactive" | "pending" | "approved" | "rejected".
  final String? verificationStatus;

  const UserProfileModel({
    required this.id,
    this.name,
    this.email,
    this.country,
    this.dealingCountry,
    this.dealingCities = const [],
    this.dealingAreas = const [],
    this.knownLanguages = const [],
    this.experience,
    this.bnrNumber,
    this.orn,
    this.userProfileImage,
    this.brokerProfileImage,
    this.role,
    this.currentRole,
    this.verificationStatus,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: _str(json['name']),
        email: _str(json['email']),
        country: _str(json['country']),
        dealingCountry: _str(json['dealingCountry']),
        dealingCities: _stringList(json['dealingCities']),
        dealingAreas: _stringList(json['dealingAreas']),
        knownLanguages: _stringList(json['knownLanguages']),
        experience: (json['experience'] as num?)?.toInt(),
        bnrNumber: _str(json['bnrNumber']),
        orn: _str(json['orn']) ?? _str(json['ornNumber']),
        userProfileImage: _str(json['userProfileImage']),
        brokerProfileImage: _str(json['brokerProfileImage']),
        role: (json['role'] as num?)?.toInt(),
        currentRole: (json['currentRole'] as num?)?.toInt(),
        verificationStatus: _str(json['verificationStatus']),
      );

  /// True when this person holds the broker role — including hybrid (3), which
  /// is `1 | 2`. Matches `ProfileController.hasBrokerRole`.
  bool get isBroker => ((role ?? 1) & 2) != 0;

  /// Only an admin-approved broker earns the verified badge.
  bool get isVerified => isBroker && verificationStatus == 'approved';

  /// The photo to show. A broker has two on file and the broker-side one is the
  /// professional headshot, so it wins when they have one.
  String? get avatarUrl {
    final broker = brokerProfileImage;
    final user = userProfileImage;
    if (isBroker && broker != null && broker.isNotEmpty) return broker;
    if (user != null && user.isNotEmpty) return user;
    if (broker != null && broker.isNotEmpty) return broker;
    return null;
  }

  String? get displayCountry {
    final dealing = dealingCountry;
    if (dealing != null && dealing.isNotEmpty) return dealing;
    final own = country;
    return (own != null && own.isNotEmpty) ? own : null;
  }

  /// Areas fall back to cities: brokers onboarded before areas were collected
  /// have only `dealingCities` filled in, and showing "Not added yet" for
  /// someone who did list their coverage reads as missing data.
  List<String> get coverage =>
      dealingAreas.isNotEmpty ? dealingAreas : dealingCities;

  /// "5 Year" / "1 Year", matching the design. Null when not provided.
  String? get experienceLabel {
    final years = experience;
    if (years == null) return null;
    return '$years ${years == 1 ? 'Year' : 'Years'}';
  }

  static String? _str(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
