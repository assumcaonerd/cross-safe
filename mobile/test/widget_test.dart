import 'package:flutter_test/flutter_test.dart';

import 'package:cross_safe/app.dart';

void main() {
  testWidgets('CrossSafe home renders the monitoring entry point', (tester) async {
    await tester.pumpWidget(const CrossSafeApp());

    expect(find.text('CrossSafe'), findsOneWidget);
    expect(find.text('Ativar alerta de faixa'), findsOneWidget);
    expect(find.text('Pedestre'), findsOneWidget);
  });
}
