import 'package:flutter/material.dart';
import 'core/themes/app_theme.dart';
import 'features/views/auth/login_page.dart';
import 'features/viewmodels/auth_viewmodel.dart';
import './data/repositories/auth_repository.dart';
import './data/providers/auth_remote_datasource.dart';
import './core/constants/dio_client.dart';
import './core/constants/token_storage.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            AuthRepository(
              AuthRemoteDatasource(DioClient().dio),
              TokenStorage(),
            ),
          ),
        ),
      ],
      child: const UitHelpApp(),
    ),
  );
}


class UitHelpApp extends StatefulWidget {
  const UitHelpApp({super.key});

  @override
  State<UitHelpApp> createState() => _UitHelpAppState();
}

class _UitHelpAppState extends State<UitHelpApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UIT Help',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: const LoginPage(),
    );
  }
}
