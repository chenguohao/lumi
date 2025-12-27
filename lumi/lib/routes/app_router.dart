import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/character_page.dart';
import '../pages/video_detail_page.dart';
import '../pages/video_create_page.dart';
import '../pages/chat_session_page.dart';
import '../pages/chat_conversation_page.dart';
import '../pages/profile_page.dart';
import '../pages/recharge_page.dart';
import '../pages/subscribe_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/character/:id',
        name: 'character',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CharacterPage(characterId: id);
        },
      ),
      GoRoute(
        path: '/video/:id',
        name: 'video',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return VideoDetailPage(videoId: id);
        },
      ),
      GoRoute(
        path: '/video/create',
        name: 'videoCreate',
        builder: (context, state) => const VideoCreatePage(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatSessionPage(),
      ),
      GoRoute(
        path: '/chat/:sessionId',
        name: 'chatConversation',
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          return ChatConversationPage(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/recharge',
        name: 'recharge',
        builder: (context, state) => const RechargePage(),
      ),
      GoRoute(
        path: '/subscribe',
        name: 'subscribe',
        builder: (context, state) => const SubscribePage(),
      ),
    ],
  );
}

