import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goals/providers/goals_provider.dart';
import 'package:goals/providers/categories_provider.dart';
import 'package:goals/providers/journal_provider.dart';
import 'package:goals/providers/theme_provider.dart';
import 'package:goals/theme/app_theme.dart';
import 'package:goals/screens/home_screen.dart';

void main() {
  testWidgets('App smoke test - home screen loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => GoalsProvider()),
          ChangeNotifierProvider(create: (_) => CategoriesProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
              themeMode: themeProvider.themeMode,
              home: const HomeScreen(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Goals'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.brightness_6), findsOneWidget);
    expect(find.byIcon(Icons.category), findsOneWidget);
  });
}
