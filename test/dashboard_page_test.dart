import 'package:finances/features/dashboard/presentation/view/dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets('shows the initial personal finance overview', (tester) async {
    await tester.pumpWidget(const ShadApp(home: DashboardPage()));

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Saldo disponível'), findsOneWidget);
    expect(find.text('Despesas deste mês'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNWidgets(2));
    expect(find.text('Seus lançamentos aparecerão aqui.'), findsOneWidget);
  });
}
