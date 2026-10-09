import '../data/garments/garments.dart';

class TryOnState {
  String? modelImage;
  Garment? selectedGarment;
  bool fallbackMode;
  final List<String> generatedOutputs;

  TryOnState({
    this.modelImage,
    this.selectedGarment,
    this.fallbackMode = false,
    List<String>? generatedOutputs,
  }) : generatedOutputs = generatedOutputs ?? [];

  void setModelImage(String image) {
    modelImage = image;
    generatedOutputs.clear();
    fallbackMode = false;
  }

  void selectGarment(Garment garment) {
    selectedGarment = garment;
  }

  void addOutput(String output) {
    generatedOutputs.add(output);
  }

  void setFallbackMode(bool value) {
    fallbackMode = value;
  }

  void reset() {
    modelImage = null;
    selectedGarment = null;
    fallbackMode = false;
    generatedOutputs.clear();
  }
}