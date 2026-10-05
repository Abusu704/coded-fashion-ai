import 'package:flutter_test/flutter_test.dart';
import 'package:coded_fashion_ai/data/garments/garment_catalog.dart';

void main() {
  test('garment catalog loads correctly', () {
    final tops = GarmentCatalog.getByCategory('tops');
    final bottoms = GarmentCatalog.getByCategory('bottoms');
    final garment = GarmentCatalog.getById('top_101');

    expect(tops.length, 5);
    expect(bottoms.length, 5);
    expect(garment?.name, 'Black T-Shirt');
  });
}