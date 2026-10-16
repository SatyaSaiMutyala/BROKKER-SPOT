/// One row of `user/dashboard/brokers` — an approved broker shown in the
/// user-side home screen's story row.
class BrokerSummary {
  final String? id;
  final String? name;
  final String? email;
  final String? country;
  final String? mobileNumber;
  final String? brokerProfileImage;

  const BrokerSummary({
    this.id,
    this.name,
    this.email,
    this.country,
    this.mobileNumber,
    this.brokerProfileImage,
  });

  factory BrokerSummary.fromJson(Map<String, dynamic> json) => BrokerSummary(
        id: json['_id']?.toString(),
        name: json['name']?.toString(),
        email: json['email']?.toString(),
        country: json['country']?.toString(),
        mobileNumber: json['mobileNumber']?.toString(),
        brokerProfileImage: json['brokerProfileImage']?.toString(),
      );
}
