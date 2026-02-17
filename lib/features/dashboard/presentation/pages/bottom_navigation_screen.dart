import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../auth/presentation/view_model/auth_viewmodel.dart';
import 'bottom_screen/home_screen.dart';
import 'bottom_screen/calendar_screen.dart';
import 'bottom_screen/profile_screen.dart';

class BottomNavigationScreen extends ConsumerStatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  ConsumerState<BottomNavigationScreen> createState() =>
      _BottomNavigationScreenState();
}

class _BottomNavigationScreenState
    extends ConsumerState<BottomNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final String? profileImage = profileAsync.maybeWhen(
      data: (p) => p['profileImage'] as String?,
      orElse: () => null,
    );

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  index: 0,
                  currentIndex: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  index: 1,
                  currentIndex: _currentIndex,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _ProfileNavItem(
                  index: 2,
                  currentIndex: _currentIndex,
                  profileImage: profileImage,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color(0xFF7C3AED) : Colors.grey,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _ProfileNavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String? profileImage;
  final VoidCallback onTap;

  const _ProfileNavItem({
    required this.index,
    required this.currentIndex,
    required this.profileImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: profileImage != null
                  ? Image.network(
                      '${ApiEndpoints.imageBaseUrl}$profileImage',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 18,
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : Colors.grey,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 18,
                      color: isSelected ? const Color(0xFF7C3AED) : Colors.grey,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
