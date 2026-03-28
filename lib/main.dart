import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/movie_model.dart';
import 'services/storage_service.dart';
import 'services/download_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D0D),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  Hive.registerAdapter(MovieAdapter());
  Hive.registerAdapter(StreamSourceAdapter());
  Hive.registerAdapter(CastMemberAdapter());
  Hive.registerAdapter(WatchHistoryEntryAdapter());

  await StorageService.init();
  await DownloadService().init();

  runApp(const CineVaultApp());
}

class CineVaultApp extends StatelessWidget {
  const CineVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    WatchlistScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      ['Home', '0xe88a', '0xe425'],
      ['Search', '0xe8b6', '0xef4a'],
      ['My List', '0xe866', '0xe865'],
      ['Downloads', '0xf090', '0xf090'],
      ['Settings', '0xe8b8', '0xe8b8'],
    ];
    final icons = [
      [Icons.home_outlined, Icons.home_rounded],
      [Icons.search_outlined, Icons.search_rounded],
      [Icons.bookmark_border_rounded, Icons.bookmark_rounded],
      [Icons.download_outlined, Icons.download_rounded],
      [Icons.settings_outlined, Icons.settings_rounded],
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(5, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? icons[i][1] : icons[i][0],
                        color: selected ? AppTheme.accent : AppTheme.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i][0],
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected ? AppTheme.accent : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
