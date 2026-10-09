import 'package:flutter_test/flutter_test.dart';
import 'package:coded_fashion_ai/data/garments/garment_catalog.dart';
import 'package:coded_fashion_ai/state/try_on_state.dart';

void main() {
  test('selects a garment', () {
    final state = TryOnState();
    final garment = GarmentCatalog.getById('top_101');

    state.selectGarment(garment!);

    expect(state.selectedGarment?.id, 'top_101');
  });

  test('new model image clears previous outputs', () {
    final state = TryOnState();

    state.addOutput('result_1');
    state.setModelImage('model_1');

    expect(state.modelImage, 'model_1');
    expect(state.generatedOutputs, isEmpty);
  });

  test('adds generated output', () {
    final state = TryOnState();

    state.addOutput('result_1');

    expect(state.generatedOutputs.length, 1);
    expect(state.generatedOutputs.first, 'result_1');
  });

  test('reset clears the state', () {
    final state = TryOnState();
    final garment = GarmentCatalog.getById('top_101');

    state.setModelImage('model_1');
    state.selectGarment(garment!);
    state.addOutput('result_1');
    state.fallbackMode = true;

    state.reset();

    expect(state.modelImage, isNull);
    expect(state.selectedGarment, isNull);
    expect(state.fallbackMode, false);
    expect(state.generatedOutputs, isEmpty);
  });
}