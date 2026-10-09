class Garment {
  final String id;
  final String category;
  final String name;
  final String imagePath;
  final String? maskPath;

  const Garment({
    required this.id,
    required this.category,
    required this.name,
    required this.imagePath,
    this.maskPath,
  });
}