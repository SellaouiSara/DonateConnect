import 'package:firebase_core/firebase_core.dart';
import 'package:donation_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/choose_role_page.dart';
import 'pages/auth/org_details_page.dart';
import 'pages/auth/org_upload_page.dart';
import 'pages/auth/pending_page.dart';
import 'pages/home_page.dart';
import 'pages/item_detail_page.dart';
import 'pages/post_donation_page.dart';
import 'pages/request_help_page.dart';
import 'pages/chat_page.dart';
import 'pages/profile_page.dart';
import 'pages/admin_page.dart';
import 'pages/waiting_list_page.dart';
import 'pages/causes_page.dart';
import 'pages/post_cause_page.dart';
import 'pages/impact_report_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/impact_reports_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDFAF5),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/choose-role': (context) => const ChooseRolePage(),
        '/org-details': (context) => const OrgDetailsPage(),
        '/org-upload': (context) => const OrgUploadPage(),
        '/pending': (context) => const PendingPage(),
        '/home': (context) => const HomePage(),
        '/post-donation': (context) => const PostDonationPage(),
        '/request-help': (context) => const RequestHelpPage(),
        '/profile': (context) => const ProfilePage(),
        '/admin': (context) => const AdminPage(),
        '/waiting-list': (context) => const WaitingListPage(),
        '/causes': (context) => const CausesPage(),
        '/post-cause': (context) => const PostCausePage(),
        '/impact-report': (context) => const ImpactReportPage(causeName: '', orgName: ''),
        '/edit-profile': (context) => const EditProfilePage(),
        '/impact-reports': (context) => const ImpactReportsListPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/item-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: args, itemId: args['id'] as String?),
          );
        }
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatPage(
              donorName: args['donorName']!,
              recipientId: args['recipientId'] ?? args['donorId']!,
              isOwner: args['isOwner'] ?? false,
            ),
          );
        }
        return null;
      },
    );
  }
}
