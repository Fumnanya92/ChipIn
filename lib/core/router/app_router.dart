import 'package:chipin/features/auth/presentation/pages/splash_screen.dart';
import 'package:chipin/features/auth/presentation/pages/login_screen.dart';
import 'package:chipin/features/auth/presentation/pages/signup_screen.dart';
import 'package:chipin/features/auth/presentation/pages/otp_screen.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/escrow/presentation/pages/dispute_screen.dart';
import 'package:chipin/features/escrow/presentation/pages/escrow_deposit_screen.dart';
import 'package:chipin/features/escrow/presentation/pages/escrow_status_screen.dart';
import 'package:chipin/features/reviews/presentation/pages/submit_review_screen.dart';
import 'package:chipin/features/matches/presentation/pages/smart_match_screen.dart';
import 'package:chipin/features/groups/presentation/pages/neighborhood_groups_screen.dart';
import 'package:chipin/features/home/presentation/pages/latest_feed_screen.dart';
import 'package:chipin/features/home/presentation/pages/home_screen.dart';
import 'package:chipin/features/listings/presentation/pages/browse_screen.dart';
import 'package:chipin/features/listings/presentation/pages/listing_detail_screen.dart';
import 'package:chipin/features/matches/presentation/pages/matches_screen.dart';
import 'package:chipin/features/messages/presentation/pages/chat_screen.dart';
import 'package:chipin/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:chipin/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:chipin/features/post/presentation/pages/post_category_screen.dart';
import 'package:chipin/features/post/presentation/pages/post_details_screen.dart';
import 'package:chipin/features/post/presentation/pages/post_extras_screen.dart';
import 'package:chipin/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:chipin/features/profile/presentation/pages/profile_screen.dart';
import 'package:chipin/features/verification/presentation/pages/verification_screen.dart';
import 'package:chipin/features/verification/presentation/pages/verification_intro_screen.dart';
import 'package:chipin/features/verification/presentation/pages/id_upload_screen.dart';
import 'package:chipin/features/verification/presentation/pages/selfie_verification_screen.dart';
import 'package:chipin/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' ||
          loc == '/signup' ||
          loc == '/otp' ||
          loc == '/onboarding' ||
          loc == '/splash';
      final isPublicRoute = loc == '/latest-feed';

      if (!isAuthenticated && !isAuthRoute && !isPublicRoute) {
        return '/login';
      }
      return null;
    },
    routes: [
      // ── Auth / onboarding (no shell) ──────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return OtpScreen(
            phoneNumber: extra?['phone'] ?? '',
            fullName: extra?['fullName'] ?? '',
            email: extra?['email'] ?? '',
            password: extra?['password'] ?? '',
          );
        },
      ),

      // ── Push / modal routes (no persistent bottom nav) ────────────────────
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) =>
            ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post/category',
        builder: (context, state) => const PostCategoryScreen(),
      ),
      GoRoute(
        path: '/post/details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PostDetailsScreen(category: extra?['category'] as String?);
        },
      ),
      GoRoute(
        path: '/post/extras',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PostExtrasScreen(listingData: extra ?? {});
        },
      ),
      GoRoute(
        path: '/chat/:matchId',
        builder: (context, state) =>
            ChatScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) =>
            ProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/me/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/verify/intro',
        builder: (context, state) => const VerificationIntroScreen(),
      ),
      GoRoute(
        path: '/verify/id-upload',
        builder: (context, state) => const IdUploadScreen(),
      ),
      GoRoute(
        path: '/verify/selfie',
        builder: (context, state) => const SelfieVerificationScreen(),
      ),
      GoRoute(
        path: '/pay/:matchId',
        builder: (context, state) =>
            EscrowDepositScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/escrow/:matchId',
        builder: (context, state) =>
            EscrowStatusScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/dispute/:matchId',
        builder: (context, state) =>
            DisputeScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/review/:matchId',
        builder: (context, state) =>
            SubmitReviewScreen(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/smart-match',
        builder: (context, state) => const SmartMatchScreen(),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const NeighborhoodGroupsScreen(),
      ),
      GoRoute(
        path: '/latest-feed',
        builder: (context, state) => const LatestFeedScreen(),
      ),

      // ── Main shell with persistent bottom nav ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/browse',
              builder: (context, state) => const BrowseScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/matches',
              builder: (context, state) => const MatchesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/me',
              builder: (context, state) => const ProfileScreen(userId: 'me'),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
