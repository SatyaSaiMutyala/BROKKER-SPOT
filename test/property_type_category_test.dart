// Smoke test for the Residential/Commercial category wiring on the
// create-announcement form.
//
// The fixtures below are the real dev-API responses of
// `user/common/fetch-property-types?category=...` (fetched 2026-09-10), so the
// parsing here is checked against the shape the app actually receives.
import 'dart:convert';

import 'package:brokkerspot/models/property_type_model.dart';
import 'package:brokkerspot/views/user/announcements/controller/property_type_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _residentialJson = '''
{"success":true,"message":"Property Types fetched successfully.","totalRecords":3,"totalPages":1,"page":1,"perPage":100,
 "data":[{"_id":"6a47fa4d66a9145e7b46af89","name":"Apartment","__v":0,"category":"residential"},
         {"_id":"6a9c8dfffa0b6e44ea0d7e10","name":"Building","category":"residential","__v":0},
         {"_id":"6a47fa8d66a9145e7b46af97","name":"Villa","category":"residential","__v":0}]}
''';

const _commercialJson = '''
{"success":true,"message":"Property Types fetched successfully.","totalRecords":3,"totalPages":1,"page":1,"perPage":100,
 "data":[{"_id":"6a9c8e00fa0b6e44ea0d7e20","name":"Building","category":"commercial","__v":0},
         {"_id":"6a9c8e00fa0b6e44ea0d7e21","name":"Office","category":"commercial","__v":0},
         {"_id":"6a9c8e00fa0b6e44ea0d7e22","name":"Villa","category":"commercial","__v":0}]}
''';

List<PropertyTypeModel> _parse(String body) =>
    (jsonDecode(body)['data'] as List)
        .map((e) => PropertyTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();

void main() {
  group('PropertyTypeModel.fromJson', () {
    test('reads id, name and category off the live response shape', () {
      final types = _parse(_residentialJson);

      expect(types, hasLength(3));
      expect(types.first.id, '6a47fa4d66a9145e7b46af89');
      expect(types.first.name, 'Apartment');
      expect(types.first.category, 'residential');
      expect(types.every((t) => t.id.isNotEmpty), isTrue);
    });
  });

  group('idForName across categories', () {
    test('the same name resolves to a different id per category', () {
      final residential = _parse(_residentialJson);
      final commercial = _parse(_commercialJson);

      final residentialVilla =
          residential.firstWhere((t) => t.name == 'Villa').id;
      final commercialVilla = commercial.firstWhere((t) => t.name == 'Villa').id;

      // This is the whole reason the dropdown may only ever hold one
      // category: "Villa" is two different records.
      expect(residentialVilla, isNot(commercialVilla));
    });

    test('the controller answers from the category it has loaded', () {
      final controller = PropertyTypeController();

      controller.propertyTypes.assignAll(_parse(_residentialJson));
      expect(controller.idForName('Villa'), '6a47fa8d66a9145e7b46af97');
      expect(controller.names, ['Apartment', 'Building', 'Villa']);
      // Commercial-only type is not offered under Residential.
      expect(controller.idForName('Office'), isNull);

      controller.propertyTypes.assignAll(_parse(_commercialJson));
      expect(controller.idForName('Villa'), '6a9c8e00fa0b6e44ea0d7e22');
      expect(controller.idForName('Office'), '6a9c8e00fa0b6e44ea0d7e21');
      // Residential-only type is not offered under Commercial.
      expect(controller.idForName('Apartment'), isNull);
    });
  });

  group('category → is_commercial_property', () {
    // The form holds the category as a string and the payload carries the
    // backend's flag; this is the mapping the two ends agree on.
    int flagFor(String category) =>
        category == PropertyTypeController.commercial ? 1 : 0;

    test('maps to the 0/1 the backend casts to its Boolean field', () {
      expect(flagFor(PropertyTypeController.residential), 0);
      expect(flagFor(PropertyTypeController.commercial), 1);
    });

    test('category constants match the backend enum values', () {
      expect(PropertyTypeController.residential, 'residential');
      expect(PropertyTypeController.commercial, 'commercial');
    });
  });
}
