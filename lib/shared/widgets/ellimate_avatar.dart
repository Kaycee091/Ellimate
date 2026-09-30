import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class ElliMateAvatar extends StatelessWidget {
  const ElliMateAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.fontSize,
  });

  final String? imageUrl;
  final String name;
  final double radius;
  final double? fontSize;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get _backgroundColor {
    final colors = [
      AppColors.primaryCoral,
      AppColors.blue,
      AppColors.purple,
      AppColors.success,
      AppColors.warning,
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _backgroundColor,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => _initalsWidget(),
            errorWidget: (context, url, error) => _initalsWidget(),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _backgroundColor,
      child: _initalsWidget(),
    );
  }

  Widget _initalsWidget() {
    return Text(
      _initials,
      style: TextStyle(
        color: AppColors.white,
        fontSize: fontSize ?? radius * 0.65,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
