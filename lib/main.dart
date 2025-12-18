import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/transaction_provider.dart';
import 'providers/database_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/account_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found, will use defaults
  }
  
  // Create database provider (but don't initialize yet)
  final databaseProvider = DatabaseProvider();
  
  runApp(MyApp(databaseProvider: databaseProvider));
}

class MyApp extends StatelessWidget {
  final DatabaseProvider databaseProvider;
  
  const MyApp({super.key, required this.databaseProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          return databaseProvider;
        }),
        ChangeNotifierProxyProvider<DatabaseProvider, TransactionProvider>(
          create: (_) {
            return TransactionProvider(databaseProvider);
          },
          update: (_, database, previous) {
            return previous ?? TransactionProvider(database);
          },
        ),
        ChangeNotifierProxyProvider<DatabaseProvider, BudgetProvider>(
          create: (_) {
            return BudgetProvider(databaseProvider);
          },
          update: (_, database, previous) {
            return previous ?? BudgetProvider(database);
          },
        ),
        ChangeNotifierProvider(create: (context) {
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

