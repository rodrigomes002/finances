import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/transactions/data/finance_repository.dart';
import '../features/dashboard/presentation/view/dashboard_page.dart';
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
                const DrawerHeader(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('Finanças'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  selected: _selectedIndex == 0,
                  onTap: () => _selectPage(0),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Upload'),
                  selected: _selectedIndex == 1,
                  onTap: () => _selectPage(1),
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardPage(
              repository: _repository,
              onMenuPressed: _openDrawer,
            ),
            UploadPage(repository: _repository, onMenuPressed: _openDrawer),
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
