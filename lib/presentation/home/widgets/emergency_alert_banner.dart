import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../data/models/weather_alert_model.dart';
import '../../../data/services/firestore_service.dart';

class EmergencyAlertBanner extends StatelessWidget {
  final FirestoreService firestoreService;

  const EmergencyAlertBanner({
    super.key,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WeatherAlertModel>>(
      stream: firestoreService.getWeatherAlertsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const ShimmerCardLoader(height: 72);
        }

        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show the most critical or recent alert
        final topAlert = alerts.first;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: topAlert.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: topAlert.color.withOpacity(0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: topAlert.color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: topAlert.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(topAlert.icon, color: topAlert.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: topAlert.color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            AppStrings.emergencyAlerts,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          topAlert.district,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: topAlert.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      topAlert.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: topAlert.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topAlert.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
