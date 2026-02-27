import 'dart:convert';

LoginResponseModel loginResponseModelFromJson(String str) =>
    LoginResponseModel.fromJson(json.decode(str));

String loginResponseModelToJson(LoginResponseModel data) =>
    json.encode(data.toJson());

class LoginResponseModel {
  final bool success;
  final String message;
  final UserData? data; // ✅ Made nullable

  LoginResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        success: json["success"] ?? false,
        message: json["message"] ?? "",
        data: json["data"] != null
            ? UserData.fromJson(json["data"])
            : null, // ✅ Safe parsing
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class UserData {
  final String id;
  final String name;
  final String email;
  final bool isEmailVerified;
  final int status;
  final String mobileNumber;
  final String countryCode;
  final int role;
  final int accountType;
  final List<dynamic> dealingCities;
  final List<dynamic> dealingAreas;
  final List<dynamic> knownLanguages;
  final String? deletedAt;
  final String? createdAt; // ✅ Made nullable
  final String? updatedAt; // ✅ Made nullable
  final int lastLoggedInRole;
  final String accessToken;
  final String refreshToken;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.isEmailVerified,
    required this.status,
    required this.mobileNumber,
    required this.countryCode,
    required this.role,
    required this.accountType,
    required this.dealingCities,
    required this.dealingAreas,
    required this.knownLanguages,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    required this.lastLoggedInRole,
    required this.accessToken,
    required this.refreshToken,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        id: json["_id"] ?? "",
        name: json["name"] ?? "",
        email: json["email"] ?? "",
        isEmailVerified: json["isEmailVerified"] ?? false,
        status: json["status"] ?? 0,
        mobileNumber: json["mobileNumber"] ?? "",
        countryCode: json["countryCode"] ?? "",
        role: json["role"] ?? 0,
        accountType: json["account_type"] ?? 0,
        dealingCities: List<dynamic>.from(json["dealingCities"] ?? []),
        dealingAreas: List<dynamic>.from(json["dealingAreas"] ?? []),
        knownLanguages: List<dynamic>.from(json["knownLanguages"] ?? []),
        deletedAt: json["deleted_at"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        lastLoggedInRole: json["lastLoggedInRole"] ?? 0,
        accessToken: json["access_token"] ?? "",
        refreshToken: json["refresh_token"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "email": email,
        "isEmailVerified": isEmailVerified,
        "status": status,
        "mobileNumber": mobileNumber,
        "countryCode": countryCode,
        "role": role,
        "account_type": accountType,
        "dealingCities": dealingCities,
        "dealingAreas": dealingAreas,
        "knownLanguages": knownLanguages,
        "deleted_at": deletedAt,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "lastLoggedInRole": lastLoggedInRole,
        "access_token": accessToken,
        "refresh_token": refreshToken,
      };
}
