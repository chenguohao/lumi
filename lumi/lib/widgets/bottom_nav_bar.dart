import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../config/app_config.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF150A15).withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Symbols.home,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) {
                    context.go('/home');
                  }
                },
              ),
              _NavItem(
                icon: Symbols.chat_bubble,
                label: 'Chat',
                isSelected: currentIndex == 1,
                onTap: () {
                  if (currentIndex != 1) {
                    context.go('/chat');
                  }
                },
              ),
              _NavItem(
                icon: Symbols.person,
                label: 'Profile',
                isSelected: currentIndex == 2,
                onTap: () {
                  if (currentIndex != 2) {
                    context.go('/profile');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isSelected)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: const Color(AppConfig.primaryColor),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(AppConfig.primaryColor),
                    blurRadius: 5,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          Icon(
            icon,
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

