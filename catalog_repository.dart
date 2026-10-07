import '../models/models.dart';

/// TODO(C): implement with the real garment catalog JSON
/// (images, categories, mask data). A only needs id/category/url/name.
abstract class CatalogRepository {
  Future<List<Garment>> loadCatalog();
}

class MockCatalogRepository implements CatalogRepository {
  static String _img(String bg, String label) =>
      'https://placehold.co/600x800/$bg/222222/png?text=$label';

  @override
  Future<List<Garment>> loadCatalog() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return [
      Garment(id: 'top_101', category: 'tops', name: 'Classic Tee', url: _img('F4E1D2', 'Tee')),
      Garment(id: 'top_102', category: 'tops', name: 'Denim Jacket', url: _img('A7C7E7', 'Denim')),
      Garment(id: 'top_103', category: 'tops', name: 'Cozy Hoodie', url: _img('D6C1F0', 'Hoodie')),
      Garment(id: 'top_104', category: 'tops', name: 'Linen Shirt', url: _img('CDE8C9', 'Linen')),
      Garment(id: 'btm_201', category: 'bottoms', name: 'Slim Jeans', url: _img('9EB7D9', 'Jeans')),
      Garment(id: 'btm_202', category: 'bottoms', name: 'Chino Shorts', url: _img('F2D6A2', 'Shorts')),
      Garment(id: 'btm_203', category: 'bottoms', name: 'Pleated Skirt', url: _img('F5B5CF', 'Skirt')),
      Garment(id: 'btm_204', category: 'bottoms', name: 'Joggers', url: _img('BFC5CC', 'Joggers')),
    ];
  }
}
