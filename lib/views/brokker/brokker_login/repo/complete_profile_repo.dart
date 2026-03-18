import 'dart:convert';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/api_endpoints.dart';
import 'package:brokkerspot/views/brokker/brokker_login/model/complete_profile_model.dart';

class CompleteProfileRepo {
  Future<EditBrokerResponseModel> editBrokerDetails(
      EditBrokerDetailsModel model) async {
    final response = await api.putRequest(
      endPoint: '${api.baseUrl}${ApiEndpoints.editBrokerDetails}',
      body: model.toJson(),
      headers: api.buildHeaders(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return EditBrokerResponseModel.fromJson(json);
  }
}
