import 'package:finances/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets('navigates between dashboard and upload', (tester) async {
    await tester.pumpWidget(const FinancesApp());
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Envie seus arquivos'), findsNothing);

    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(find.text('Envie seus arquivos'), findsOneWidget);
    expect(find.text('Visão geral'), findsNothing);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Envie seus arquivos'), findsNothing);
  });
}
