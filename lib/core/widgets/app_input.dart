// import 'package:flutter/material.dart';
// import '../constants/app_colors.dart';

// class AppInput extends StatelessWidget {
//   final String label;
//   final String? hint;
//   final TextEditingController? controller;
//   final bool obscureText;
//   final TextInputType keyboardType;
//   final String? Function(String?)? validator;
//   final IconData? prefixIcon;
//   final Widget? suffixWidget;
//   final int maxLines;

//   const AppInput({super.key, required this.label, this.hint, this.controller,
//       this.obscureText = false, this.keyboardType = TextInputType.text,
//       this.validator, this.prefixIcon, this.suffixWidget, this.maxLines = 1});

//   @override
//   Widget build(BuildContext context) {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
//           color: AppColors.textSecondary)),
//       const SizedBox(height: 6),
//       TextFormField(
//         controller: controller, obscureText: obscureText,
//         keyboardType: keyboardType, validator: validator, maxLines: maxLines,
//         decoration: InputDecoration(
//           hintText: hint, suffix: suffixWidget,
//           prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textSecondary) : null,
//           filled: true, fillColor: AppColors.surface,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: AppColors.border)),
//           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: AppColors.border)),
//           focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: AppColors.primary, width: 2)),
//           errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: AppColors.error)),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         ),
//       ),
//     ]);
//   }
// }
