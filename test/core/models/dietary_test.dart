import 'package:barakali/core/models/dietary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DietaryOption', () {
    test('wire values match the DB vocabulary', () {
      expect(DietaryOption.halal.wire, 'halal');
      expect(DietaryOption.vegetarian.wire, 'vegetarian');
      expect(DietaryOption.vegan.wire, 'vegan');
      expect(DietaryOption.noPork.wire, 'no_pork');
      expect(DietaryOption.noAlcohol.wire, 'no_alcohol');
    });

    test('offerTags excludes halal (merchant-level attribute)', () {
      expect(DietaryOption.offerTags, isNot(contains(DietaryOption.halal)));
      expect(DietaryOption.offerTags, contains(DietaryOption.vegetarian));
      expect(DietaryOption.offerTags.length, 4);
    });

    test('parse maps known wires and drops unknowns', () {
      expect(DietaryOption.parse(['vegan', 'no_pork', 'kosher']), {
        DietaryOption.vegan,
        DietaryOption.noPork,
      });
      expect(DietaryOption.parse(const []), isEmpty);
    });
  });

  group('offerSatisfiesDietary', () {
    bool sat(
      Set<DietaryOption> prefs,
      Set<DietaryOption> tags, {
      bool halal = false,
    }) => offerSatisfiesDietary(
      prefs: prefs,
      offerTags: tags,
      merchantIsHalal: halal,
    );

    test('empty prefs matches everything', () {
      expect(sat({}, {}), isTrue);
    });

    test('halal keys off the merchant flag, not the offer tags', () {
      expect(sat({DietaryOption.halal}, {}, halal: true), isTrue);
      expect(sat({DietaryOption.halal}, {}, halal: false), isFalse);
    });

    test('vegan satisfies a vegetarian requirement (vegan is stricter)', () {
      expect(sat({DietaryOption.vegetarian}, {DietaryOption.vegan}), isTrue);
      expect(
        sat({DietaryOption.vegetarian}, {DietaryOption.vegetarian}),
        isTrue,
      );
    });

    test('a vegetarian tag does not satisfy a vegan requirement', () {
      expect(sat({DietaryOption.vegan}, {DietaryOption.vegetarian}), isFalse);
      expect(sat({DietaryOption.vegan}, {DietaryOption.vegan}), isTrue);
    });

    test('vegetarian/vegan imply no_pork', () {
      expect(sat({DietaryOption.noPork}, {DietaryOption.vegetarian}), isTrue);
      expect(sat({DietaryOption.noPork}, {DietaryOption.vegan}), isTrue);
      expect(sat({DietaryOption.noPork}, {DietaryOption.noPork}), isTrue);
      expect(sat({DietaryOption.noPork}, {}), isFalse);
    });

    test('no_alcohol is independent of the other tags', () {
      expect(sat({DietaryOption.noAlcohol}, {DietaryOption.vegan}), isFalse);
      expect(sat({DietaryOption.noAlcohol}, {DietaryOption.noAlcohol}), isTrue);
    });

    test('every required pref must hold (AND semantics)', () {
      // halal + vegan: both must be satisfied.
      expect(
        sat(
          {DietaryOption.halal, DietaryOption.vegan},
          {DietaryOption.vegan},
          halal: true,
        ),
        isTrue,
      );
      expect(
        sat(
          {DietaryOption.halal, DietaryOption.vegan},
          {DietaryOption.vegan},
          halal: false,
        ),
        isFalse,
      );
      expect(
        sat({DietaryOption.halal, DietaryOption.vegan}, {}, halal: true),
        isFalse,
      );
    });
  });
}
