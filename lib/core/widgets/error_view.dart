import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    this.message = 'ເກີດຂໍ້ຜິດພາດ',
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  factory ErrorView.noInternet({VoidCallback? onRetry}) => ErrorView(
        message: 'ບໍ່ສາມາດເຊື່ອມຕໍ່ອິນເຕີເນັດ\nກະລຸນາກວດສອບ WiFi ຫຼື Data',
        icon: Icons.wifi_off_rounded,
        onRetry: onRetry,
      );

  factory ErrorView.serverError({VoidCallback? onRetry}) => ErrorView(
        message: 'ເຊີບເວີຂໍ້ຜິດພາດ\nກະລຸນາລອງໃໝ່ພາຍຫຼັງ',
        icon: Icons.cloud_off_rounded,
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ລອງໃໝ່'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
