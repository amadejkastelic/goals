import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'providers/goals_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/custom_fields_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final notificationProvider = NotificationProvider();
  await notificationProvider.initialize();

  runApp(MyApp(notificationProvider: notificationProvider));
}

class MyApp extends StatelessWidget {
  final NotificationProvider notificationProvider;

  const MyApp({super.key, required this.notificationProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GoalsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => CustomFieldsProvider()),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const NotificationConnector(child: ThemedApp()),
    );
  }
}

class NotificationConnector extends StatefulWidget {
  final Widget child;

  const NotificationConnector({super.key, required this.child});

  @override
  State<NotificationConnector> createState() => _NotificationConnectorState();
}

class _NotificationConnectorState extends State<NotificationConnector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCallbacks();
    });
  }

  void _setupCallbacks() {
    final goalsProvider = context.read<GoalsProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    goalsProvider.onGoalChanged = (goal) {
      notificationProvider.updateGoalNotifications(goal);
    };

    goalsProvider.onGoalDeleted = (goalId) {
      notificationProvider.removeAllNotifications();
      notificationProvider.refreshAllNotifications(goalsProvider.activeGoals);
    };

    goalsProvider.onGoalsLoaded = () {
      notificationProvider.refreshAllNotifications(goalsProvider.goals);
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ThemedApp extends StatelessWidget {
  const ThemedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              themeProvider.setDynamicColorSchemes(lightDynamic, darkDynamic);
            });

            final lightTheme =
                themeProvider.useDynamicColors &&
                    themeProvider.dynamicLightColorScheme != null
                ? AppTheme.fromColorScheme(
                    themeProvider.dynamicLightColorScheme!,
                    Brightness.light,
                  )
                : AppTheme.lightTheme();

            final darkTheme =
                themeProvider.useDynamicColors &&
                    themeProvider.dynamicDarkColorScheme != null
                ? AppTheme.fromColorScheme(
                    themeProvider.dynamicDarkColorScheme!,
                    Brightness.dark,
                  )
                : AppTheme.darkTheme();

            return MaterialApp(
              title: 'Goals',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              routes: {
                '/': (_) => const HomeScreen(),
                '/categories': (_) => const CategoriesScreen(),
              },
              initialRoute: '/',
            );
          },
        );
      },
    );
  }
}
