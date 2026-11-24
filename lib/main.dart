import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/shell_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/catalog_service.dart';
import 'state/cart_state.dart';
import 'state/wishlist_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final seenWelcome = prefs.getBool(WelcomeScreen.seenKey) ?? false;

  runApp(AmalApp(prefs: prefs, seenWelcome: seenWelcome));
}

class AmalApp extends StatelessWidget {
  const AmalApp({super.key, required this.prefs, required this.seenWelcome});

  final SharedPreferences prefs;
  final bool seenWelcome;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CatalogService>(
          create: (_) => CatalogService(Supabase.instance.client),
        ),
        ChangeNotifierProvider(create: (_) => CartState(prefs)),
        ChangeNotifierProvider(create: (_) => WishlistState(prefs)),
      ],
      child: MaterialApp(
        title: 'AMAL Market Link',
        debugShowCheckedModeBanner: false,
        theme: AmalTheme.light(),
        home: seenWelcome ? const ShellScreen() : const WelcomeScreen(),
      ),
    );
  }
}
