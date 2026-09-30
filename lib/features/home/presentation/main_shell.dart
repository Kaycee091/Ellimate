import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/laundry')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/updates')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            backgroundColor: AppColors.white,
            selectedItemColor: AppColors.primaryCoral,
            unselectedItemColor: AppColors.secondaryText,
            selectedLabelStyle: AppTypography.caption.copyWith(
              color: AppColors.primaryCoral,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTypography.caption,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/home');
                case 1:
                  context.go('/laundry');
                case 2:
                  context.go('/chat');
                case 3:
                  context.go('/updates');
                case 4:
                  context.go('/profile');
              }
            },
            items: [
              _navItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0, selectedIndex),
              _navItem(Icons.local_laundry_service_rounded, Icons.local_laundry_service_outlined, 'Laundry', 1, selectedIndex),
              _navItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat', 2, selectedIndex),
              _navItem(Icons.campaign_rounded, Icons.campaign_outlined, 'Updates', 3, selectedIndex),
              _navItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile', 4, selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
    IconData filled,
    IconData outline,
    String label,
    int index,
    int selected,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(index == selected ? filled : outline, size: 24),
      label: label,
    );
  }
}
