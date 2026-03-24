import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final String role;
  final Widget child;

  const MainScaffold({
    super.key,
    required this.role,
    required this.child,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  List<_NavItem> get _navItems {
    if (widget.role == 'technician') {
      return [
        _NavItem(Icons.home_rounded, 'home', '/technician'),
        _NavItem(Icons.calendar_today_rounded, 'bookings', '/technician/bookings'),
        _NavItem(Icons.account_balance_wallet_rounded, 'wallet', '/technician/wallet'),
        _NavItem(Icons.settings_rounded, 'settings', '/technician/settings'),
      ];
    }
    return [
      _NavItem(Icons.home_rounded, 'home', '/home'),
      _NavItem(Icons.calendar_today_rounded, 'bookings', '/bookings'),
      _NavItem(Icons.account_balance_wallet_rounded, 'wallet', '/wallet'),
      _NavItem(Icons.settings_rounded, 'settings', '/settings'),
    ];
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync selected index with current route
    final location = GoRouterState.of(context).matchedLocation;
    final items = _navItems;
    for (int i = 0; i < items.length; i++) {
      if (location == items[i].route) {
        if (_selectedIndex != i) {
          setState(() => _selectedIndex = i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _navItems;
    final useRail = Responsive.useNavigationRail(context);

    if (useRail) {
      // Tablet / landscape – NavigationRail on the leading side
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Theme.of(context).colorScheme.surface,
                destinations: items.map((item) {
                  return NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(l10n.translate(item.labelKey)),
                  );
                }).toList(),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: widget.child),
            ],
          ),
        ),
      );
    }

    // Phone – standard bottom navigation
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: items.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            label: l10n.translate(item.labelKey),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String labelKey;
  final String route;

  _NavItem(this.icon, this.labelKey, this.route);
}

// Shared loading widget with smooth pulse animation
class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _opacityAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shared error widget – adapts icon & padding to screen size
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final iconSz = Responsive.value<double>(context, mobile: 56, tablet: 72);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.maxFormWidth(context)),
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: iconSz,
                color: AppTheme.errorColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).tryAgain),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Empty state widget – responsive icon & spacing
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final iconSz = Responsive.value<double>(context, mobile: 72, tablet: 96);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.maxFormWidth(context)),
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSz, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Status badge widget – scales text for readability
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'searching':
        return Colors.orange;
      case 'assigned':
      case 'driving':
        return const Color(0xFF2563EB);
      case 'arrived':
        return const Color(0xFF7C3AED);
      case 'active':
      case 'in_progress':
        return const Color(0xFF6366F1);
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Responsive.value<double>(context, mobile: 12, tablet: 13);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: fs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
