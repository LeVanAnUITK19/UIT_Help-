import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/themes/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'features/views/auth/login_page.dart';
import 'features/views/home/home_page.dart';
import 'features/viewmodels/auth_viewmodel.dart';
import 'features/viewmodels/post_viewmodel.dart';
import 'features/viewmodels/comment_viewmodel.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/post_repository.dart';
import 'data/repositories/comment_repository.dart';
import 'data/providers/auth_remote_datasource.dart';
import 'data/providers/post_remote_datasource.dart';
import 'data/providers/comment_remote_datasource.dart';
import 'features/viewmodels/locket_viewmodel.dart';
import 'data/repositories/locket_repository.dart';
import 'data/providers/locket_remote_datasource.dart';
import 'features/viewmodels/notification_viewmodel.dart';
import 'data/repositories/notification_repository.dart';
import 'data/providers/notification_remote_datasource.dart';
import 'features/viewmodels/conversation_viewmodel.dart';
import 'data/repositories/conversation_repository.dart';
import 'data/providers/conversation_remote_datasource.dart';
import 'core/constants/dio_client.dart';
import 'core/constants/token_storage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Firebase — chỉ chạy khi đã có google-services.json + firebase_options.dart
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Đăng ký background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Init failed: $e');
    // App vẫn chạy bình thường, chỉ không có push notification
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            AuthRepository(
              AuthRemoteDatasource(DioClient().dio),
              TokenStorage(),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PostViewModel(
            PostRepository(PostRemoteDatasource(DioClient().dio)),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CommentViewModel(
            CommentRepository(CommentRemoteDatasource(DioClient().dio)),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LocketViewModel(
            LocketRepository(LocketRemoteDatasource(DioClient().dio)),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationViewModel(
            NotificationRepository(NotificationRemoteDatasource()),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationViewModel(
            ConversationRepository(ConversationRemoteDatasource()),
          ),
        ),
      ],
      child: const UitHelpApp(),
    ),
  );
}

class UitHelpApp extends StatelessWidget {
  const UitHelpApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    return MaterialApp(
      title: 'UIT Connect',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _setupFcmListeners();
    _checkLogin();
  }

  void _setupFcmListeners() {
    // Foreground: hiển thị snackbar đơn giản
    FcmService.listenForeground(
      onMessage: (message) {
        final title = message.notification?.title ?? '';
        final body = message.notification?.body ?? '';
        if (mounted && (title.isNotEmpty || body.isNotEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title: $body'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );

    // Background tap: có thể navigate sau này
    FcmService.listenOnTap(
      onTap: (message) {
        // TODO: navigate dựa vào message.data['type']
      },
    );
  }

  void _checkLogin() async {
    final token = await TokenStorage().getRefreshToken();
    if (!mounted) return;
    if (token != null) {
      // Fetch lại thông tin user từ server
      await context.read<AuthViewModel>().fetchProfile();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => token != null ? const HomePage() : const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
