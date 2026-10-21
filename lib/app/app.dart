import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/widgets/finances_logo.dart';
import '../features/transactions/data/finance_repository.dart';
import '../features/dashboard/presentation/view/dashboard_page.dart';
import '../features/manual_entry/presentation/view/manual_entry_page.dart';
import '../features/upload/presentation/view/upload_page.dart';
import 'theme/app_theme.dart';

class FinancesApp extends StatefulWidget {
  const FinancesApp({super.key, this.repository});

  final FinanceRepository? repository;

  @override
  State<FinancesApp> createState() => _FinancesAppState();
}

class _FinancesAppState extends State<FinancesApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late final FinanceRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SqliteFinanceRepository();
  }

  @override
  Widget build(BuildContext context) {
    const locale = Locale('pt', 'BR');
    final colors = AppTheme.light.colorScheme;

    return MaterialApp(
      title: 'Finanças',
      locale: locale,
      supportedLocales: const [locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      home: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const FinancesLogo(size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Finanças',
                          style: AppTheme.light.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Seu dinheiro, sob controle',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    _selectedIndex == 0
                        ? Icons.space_dashboard
                        : Icons.space_dashboard_outlined,
                  ),
                  title: const Text('Dashboard'),
                  selected: _selectedIndex == 0,
                  selectedTileColor: colors.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  onTap: () => _selectPage(0),
                ),
                ListTile(
                  leading: Icon(
                    _selectedIndex == 1
                        ? Icons.file_upload
                        : Icons.file_upload_outlined,
                  ),
                  title: const Text('Upload'),
                  selected: _selectedIndex == 1,
                  selectedTileColor: colors.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  onTap: () => _selectPage(1),
                ),
                ListTile(
                  leading: Icon(
                    _selectedIndex == 2
                        ? Icons.add_card
                        : Icons.add_card_outlined,
                  ),
                  title: const Text('Lançamento manual'),
                  selected: _selectedIndex == 2,
                  selectedTileColor: colors.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  onTap: () => _selectPage(2),
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardPage(repository: _repository, onMenuPressed: _openDrawer),
            UploadPage(repository: _repository, onMenuPressed: _openDrawer),
            ManualEntryPage(
              repository: _repository,
              onMenuPressed: _openDrawer,
            ),
          ],
        ),
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    _scaffoldKey.currentState?.closeDrawer();
  }
}
