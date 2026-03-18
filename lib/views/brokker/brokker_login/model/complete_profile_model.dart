class FileUploadResponseModel {
  final bool success;
  final String message;
  final String? fileUrl;

  FileUploadResponseModel({
    required this.success,
    required this.message,
    this.fileUrl,
  });

  factory FileUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return FileUploadResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      fileUrl: json['data']?['url'] ?? json['data']?['fileUrl'] ?? json['url'],
    );
  }
}

class EditBrokerDetailsModel {
  final String? profileImage;
  final String? passportImage;
  final String? localIdFrontImage;
  final String? localIdBackImage;
  final String dealingCountry;
  final List<String> dealingCities;
  final List<String> dealingAreas;
  final int experience;
  final List<String> knownLanguages;
  final String professionalEmail;
  final String? bnrNumber;

  EditBrokerDetailsModel({
    this.profileImage,
    this.passportImage,
    this.localIdFrontImage,
    this.localIdBackImage,
    required this.dealingCountry,
    required this.dealingCities,
    required this.dealingAreas,
    required this.experience,
    required this.knownLanguages,
    required this.professionalEmail,
    this.bnrNumber,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'dealingCountry': dealingCountry,
      'dealingCities': dealingCities,
      'dealingAreas': dealingAreas,
      'experience': experience,
      'knownLanguages': knownLanguages,
      'professionalEmail': professionalEmail,
    };
    if (profileImage != null && profileImage!.isNotEmpty) {
      map['profileImage'] = profileImage;
    }
    if (passportImage != null && passportImage!.isNotEmpty) {
      map['passportImage'] = passportImage;
    }
    if (localIdFrontImage != null && localIdFrontImage!.isNotEmpty) {
      map['localIdFrontImage'] = localIdFrontImage;
    }
    if (localIdBackImage != null && localIdBackImage!.isNotEmpty) {
      map['localIdBackImage'] = localIdBackImage;
    }
    if (bnrNumber != null && bnrNumber!.isNotEmpty) {
      map['bnrNumber'] = bnrNumber;
    }
    return map;
  }
}

class EditBrokerResponseModel {
  final bool success;
  final String message;

  EditBrokerResponseModel({required this.success, required this.message});

  factory EditBrokerResponseModel.fromJson(Map<String, dynamic> json) {
    return EditBrokerResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
