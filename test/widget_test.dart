import 'package:flutter_test/flutter_test.dart';
import 'package:track3_campaign_demo/main.dart';

void main() {
  testWidgets('Campaign form opens', (tester) async {
    await tester.pumpWidget(const CampaignApp());

    expect(find.text('Create your next campaign'), findsOneWidget);
    expect(find.text('Upload product photo'), findsOneWidget);
  });
}
