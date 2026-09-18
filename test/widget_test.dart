import 'package:flutter_test/flutter_test.dart';
import 'package:waseem_medical_pro/app.dart';

void main() {
  testWidgets('Waseem Medical starts', (tester) async {
    await tester.pumpWidget(const WaseemMedicalApp());
    expect(find.text('وسيم ميديكال'), findsOneWidget);
  });
}
