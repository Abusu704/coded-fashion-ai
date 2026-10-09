import 'package:flutter/material.dart';
import 'data/garments/garment_catalog.dart';

void main() {
  runApp(const CatalogTestApp());
}

class CatalogTestApp extends StatelessWidget {
  const CatalogTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tops = GarmentCatalog.getByCategory('tops');
    final bottoms = GarmentCatalog.getByCategory('bottoms');
    final garment = GarmentCatalog.getById('top_101');

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Garment Catalog Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tops: ${tops.length}'),
              Text('Bottoms: ${bottoms.length}'),
              Text('Found: ${garment?.name ?? 'Not found'}'),
            ],
          ),
        ),
      ),
    );
  }
}