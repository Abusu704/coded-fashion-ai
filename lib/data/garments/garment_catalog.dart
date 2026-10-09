import 'garments.dart';

class GarmentCatalog {
  static const List<Garment> garments = [
    Garment(
      id: 'top_101',
      category: 'tops',
      name: 'Black T-Shirt',
      imagePath: 'assets/garments/tops/top_101.png',
      maskPath: 'assets/masks/top_101.png',
    ),
    Garment(
      id: 'top_102',
      category: 'tops',
      name: 'White T-Shirt',
      imagePath: 'assets/garments/tops/top_102.png',
      maskPath: 'assets/masks/top_102.png',
    ),
    Garment(
      id: 'top_103',
      category: 'tops',
      name: 'Blue Shirt',
      imagePath: 'assets/garments/tops/top_103.png',
      maskPath: 'assets/masks/top_103.png',
    ),
    Garment(
      id: 'top_104',
      category: 'tops',
      name: 'Red Hoodie',
      imagePath: 'assets/garments/tops/top_104.png',
      maskPath: 'assets/masks/top_104.png',
    ),
    Garment(
      id: 'top_105',
      category: 'tops',
      name: 'Green Polo',
      imagePath: 'assets/garments/tops/top_105.png',
      maskPath: 'assets/masks/top_105.png',
    ),
    Garment(
      id: 'bottom_201',
      category: 'bottoms',
      name: 'Blue Jeans',
      imagePath: 'assets/garments/bottoms/bottom_201.png',
      maskPath: 'assets/masks/bottom_201.png',
    ),
    Garment(
      id: 'bottom_202',
      category: 'bottoms',
      name: 'Black Trousers',
      imagePath: 'assets/garments/bottoms/bottom_202.png',
      maskPath: 'assets/masks/bottom_202.png',
    ),
    Garment(
      id: 'bottom_203',
      category: 'bottoms',
      name: 'Grey Joggers',
      imagePath: 'assets/garments/bottoms/bottom_203.png',
      maskPath: 'assets/masks/bottom_203.png',
    ),
    Garment(
      id: 'bottom_204',
      category: 'bottoms',
      name: 'Khaki Pants',
      imagePath: 'assets/garments/bottoms/bottom_204.png',
      maskPath: 'assets/masks/bottom_204.png',
    ),
    Garment(
      id: 'bottom_205',
      category: 'bottoms',
      name: 'White Shorts',
      imagePath: 'assets/garments/bottoms/bottom_205.png',
      maskPath: 'assets/masks/bottom_205.png',
    ),
  ];

  static List<Garment> getByCategory(String category) {
    return garments
        .where((garment) => garment.category == category)
        .toList();
  }

  static Garment? getById(String id) {
    for (final garment in garments) {
      if (garment.id == id) {
        return garment;
      }
    }

    return null;
  }
}