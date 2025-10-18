import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/transaction_provider.dart';
import 'providers/database_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/account_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  print('Main: Starting app initialization...');
  WidgetsFlutterBinding.ensureInitialized();
  print('Main: Flutter binding initialized');
  
  // Create database provider (but don't initialize yet)
  print('Main: Creating DatabaseProvider...');
  final databaseProvider = DatabaseProvider();
  print('Main: Database provider created');
  
  print('Main: Starting app...');
  runApp(MyApp(databaseProvider: databaseProvider));
}

class MyApp extends StatelessWidget {
  final DatabaseProvider databaseProvider;
  
  const MyApp({super.key, required this.databaseProvider});

  @override
  Widget build(BuildContext context) {
    print('MyApp: Building app with providers...');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print('MyApp: Creating DatabaseProvider');
          return databaseProvider;
        }),
        ChangeNotifierProxyProvider<DatabaseProvider, TransactionProvider>(
          create: (_) {
            print('MyApp: Creating TransactionProvider');
            return TransactionProvider(databaseProvider);
          },
          update: (_, database, previous) {
            print('MyApp: Updating TransactionProvider');
            return previous ?? TransactionProvider(database);
          },
        ),
        ChangeNotifierProxyProvider<DatabaseProvider, BudgetProvider>(
          create: (_) {
            print('MyApp: Creating BudgetProvider');
            return BudgetProvider(databaseProvider);
          },
          update: (_, database, previous) {
            print('MyApp: Updating BudgetProvider');
            return previous ?? BudgetProvider(database);
          },
        ),
        ChangeNotifierProvider(create: (context) {
          print('MyApp: Creating AccountProvider');
          final accountProvider = AccountProvider();
          accountProvider.setDatabaseProvider(databaseProvider);
          
          // Set provider references immediately
          final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
          final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
          accountProvider.setTransactionProvider(transactionProvider);
          accountProvider.setBudgetProvider(budgetProvider);
          
          return accountProvider;
        }),
      ],
      child: MaterialApp(
        title: 'Pezo - Never run out of Pesos',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

