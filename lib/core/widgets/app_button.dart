// import 'package:flutter/material.dart';
// import '../constants/app_colors.dart';
// import '../constants/app_text_styles.dart';

// class AppButton extends StatelessWidget {
//   final String label;
//   final VoidCallback? onPressed;
//   final bool isLoading;
//   final Color? color;
//   final IconData? icon;
//   const AppButton({super.key, required this.label, this.onPressed,
//       this.isLoading = false, this.color, this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity, height: 52,
//       child: ElevatedButton(
//         onPressed: isLoading ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color ?? AppColors.primary,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         child: isLoading
//           ? const SizedBox(width: 22, height: 22,
//               child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//           : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//               if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
//               Text(label, style: AppTextStyles.button),
//             ]),
//       ),
//     );
//   }
// }
