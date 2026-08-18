import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sakan_app/core/storage/storage_service.dart';
import 'package:sakan_app/core/theme/app_theme.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakan_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sakan_app/shared/widgets/bottom_nav_bar.dart';
import 'package:sakan_app/features/properties/presentation/screens/home_screen.dart';
import 'package:sakan_app/features/properties/presentation/screens/search_screen.dart';
import 'package:sakan_app/features/properties/presentation/screens/favorites_screen.dart';
import 'package:sakan_app/features/properties/presentation/screens/my_listings_screen.dart';
import 'package:sakan_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:sakan_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:sakan_app/features/admin/presentation/screens/pending_listings_screen.dart';
import 'package:sakan_app/features/admin/presentation/screens/platform_settings_screen.dart';
import 'package:sakan_app/features/admin/presentation/screens/users_management_screen.dart';
import 'package:sakan_app/features/admin/presentation/screens/send_notification_screen.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/payment/presentation/screens/payment_history_screen.dart';
import 'package:sakan_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sakan_app/core/providers/app_mode_provider.dart';
import 'package:sakan_app/features/properties/presentation/screens/create_listing_screen.dart';
import 'package:sakan_app/core/services/push_notification_service.dart';
import 'package:sakan_app/features/admin/presentation/screens/payments_review_screen.dart';
import 'package:sakan_app/features/admin/presentation/screens/reports_management_screen.dart';
import 'package:google_fonts/google_fonts.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(StorageService(prefs)),
      ],
      child: const SakanApp(),
    ),
  );
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    final isDark = _ref.read(storageServiceProvider).getThemeMode();
    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void toggleTheme() {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    _ref.read(storageServiceProvider).setThemeMode(!isDark);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;
  LocaleNotifier(this._ref) : super(const Locale('ar')) {
    final lang = _ref.read(storageServiceProvider).getLanguage();
    if (lang != null) {
      state = Locale(lang);
    }
  }

  void setLocale(String langCode) {
    state = Locale(langCode);
    _ref.read(storageServiceProvider).setLanguage(langCode);
  }
}

class SakanApp extends ConsumerStatefulWidget {
  const SakanApp({super.key});

  @override
  ConsumerState<SakanApp> createState() => _SakanAppState();
}

class _SakanAppState extends ConsumerState<SakanApp> {
  @override
  void initState() {
    super.initState();
    // تهيئة الإشعارات بعد أول Frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final authState = ref.watch(authProvider);



    return MaterialApp(
      title: 'Aqaro',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authState.isLoading 
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Check if authenticated first
    if (authState.isAuthenticated) {
      if (authState.user?.role == 'Admin') {
        return const AdminDashboardShell();
      }
      return const UserNavigationShell();
    }

    // If not authenticated, we treat them as a guest by default
    // The GuestPromptCard in specific screens will handle the login requirement
    return const UserNavigationShell();
  }
}

class UserNavigationShell extends ConsumerStatefulWidget {
  const UserNavigationShell({super.key});

  @override
  ConsumerState<UserNavigationShell> createState() => _UserNavigationShellState();
}

class _UserNavigationShellState extends ConsumerState<UserNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);
    final isHosting = mode == AppMode.hosting;

    // Reset index when switching modes to avoid confusion
    ref.listen(appModeProvider, (previous, next) {
      if (previous != next) {
        setState(() => _currentIndex = 0);
      }
    });

    final List<Widget> rentingScreens = [
      const HomeScreen(),
      const SearchScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];

    final List<Widget> hostingScreens = [
      const MyListingsScreen(),
      const PaymentHistoryScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    final screens = isHosting ? hostingScreens : rentingScreens;

    return Scaffold(
      body: IndexedStack(
        key: ValueKey(mode),
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _currentIndex = 0;

    final List<Widget> _screens = [
      const AdminDashboardScreen(),
      const PendingListingsScreen(),
      const PaymentsReviewScreen(),
      const ReportsManagementScreen(),
      const UsersManagementScreen(),
      const PlatformSettingsScreen(),
      const SendNotificationScreen(),
    ];

  final List<String> _titles = const [
    'admin_dashboard',
    'pending_listings',
    'payments',
    'reports',
    'users',
    'settings',
    'send_notification',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.translate(_titles[_currentIndex]))),
      drawer: Consumer(
        builder: (context, ref, child) => Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: Text(
                  '${context.translate('app_title')} Admin',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 24),
                ),
              ),
              _buildDrawerItem(0, Icons.dashboard, context.translate('admin_dashboard')),
              _buildDrawerItem(1, Icons.pending_actions, context.translate('pending_listings')),
              _buildDrawerItem(2, Icons.payment, context.translate('payments')),
              _buildDrawerItem(3, Icons.report_problem, context.translate('reports')),
              _buildDrawerItem(4, Icons.people, context.translate('users')),
              _buildDrawerItem(5, Icons.settings, context.translate('settings')),
              _buildDrawerItem(6, Icons.notifications_active, context.translate('send_notification')),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(context.translate('logout')),
                onTap: () => ref.read(authProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
      body: _screens[_currentIndex],
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _currentIndex == index ? Theme.of(context).colorScheme.primary : null),
      title: Text(title, style: TextStyle(color: _currentIndex == index ? Theme.of(context).colorScheme.primary : null)),
      selected: _currentIndex == index,
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
