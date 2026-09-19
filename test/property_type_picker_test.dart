// Category and type are picked together in one sheet now. These cover what a
// tap does to the selection, the chip label, and the icons.
import 'package:brokkerspot/models/property_type_model.dart';
import 'package:brokkerspot/widgets/common/property_type_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _villaResidential =
    PropertyTypeModel(id: 'v-res', name: 'Villa', category: 'residential');
const _villaCommercial =
    PropertyTypeModel(id: 'v-com', name: 'Villa', category: 'commercial');

void main() {
  group('tapping a category', () {
    test('picks it', () {
      final next = PropertyTypePicker.selectCategory(
          PropertyTypeSelection.none, true);
      expect(next.isCommercial, isTrue);
      expect(next.typeId, isNull);
    });

    test('switching drops the type from the other category', () {
      final next = PropertyTypePicker.selectCategory(
        const PropertyTypeSelection(
            isCommercial: false, typeId: 'v-res', typeName: 'Villa'),
        true,
      );
      expect(next.isCommercial, isTrue);
      expect(next.typeId, isNull);
    });

    test('tapping the active one again clears everything', () {
      final next = PropertyTypePicker.selectCategory(
        const PropertyTypeSelection(isCommercial: true, typeId: 'v-com'),
        true,
      );
      expect(next.isEmpty, isTrue);
    });
  });

  group('tapping a type', () {
    test('with no category yet, settles on Residential — the list on show', () {
      final next = PropertyTypePicker.selectType(
          PropertyTypeSelection.none, _villaResidential);
      expect(next.isCommercial, isFalse);
      expect(next.typeId, 'v-res');
      expect(next.typeName, 'Villa');
    });

    test('keeps the chosen category and picks that category\'s record', () {
      // "Villa" exists on both sides; the id is what tells them apart.
      final next = PropertyTypePicker.selectType(
          const PropertyTypeSelection(isCommercial: true), _villaCommercial);
      expect(next.isCommercial, isTrue);
      expect(next.typeId, 'v-com');
    });

    test('tapping the selected tile again lets go of the type only', () {
      final next = PropertyTypePicker.selectType(
        const PropertyTypeSelection(isCommercial: true, typeId: 'v-com'),
        _villaCommercial,
      );
      expect(next.isCommercial, isTrue);
      expect(next.typeId, isNull);
    });
  });

  group('chip label', () {
    test('type wins, then category, then the placeholder', () {
      expect(
          propertyTypeChipLabel(isCommercial: true, typeName: 'Office'),
          'Office');
      expect(propertyTypeChipLabel(isCommercial: true), 'Commercial');
      expect(propertyTypeChipLabel(isCommercial: false), 'Residential');
      expect(propertyTypeChipLabel(), 'Property Type');
    });
  });

  group('icons', () {
    test('longer names are matched before the shorter ones inside them', () {
      expect(iconForPropertyType('Villa Compound'),
          isNot(iconForPropertyType('Villa')));
      expect(iconForPropertyType('Industrial Land'),
          isNot(iconForPropertyType('Land')));
      expect(iconForPropertyType('Hotel Apartment'),
          isNot(iconForPropertyType('Apartment')));
    });

    test('an unknown type still gets an icon', () {
      expect(iconForPropertyType('Something New'), Icons.home_work_outlined);
    });
  });
}
