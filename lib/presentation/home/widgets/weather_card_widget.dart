import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/bangla_number_converter.dart';
import '../../../core/utils/district_data.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../providers/weather_provider.dart';

class WeatherCardWidget extends StatelessWidget {
  const WeatherCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    if (weatherProvider.isLoading && weatherProvider.weatherInfo == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: ShimmerCardLoader(height: 180),
      );
    }

    final weather = weatherProvider.weatherInfo;
    if (weather == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221B5E20),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Location & Weather condition
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _showDistrictPicker(context, weatherProvider),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          weather.district,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 15),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    weather.conditionBn,
                    style: const TextStyle(
                      color: Color(0xFFE8F5E9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Temp and Key Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Big Temperature Display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BanglaNumberConverter.toBangla(weather.currentTemp.toStringAsFixed(0)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      '°C',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Metrics Grid (Rain chance, Humidity)
                Row(
                  children: [
                    _buildMetricItem(
                      icon: Icons.water_drop_outlined,
                      label: AppStrings.rainChance,
                      value: '${BanglaNumberConverter.toBangla(weather.rainProbability)}%',
                    ),
                    const SizedBox(width: 14),
                    _buildMetricItem(
                      icon: Icons.air_outlined,
                      label: AppStrings.humidity,
                      value: '${BanglaNumberConverter.toBangla(weather.humidity)}%',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Farming Advice Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFFFE082), size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weather.farmingAdvice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 9),

            // 3-Day Farming Forecast
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.weatherForecast3Days,
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'আপডেট: ${BanglaNumberConverter.toBangla('আজ')}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weather.threeDayForecast.map((f) => _buildForecastDay(f)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 13),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastDay(ForecastDay f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            f.dayName,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Icon(
            _getWeatherIcon(f.condition),
            color: const Color(0xFFFFD54F),
            size: 17,
          ),
          const SizedBox(height: 2),
          Text(
            '${BanglaNumberConverter.toBangla(f.tempMax.toStringAsFixed(0))}° / ${BanglaNumberConverter.toBangla(f.tempMin.toStringAsFixed(0))}°',
            style: const TextStyle(color: Colors.white70, fontSize: 10.5),
          ),
          Text(
            'বৃষ্টি: ${BanglaNumberConverter.toBangla(f.rainChance)}%',
            style: const TextStyle(color: Color(0xFFC8E6C9), fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'rain':
      case 'বৃষ্টি':
        return Icons.water_drop;
      case 'cloudy':
      case 'মেঘলা':
        return Icons.cloud;
      default:
        return Icons.wb_sunny;
    }
  }

  void _showDistrictPicker(BuildContext context, WeatherProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.selectDistrict,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: DistrictData.districts.length,
                  itemBuilder: (context, index) {
                    final d = DistrictData.districts[index];
                    return ListTile(
                      title: Text(d),
                      trailing: d == provider.currentDistrict
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        provider.changeDistrict(d);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
