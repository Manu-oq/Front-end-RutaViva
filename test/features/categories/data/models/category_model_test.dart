import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/features/categories/data/models/category_model.dart';

void main() {
  group('CategoryModel', () {
    test('parses parent_id from backend contract', () {
      final parent = CategoryModel.fromJson({
        'id': 1,
        'name': 'Naturaleza',
        'icon_url': null,
        'parent_id': null,
      });
      final child = CategoryModel.fromJson({
        'id': 6,
        'name': 'Trekking/Senderismo',
        'icon_url': null,
        'parent_id': 1,
      });

      expect(parent.parentId, isNull);
      expect(parent.isParent, isTrue);
      expect(child.parentId, equals(1));
      expect(child.isParent, isFalse);
    });

    test('builds grouped attraction categories and hides infrastructure', () {
      const categories = [
        CategoryModel(id: 1, name: 'Naturaleza'),
        CategoryModel(id: 5, name: 'Cultura'),
        CategoryModel(id: 6, name: 'Trekking/Senderismo', parentId: 1),
        CategoryModel(id: 10, name: 'Parques/Reservas', parentId: 1),
        CategoryModel(id: 11, name: 'Museos/Patrimonio', parentId: 5),
        CategoryModel(id: 13, name: 'Servicios turísticos/Información'),
        CategoryModel(id: 14, name: 'Transporte/Accesos'),
      ];

      expect(
        categories.topLevelAttractionCategories().map((item) => item.id),
        equals([1, 5]),
      );
      expect(categories.childrenOf(1).map((item) => item.id), equals([6, 10]));
      expect(categories.childrenOf(5).single.id, equals(11));
    });
  });
}
