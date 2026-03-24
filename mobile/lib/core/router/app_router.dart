import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/domain/models/auth_models.dart';
import '../../features/home/presentation/screens/customer_home_screen.dart';
import '../../features/home/presentation/screens/technician_home_screen.dart';
import '../../features/booking/presentation/screens/create_booking_screen.dart';
import '../../features/booking/presentation/screens/booking_detail_screen.dart';
import '../../features/booking/presentation/screens/receipt_screen.dart';
import '../../features/booking/presentation/screens/bookings_list_screen.dart';
import '../../features/booking/presentation/screens/booking_search_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/ratings/presentation/screens/rating_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/support/presentation/screens/create_ticket_screen.dart';
import '../../features/support/presentation/screens/ticket_detail_screen.dart';
import '../../features/technician/presentation/screens/technician_waiting_screen.dart';
import '../../features/technician/presentation/screens/technician_registration_screen.dart';
import '../../features/technician/presentation/screens/verification_flow_screen.dart';
import '../../features/technician/presentation/screens/technician_services_screen.dart';
import '../../features/technician/presentation/screens/service_selector_screen.dart';
import '../../features/technician/presentation/screens/location_selector_screen.dart';
import '../../features/technician/presentation/screens/technician_requests_screen.dart';
import '../../features/auth/presentation/screens/property_type_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/addresses/presentation/screens/add_address_screen.dart';
import '../../features/addresses/presentation/screens/addresses_list_screen.dart';
import '../widgets/main_scaffold.dart';

/// Notifier that tells GoRouter to re-evaluate its redirect
/// whenever the auth state changes, WITHOUT recreating the router.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;

      final isOnAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/otp') ||
          state.matchedLocation.startsWith('/splash') ||
          state.matchedLocation.startsWith('/select-property-type');

      // While loading, don't redirect — let the current page stay
      if (isLoading) return null;

      if (!isLoggedIn && !isOnAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isOnAuthRoute) {
        final role = authState.user?.role ?? 'customer';
        if (role == 'technician') {
          if (authState.user?.technicianApproved == false) {
            return '/technician-waiting';
          }
          return '/technician';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => SplashScreen(
          onFinished: () {
            final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
            if (isLoggedIn) {
              final role = ref.read(authStateProvider).user?.role ?? 'customer';
              if (role == 'technician') {
                return '/technician';
              }
              return '/home';
            }
            return '/login';
          },
        ),
      ),
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            phone: extra?['phone'] ?? '',
            purpose: extra?['purpose'] ?? 'login',
          );
        },
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/select-property-type',
        name: 'select-property-type',
        builder: (context, state) => const PropertyTypeScreen(),
      ),

      // Technician waiting for approval
      GoRoute(
        path: '/technician-waiting',
        name: 'technician-waiting',
        builder: (context, state) => const TechnicianWaitingScreen(),
      ),
      GoRoute(
        path: '/technician-registration',
        name: 'technician-registration',
        builder: (context, state) => const TechnicianRegistrationScreen(),
      ),

      // Technician verification flow
      GoRoute(
        path: '/technician/verification',
        name: 'technician-verification',
        builder: (context, state) => const VerificationFlowScreen(),
      ),
      GoRoute(
        path: '/technician/my-services',
        name: 'technician-my-services',
        builder: (context, state) => const TechnicianServicesScreen(),
      ),
      GoRoute(
        path: '/technician/add-services',
        name: 'technician-add-services',
        builder: (context, state) => ServiceSelectorScreen(
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
      GoRoute(
        path: '/technician/add-locations',
        name: 'technician-add-locations',
        builder: (context, state) => LocationSelectorScreen(
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
      GoRoute(
        path: '/technician/requests',
        name: 'technician-requests',
        builder: (context, state) => const TechnicianRequestsScreen(),
      ),

      // Customer main shell
      ShellRoute(
        builder: (context, state, child) => MainScaffold(
          role: 'customer',
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            name: 'customer-home',
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: '/bookings',
            name: 'customer-bookings',
            builder: (context, state) => const BookingsListScreen(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'customer-wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'customer-settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Technician main shell
      ShellRoute(
        builder: (context, state, child) => MainScaffold(
          role: 'technician',
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/technician',
            name: 'technician-home',
            builder: (context, state) => const TechnicianHomeScreen(),
          ),
          GoRoute(
            path: '/technician/bookings',
            name: 'technician-bookings',
            builder: (context, state) => const BookingsListScreen(),
          ),
          GoRoute(
            path: '/technician/wallet',
            name: 'technician-wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/technician/settings',
            name: 'technician-settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Shared detail routes (outside shell)
      GoRoute(
        path: '/booking/create/:categoryId',
        name: 'create-booking',
        builder: (context, state) => CreateBookingScreen(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: '/booking/search/:id',
        name: 'booking-search',
        builder: (context, state) => BookingSearchScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/booking/:id',
        name: 'booking-detail',
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/receipt/:bookingId',
        name: 'receipt',
        builder: (context, state) => ReceiptScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/tracking/:bookingId',
        name: 'tracking',
        builder: (context, state) => TrackingScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/chat/:bookingId',
        name: 'chat',
        builder: (context, state) => ChatScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/rating/:bookingId',
        name: 'rating',
        builder: (context, state) => RatingScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/addresses',
        name: 'addresses-list',
        builder: (context, state) => const AddressesListScreen(),
      ),
      GoRoute(
        path: '/addresses/add',
        name: 'add-address',
        builder: (context, state) => const AddAddressScreen(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/support/create',
        name: 'create-ticket',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/support/:id',
        name: 'ticket-detail',
        builder: (context, state) => TicketDetailScreen(
          ticketId: state.pathParameters['id']!,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
