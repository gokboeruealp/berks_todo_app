import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/todo_provider.dart';
import 'screens/home_screen.dart';
import 'screens/daily_todos_screen.dart';
import 'screens/weekly_todos_screen.dart';
import 'screens/today_specific_todos_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bildirim servisini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(const BerksTodoApp());
}

class BerksTodoApp extends StatelessWidget {
  const BerksTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodoProvider(),
      child: MaterialApp(
        title: 'Berk\'s Todo App',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('tr', 'TR'),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color.fromARGB(255, 148, 192, 213),
            onPrimary: Colors.white,
            onSurface: Colors.white,
            brightness: Brightness.dark,
          ),
          cardTheme: const CardTheme(
            color: Color(0xFF1E1E1E),
          ),
          appBarTheme: const AppBarTheme(
            foregroundColor: Colors.white,
          ),
        ),
        themeMode: ThemeMode.dark,
        home: const MyHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const HomeScreen(),
    const DailyTodosScreen(),
    const WeeklyTodosScreen(),
    const TodaySpecificTodosScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.jumpToPage(
              index,
            );
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.replay),
            label: 'Günlük',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Haftalık',
          ),
          NavigationDestination(
            icon: Icon(Icons.today),
            label: 'Bugüne Özel',
          ),
        ],
      ),
    );
  }
}
