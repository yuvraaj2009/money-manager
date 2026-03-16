import '../models/household_model.dart';
import 'api_service.dart';

class HouseholdService {
  HouseholdService(this._api);

  final ApiService _api;

  Future<List<HouseholdModel>> getHouseholds() async {
    final json = await _api.getJson('/households');
    final list = json as List<dynamic>;
    return list
        .map((item) => HouseholdModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<HouseholdModel> createHousehold(String name) async {
    final json = await _api.postJson('/households', {'name': name});
    return HouseholdModel.fromJson(json as Map<String, dynamic>);
  }

  Future<HouseholdModel> joinHousehold(String inviteCode) async {
    final json =
        await _api.postJson('/households/join', {'invite_code': inviteCode});
    return HouseholdModel.fromJson(json as Map<String, dynamic>);
  }

  Future<void> leaveHousehold(String householdId) async {
    await _api.deleteRequest('/households/$householdId/leave');
  }
}
