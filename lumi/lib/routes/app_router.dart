import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../pages/main_tab_page.dart';
import '../pages/character_page.dart';
import '../pages/video_detail_page.dart';
import '../pages/video_create_page.dart';
import '../pages/chat_conversation_page.dart';
import '../pages/recharge_page.dart';
import '../pages/subscribe_page.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  // 创建 router，传入 AuthProvider 以便监听状态变化
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider, // 监听 AuthProvider 的变化
      redirect: (context, state) {
        // 如果还未初始化完成，等待初始化
        if (!authProvider.isInitialized) {
          return null; // 继续当前路由
        }
        
        // 如果已登录，访问登录页时重定向到首页
        if (authProvider.isAuthenticated && state.matchedLocation == '/login') {
          return '/';
        }
        
        // 如果未登录，访问需要登录的页面时重定向到登录页
        if (!authProvider.isAuthenticated && state.matchedLocation != '/login') {
          return '/login';
        }
        
        return null; // 允许访问
      },
      routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainTabPage(),
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
        path: '/chat/:sessionId',
        name: 'chatConversation',
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          return ChatConversationPage(sessionId: sessionId);
        },
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
}

