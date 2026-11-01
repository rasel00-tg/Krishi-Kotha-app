import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/bangla_number_converter.dart';
import '../../../core/utils/district_data.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../data/models/weather_info_model.dart';

class WeatherCardWidget extends StatefulWidget {
  const WeatherCardWidget({super.key});

  @override
  State<WeatherCardWidget> createState() => _WeatherCardWidgetState();
}

class _WeatherCardWidgetState extends State<WeatherCardWidget> {
  bool _profileDistrictSynced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileDistrictSynced) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileDistrict = authProvider.user?.district;
      if (profileDistrict != null && profileDistrict.trim().isNotEmpty) {
        _profileDistrictSynced = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<WeatherProvider>(context, listen: false)
                .setInitialDistrict(profileDistrict.trim());
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    // Also auto-sync if user logged in dynamically
    final authUserDistrict = Provider.of<AuthProvider>(context, listen: false).user?.district;
    if (!_profileDistrictSynced && authUserDistrict != null && authUserDistrict.trim().isNotEmpty) {
      _profileDistrictSynced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          weatherProvider.setInitialDistrict(authUserDistrict.trim());
        }
      });
    }

    if (weatherProvider.isLoading && weatherProvider.weatherInfo == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: ShimmerCardLoader(height: 165),
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
          colors: [
            Color(0xFF1B5E20), // ডিপ ফরেস্ট এমারেল্ড
            Color(0xFF2E7D32), // ভাইব্রেন্ট এগ্রি গ্রিন
            Color(0xFF388E3C), // সফট লিফ গ্রিন
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.24), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF2979FF).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ১. টপ হেডার: স্লিক পিল জেলা ড্রপডাউন ও ওয়েদার কন্ডিশন ব্যাজ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // সফট কার্ভড পিল/ক্যাপসুল শেপে ৬৪ জেলার ড্রপডাউন ট্রিগার
                InkWell(
                  onTap: () => _showDistrictPicker(context, weatherProvider),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFFFFD54F), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          weather.district,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 17),
                      ],
                    ),
                  ),
                ),

                // ওয়েদার কন্ডিশন ক্যাপসুল
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getWeatherIcon(weather.conditionBn),
                        color: const Color(0xFFFFD54F),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        weather.conditionBn,
                        style: const TextStyle(
                          color: Color(0xFFE8F5E9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ২. বড় ও ক্রিস্প লাইভ তাপমাত্রা এবং আধুনিক মেট্রিক্স ইন্ডিকেটর
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // বড় লাইভ তাপমাত্রা
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BanglaNumberConverter.toBangla(weather.currentTemp.toStringAsFixed(0)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      '°C',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                // লাইভ মেট্রিক্স ব্যাজসমূহ (বৃষ্টির শঙ্কা, আর্দ্রতা, বাতাসের গতি)
                Row(
                  children: [
                    _buildMetricItem(
                      icon: Icons.water_drop_outlined,
                      label: AppStrings.rainChance,
                      value: '${BanglaNumberConverter.toBangla(weather.rainProbability)}%',
                    ),
                    const SizedBox(width: 12),
                    _buildMetricItem(
                      icon: Icons.opacity_rounded,
                      label: AppStrings.humidity,
                      value: '${BanglaNumberConverter.toBangla(weather.humidity)}%',
                    ),
                    const SizedBox(width: 12),
                    _buildMetricItem(
                      icon: Icons.air_rounded,
                      label: 'বাতাস',
                      value: '${BanglaNumberConverter.toBangla(weather.windSpeed.toStringAsFixed(0))} কিমি/ঘ',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ৩. পরবর্তী ৩ দিনের সংক্ষিপ্ত কৃষি পূর্বাভাস
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 6),
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
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weather.threeDayForecast.map((f) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _buildForecastDay(f),
                ),
              )).toList(),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 13),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastDay(ForecastDay f) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            f.dayName,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Icon(
            _getWeatherIcon(f.condition),
            color: const Color(0xFFFFD54F),
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            '${BanglaNumberConverter.toBangla(f.tempMax.toStringAsFixed(0))}° / ${BanglaNumberConverter.toBangla(f.tempMin.toStringAsFixed(0))}°',
            style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
          Text(
            'বৃষ্টি: ${BanglaNumberConverter.toBangla(f.rainChance)}%',
            style: const TextStyle(color: Color(0xFFC8E6C9), fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain') || lower.contains('বৃষ্টি')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('cloud') || lower.contains('মেঘলা')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('thunder') || lower.contains('ঝড়') || lower.contains('তুফান')) {
      return Icons.thunderstorm_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  // বাংলাদেশের পূর্ণাঙ্গ ৬৪ জেলার সার্চেবল প্রিমিয়াম ড্রপডাউন বটম-শীট
  void _showDistrictPicker(BuildContext context, WeatherProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> all64Districts = BangladeshLocationData.districts;
            final filtered = searchQuery.isEmpty
                ? all64Districts
                : all64Districts.where((d) => d.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ড্র্যাগ হ্যান্ডেল
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // হেডার
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'জেলা নির্বাচন করুন (৬৪ জেলা)',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // সার্চ ইনপুট ফিল্ড
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8E2)),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'জেলার নাম খুঁজুন...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF758577)),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ৬৪ জেলার গ্রিড লিস্ট
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'কোনো জেলা পাওয়া যায়নি',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final district = filtered[index];
                              final isSelected = district == provider.selectedDistrict;

                              return InkWell(
                                onTap: () {
                                  provider.updateDistrict(district);
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAF7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.location_city_rounded,
                                        size: 16,
                                        color: isSelected ? AppColors.primary : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          district,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
