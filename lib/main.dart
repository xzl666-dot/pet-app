import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'database/database_factory_setup.dart';
import 'managers/auth_manager.dart';
import 'managers/auth_wrapper.dart';
import 'screens/home_page.dart';
import 'screens/task_list_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/pet_selection_page.dart';
import 'screens/background_info_page.dart';
import 'screens/ability_assessment_page.dart';
import 'screens/social_challenge_page.dart';
import 'screens/ai_mental_assistant_page.dart';
import 'screens/notification_settings_page.dart';
import 'screens/admin_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Setup database factory for platform compatibility
    await setupDatabaseFactory();
    print('Database factory setup completed');
  } catch (e) {
    print('Error setting up database factory: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '宠物养成任务管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.blue,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.blue,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/pet_selection': (context) => const PetSelectionPage(),
        '/home': (context) => AuthWrapper(child: const HomePage(), requirePet: true),
        '/tasks': (context) => AuthWrapper(child: const TaskListPage(), requirePet: true),
        '/background': (context) => const BackgroundInfoPage(),
        '/ability': (context) => AuthWrapper(child: const AbilityAssessmentPage(), requirePet: true),
        '/social': (context) => AuthWrapper(child: const SocialChallengePage(), requirePet: true),
        '/ai_assistant': (context) => AuthWrapper(child: const AIMentalAssistantPage(), requirePet: true),
        '/notification_settings': (context) => AuthWrapper(child: const NotificationSettingsPage(), requirePet: true),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}