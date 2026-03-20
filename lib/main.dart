import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'database/database_factory_setup.dart';
import 'managers/auth_manager.dart';
import 'managers/auth_wrapper.dart';
import 'screens/home_page.dart';
import 'screens/task_list_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/pet_selection_page.dart';
import 'screens/background_info_page.dart';
import 'screens/ability_assessment_page.dart';
import 'screens/ability_evaluation_page.dart';
import 'screens/social_challenge_page.dart';

import 'screens/notification_settings_page.dart';
import 'screens/admin_page.dart';
import 'screens/incentive_page.dart';
import 'screens/evaluation_report_page.dart';
import 'screens/learning_center_page.dart';
import 'screens/main_navigation_page.dart';
import 'screens/data_statistics_page.dart';
import 'screens/user_segmentation_page.dart';
import 'screens/teacher_dashboard_page.dart';
import 'screens/parent_dashboard_page.dart';
import 'screens/items_page.dart';
import 'screens/pet_advance_page.dart';
import 'pages/splash_page.dart';
import 'providers/app_state_provider.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppStateProvider.instance),
        ChangeNotifierProvider(create: (context) => AuthManager.instance),
      ],
      child: MaterialApp(
        title: '宠物养成任务管理',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          buttonTheme: const ButtonThemeData(
            buttonColor: Colors.blue,
            textTheme: ButtonTextTheme.primary,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
            bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
            bodySmall: TextStyle(fontSize: 12, color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        themeMode: ThemeMode.light,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forgot_password': (context) => const ForgotPasswordPage(),
          '/pet_selection': (context) => const PetSelectionPage(),
          '/evaluation-report': (context) => AuthWrapper(child: const EvaluationReportPage(), requirePet: true),
          '/home': (context) => AuthWrapper(child: const MainNavigationPage(), requirePet: true),
          '/tasks': (context) => AuthWrapper(child: const TaskListPage(), requirePet: true),
          '/learning_center': (context) => AuthWrapper(child: const LearningCenterPage(), requirePet: true),
          '/background': (context) => const BackgroundInfoPage(),
          '/ability': (context) => AuthWrapper(child: const AbilityEvaluationPage(), requirePet: true),
          '/social': (context) => AuthWrapper(child: const SocialChallengePage(), requirePet: true),

          '/notification_settings': (context) => AuthWrapper(child: const NotificationSettingsPage(), requirePet: true),
          '/incentive': (context) => AuthWrapper(child: const IncentivePage(), requirePet: true),
          '/data_statistics': (context) => AuthWrapper(child: const DataStatisticsPage(), requirePet: true),
          '/user_segmentation': (context) => AuthWrapper(child: const UserSegmentationPage(), requirePet: true),
          '/teacher_dashboard': (context) => const TeacherDashboardPage(),
          '/parent_dashboard': (context) => const ParentDashboardPage(),
          '/items': (context) => AuthWrapper(child: const ItemsPage(), requirePet: true),
          '/pet_advance': (context) => AuthWrapper(child: const PetAdvancePage(), requirePet: true),
          '/admin': (context) => const AdminPage(),
        },
      ),
    );
  }
}