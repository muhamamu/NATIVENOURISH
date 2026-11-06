import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final UserProfile profile;
  final double size;
  const ProfileAvatar({super.key, required this.profile, this.size = 88});

  @override
  Widget build(BuildContext context) {
    Widget fallback = Center(child: Text(profile.name.isEmpty ? 'N' : profile.name.characters.first.toUpperCase(),
      style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.w700)));
    Widget image = fallback;
    if (profile.profileImage.startsWith('data:image/')) {
      try {
        final bytes = base64Decode(profile.profileImage.split(',').last);
        image = Image.memory(bytes, width: size, height: size, fit: BoxFit.cover,
          gaplessPlayback: true, errorBuilder: (_, error, stack) => fallback);
      } catch (_) { image = fallback; }
    }
    return Semantics(label: 'Profile photo', image: true, child: Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryAccentDark,
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.35), width: 3)),
      child: ClipOval(child: image),
    ));
  }
}
