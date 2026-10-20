class BangladeshLocations {
  /// বাংলাদেশের ৮টি বিভাগের অধীনে সম্পূর্ণ ৬৪ জেলার সুবিন্যস্ত তালিকা
  static const Map<String, List<String>> divisionDistricts = {
    'ঢাকা বিভাগ': [
      'ঢাকা', 'গাজীপুর', 'নারায়ণগঞ্জ', 'টাঙ্গাইল', 'কিশোরগঞ্জ', 'নরসিংদী',
      'মানিকগঞ্জ', 'মুন্সীগঞ্জ', 'ফরিদপুর', 'রাজবাড়ী', 'গোপালগঞ্জ', 'মাদারীপুর', 'শরীয়তপুর',
    ],
    'চট্টগ্রাম বিভাগ': [
      'চট্টগ্রাম', 'কক্সবাজার', 'কুমিল্লা', 'নোয়াখালী', 'ফেনী', 'ব্রাহ্মণবাড়িয়া',
      'চাঁদপুর', 'লক্ষ্মীপুর', 'রাঙ্গামাটি', 'খাগড়াছড়ি', 'বান্দরবান',
    ],
    'রাজশাহী বিভাগ': [
      'রাজশাহী', 'বগুড়া', 'পাবনা', 'সিরাজগঞ্জ', 'নওগাঁ', 'নাটোর', 'চাঁপাইনবাবগঞ্জ', 'জয়পুরহাট',
    ],
    'রংপুর বিভাগ': [
      'রংপুর', 'দিনাজপুর', 'কুড়িগ্রাম', 'গাইবান্ধা', 'নীলফামারী', 'লালমনিরহাট', 'পঞ্চগড়', 'ঠাকুরগাঁও',
    ],
    'খুলনা বিভাগ': [
      'খুলনা', 'যশোর', 'কুষ্টিয়া', 'ঝিনাইদহ', 'সাতক্ষীরা', 'বাগেরহাট', 'চুয়াডাঙ্গা', 'মেহেরপুর', 'মাগুরা', 'নড়াইল',
    ],
    'বরিশাল বিভাগ': [
      'বরিশাল', 'পটুয়াখালী', 'ভোলা', 'পিরোজপুর', 'বরগুনা', 'ঝালকাঠি',
    ],
    'সিলেট বিভাগ': [
      'সিলেট', 'মৌলভীবাজার', 'হবিগঞ্জ', 'সুনামগঞ্জ',
    ],
    'ময়মনসিংহ বিভাগ': [
      'ময়মনসিংহ', 'জামালপুর', 'নেত্রকোণা', 'শেরপুর',
    ],
  };

  /// সকল বিভাগের তালিকা
  static const List<String> allDivisions = [
    'সকল বিভাগ',
    'ঢাকা বিভাগ',
    'চট্টগ্রাম বিভাগ',
    'রাজশাহী বিভাগ',
    'রংপুর বিভাগ',
    'খুলনা বিভাগ',
    'বরিশাল বিভাগ',
    'সিলেট বিভাগ',
    'ময়মনসিংহ বিভাগ',
  ];

  /// বাংলাদেশের সম্পূর্ণ ৬৪ জেলার ফ্ল্যাট তালিকা
  static List<String> get allDistricts {
    final list = <String>[];
    for (final districts in divisionDistricts.values) {
      list.addAll(districts);
    }
    return list;
  }

  /// নির্দিষ্ট বিভাগের অন্তর্ভুক্ত জেলাসমূহ রিটার্ন করে
  static List<String> getDistrictsForDivision(String division) {
    if (division == 'সকল বিভাগ') {
      return allDistricts;
    }
    return divisionDistricts[division] ?? allDistricts;
  }

  /// ফিল্টারের জন্য জেলা তালিকা (উপরে 'সারাদেশ / সকল জেলা' সহ)
  static List<String> getFilterDistricts(String division) {
    final districts = getDistrictsForDivision(division);
    return ['সারাদেশ / সকল জেলা', ...districts];
  }

  /// জেলা নাম নরম্যালাইজেশন (যেমন: বগুড়া / বগুড়া, নারায়ণগঞ্জ / নারায়ণগঞ্জ সমার্থক হ্যান্ডলিং)
  static bool matchDistrict(String a, String b) {
    if (a == b) return true;
    final normA = a.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়').replaceAll('ণ', 'ন');
    final normB = b.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়').replaceAll('ণ', 'ন');
    return normA.trim().toLowerCase() == normB.trim().toLowerCase();
  }

  /// নির্দিষ্ট জেলার বিভাগ শনাক্ত করে
  static String getDivisionForDistrict(String district) {
    for (final entry in divisionDistricts.entries) {
      if (entry.value.any((d) => matchDistrict(d, district))) {
        return entry.key;
      }
    }
    return 'ঢাকা বিভাগ';
  }
}
