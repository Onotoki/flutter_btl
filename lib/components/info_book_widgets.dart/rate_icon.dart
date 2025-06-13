import 'package:flutter/material.dart';

class RateWidget extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String imageIcon;
  final String textIcon;
  final Color activeColor;

  const RateWidget({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.imageIcon,
    required this.textIcon,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRect(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(color, BlendMode.saturation),
                child: Image.asset(
                  imageIcon,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              textIcon,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}
