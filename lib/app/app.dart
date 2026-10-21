import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../features/dashboard/presentation/view/dashboard_page.dart';
import '../features/upload/presentation/view/upload_page.dart';
import 'theme/app_theme.dart';

class FinancesApp extends StatefulWidget {
  const FinancesApp({super.key});

  @override
  State<FinancesApp> createState() => _FinancesAppState();
}

class _FinancesAppState extends State<FinancesApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const locale = Locale('pt', 'BR');

    return ShadApp(
      title: 'Finanças',
      locale: locale,
      supportedLocales: const [locale],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: const [DashboardPage(), UploadPage()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.upload_file_outlined),
              selectedIcon: Icon(Icons.upload_file),
              label: 'Upload',
            ),
          ],
        ),
      ),
    );
  }
}
