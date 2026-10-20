import '../models/crop_model.dart';
import '../models/pest_disease_model.dart';
import '../models/market_price_model.dart';
import '../models/community_post_model.dart';
import '../models/weather_alert_model.dart';
import '../models/notification_model.dart';

class SeedData {
  static List<CropModel> getInitialCrops() {
    return [
      const CropModel(
        id: 'crop_rice_boro',
        nameBn: 'বোরো ধান (BRRI Dhan-28/29/89)',
        category: 'দানাদার শস্য',
        season: 'রবি (শীতকাল)',
        soilType: 'দোআঁশ ও এঁটেল মাটি',
        sowingTime: 'কার্তিক থেকে অগ্রহায়ণ (নভেম্বর - ডিসেম্বর)',
        imageUrl: 'https://images.unsplash.com/photo-1536657464919-892534f60d6e?w=800&auto=format&fit=crop&q=80',
        stages: [
          CropStage(
            stageName: 'বীজতলা ও জমি তৈরি',
            description: 'বীজ শোধন করে ভেজানো ও ৪-৫ টি চাষ দিয়ে জমি কাদা তৈরি করা।',
            irrigation: 'বীজতলায় হালকা ২-৩ সেমি পানি ধরে রাখা।',
            fertilizer: 'প্রতি শতকে শেষ চাষে ১০০ গ্রাম ইউরিয়া, ৫০ গ্রাম টিএসপি ও ৪০ গ্রাম এমওপি।',
          ),
          CropStage(
            stageName: 'চারা রোপণ (১৫-৩০ দিন)',
            description: 'সুস্থ ও সতেজ ২৫-৩০ দিনের চারা লাইন করে রোপণ করা (২৫x১৫ সেমি দূরত্বে)।',
            irrigation: 'রোপণের পর ২-৩ দিন জমিতে ২-৩ ইঞ্চি পানি রাখুন।',
            fertilizer: 'রোপণের ১৫ দিন পর ১ম কিস্তি ইউরিয়া উপরিপ্রয়োগ।',
          ),
          CropStage(
            stageName: 'কুশি ও থোড় পর্যায় (৩৫-৬০ দিন)',
            description: 'কুশি বৃদ্ধির সময় জমি আগাছামুক্ত রাখা এবং পোকা নজরদারি করা।',
            irrigation: 'পর্যাপ্ত পানি নিশ্চিত করুন, শুকিয়ে ফেটে যেতে দেবেন না।',
            fertilizer: 'রোপণের ৩৫-৪০ দিন পর ২য় কিস্তি ও থোড় আসার পূর্বে ৩য় কিস্তি ইউরিয়া।',
          ),
          CropStage(
            stageName: 'দানা গঠন ও পরিপক্কতা (৬৫-৯০ দিন)',
            description: 'দানা শক্ত হওয়া পর্যন্ত সেচ বজায় রাখা এবং কাটার ১০ দিন আগে পানি নিষ্কাশন করা।',
            irrigation: 'শীষ বের হওয়ার সময় জমিতে রস থাকা বাধ্যতামূলক।',
            fertilizer: 'এমওপি বা পটাশ স্প্রে করা যেতে পারে দানার পুষ্টির জন্য।',
          ),
        ],
      ),
      const CropModel(
        id: 'crop_potato',
        nameBn: 'গোল আলু (ডায়মন্ড / কার্ডিনাল)',
        category: 'শাকসবজি',
        season: 'রবি',
        soilType: 'বেলে দোআঁশ মাটি',
        sowingTime: 'কার্তিক থেকে অগ্রহায়ণ (অক্টোবর - নভেম্বর)',
        imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=800&auto=format&fit=crop&q=80',
        stages: [
          CropStage(
            stageName: 'জমি তৈরি ও রোপণ',
            description: 'গভীরভাবে চাষ দিয়ে মাটি ঝুরঝুরে করা এবং সুষম সার প্রয়োগ করা।',
            irrigation: 'রোপণের সময় মাটিতে পর্যাপ্ত রস থাকা আবশ্যক।',
            fertilizer: 'প্রতি শতকে ইউরিয়া ১ কেজি, টিএসপি ৮০০ গ্রাম, এমওপি ১ কেজি, জিপসাম ৪০০ গ্রাম।',
          ),
          CropStage(
            stageName: 'গাছ বৃদ্ধি ও মাটি তোলা (২৫-৩৫ দিন)',
            description: 'গাছের গোড়ায় মাটি তুলে দেওয়া এবং প্রথম সেচ প্রদান করা।',
            irrigation: 'রোপণের ২০-২৫ দিন পর ১ম হালকা সেচ দিন।',
            fertilizer: 'মাটি তোলার সময় ইউরিয়া উপরিপ্রয়োগ করুন।',
          ),
          CropStage(
            stageName: 'কন্দ বৃদ্ধি (৪৫-৭০ দিন)',
            description: 'আলু আকারে বড় হতে থাকে, এ সময় রোগবালাই থেকে সতর্ক থাকুন।',
            irrigation: 'মাটির অবস্থা বুঝে ৮-১০ দিন পর পর সেচ দিন। অতিরিক্ত পানি জমতে দেবেন না।',
            fertilizer: 'পটাশ স্প্রে ও বোরন সার প্রয়োগ উপকারী।',
          ),
        ],
      ),
      const CropModel(
        id: 'crop_tomato',
        nameBn: 'টমেটো (উফশী ও হাইব্রিড)',
        category: 'শাকসবজি',
        season: 'রবি ও খরিফ',
        soilType: 'উর্বর দোআঁশ মাটি',
        sowingTime: 'আশ্বিন - কার্তিক (অক্টোবর - নভেম্বর)',
        imageUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=800&auto=format&fit=crop&q=80',
        stages: [
          CropStage(
            stageName: 'চারা তৈরি ও রোপণ',
            description: 'সুস্থ চারা ৬০x৪০ সেমি দূরত্বে তৈরি বেডে রোপণ করুন।',
            irrigation: 'রোপণের পর গোড়ায় হালকা সেচ প্রদান।',
            fertilizer: 'প্রতি শতকে জৈব সার ২০ কেজি, টিএসপি ৪০০ গ্রাম, এমওপি ৩০০ গ্রাম।',
          ),
          CropStage(
            stageName: 'খুঁটি দেওয়া ও ফলন পর্যায়',
            description: 'গাছের বৃদ্ধির সাথে সাথে বাঁশের খুঁটি দিন এবং ডালপালা ছাঁটাই করুন।',
            irrigation: 'ফুল ও ফল ধরার সময় নিয়মিত সেচ প্রয়োজন।',
            fertilizer: 'গাছ প্রতি ২০ দিন পর পর ইউরিয়া ও পটাশ উপরিপ্রয়োগ করুন।',
          ),
        ],
      ),
      const CropModel(
        id: 'crop_maize',
        nameBn: 'ভুট্টা (হাইব্রিড)',
        category: 'দানাদার শস্য',
        season: 'রবি ও খরিফ',
        soilType: 'উর্বর বেলে দোআঁশ',
        sowingTime: 'কার্তিক - পৌষ (নভেম্বর - ডিসেম্বর)',
        imageUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=800&auto=format&fit=crop&q=80',
        stages: [
          CropStage(
            stageName: 'বপন ও চারা পর্যায়',
            description: 'সারি থেকে সারির দূরত্ব ৬০ সেমি এবং গাছ থেকে গাছ ২৫ সেমি রেখে বীজ বপন করুন।',
            irrigation: 'বীজ গজানোর পর প্রয়োজনে হালকা সেচ দিন।',
            fertilizer: 'প্রতি শতকে ইউরিয়া ১.৫ কেজি, ডিএপি ৮০০ গ্রাম, এমওপি ৬০০ গ্রাম, জিপসাম ৫০০ গ্রাম।',
          ),
        ],
      ),
      const CropModel(
        id: 'crop_brinjal',
        nameBn: 'বেগুন (ইসলামপুরী / নয়নতারা)',
        category: 'শাকসবজি',
        season: 'সারা বছর',
        soilType: 'উঁচু দোআঁশ মাটি',
        sowingTime: 'ভাদ্র - আশ্বিন (শীতকালীন) অথবা চৈত্র - বৈশাখ (গ্রীষ্মকালীন)',
        imageUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop&q=80',
        stages: [
          CropStage(
            stageName: 'চারা রোপণ ও প্রাথমিক যত্ন',
            description: 'সুস্থ সবল চারা ৭৫x৬০ সেমি দূরত্বে রোপণ করুন।',
            irrigation: 'মাটিতে রস না থাকলে ৩-৪ দিন পর পর হালকা সেচ দিন।',
            fertilizer: 'প্রতি শতকে গোবর ১৫ কেজি, টিএসপি ৫০০ গ্রাম, ইউরিয়া ৬০০ গ্রাম।',
          ),
        ],
      ),
    ];
  }

  static List<PestDiseaseModel> getInitialPests() {
    return [
      const PestDiseaseModel(
        id: 'pest_blast',
        cropId: 'crop_rice_boro',
        cropNameBn: 'ধান',
        nameBn: 'ধানের ব্লাস্ট রোগ (Rice Blast)',
        symptoms: 'পাতায় ছোট বাদামি দাগ পড়ে যা পরবর্তীতে চোখের মতো বা ডিম্বাকৃতি ধারণ করে। দাগের কেন্দ্র ধূসর ও কিনারা গাঢ় বাদামি হয়। শিষের গোড়ায় আক্রমণ হলে পুরো শিষ সাদা হয়ে চিটা হয়ে যায় (নেক ব্লাস্ট)।',
        organicCure: 'রোগাক্রান্ত জমিতে ছাই বা ট্রাইকোডার্মা বায়োপেস্টিসাইড ব্যবহার করুন। আক্রান্ত গাছের পরিত্যক্ত অংশ পুড়িয়ে নষ্ট করুন এবং অতিরিক্ত ইউরিয়া সার দেওয়া বন্ধ রাখুন।',
        chemicalCure: 'লক্ষণ দেখা মাত্রই ট্রাইসাইক্লাজল জাতীয় ছত্রাকনাশক (যেমন: ট্রপার ৭৫ ডব্লিউপি / দিফা ৭৫ ডব্লিউপি) প্রতি লিটার পানিতে ০.৭৫ গ্রাম অথবা নেটিভো ৭৫ ডব্লিউজি প্রতি লিটার পানিতে ০.৬ গ্রাম হারে মিশিয়ে স্প্রে করুন।',
        precaution: 'বীজ বপনের পূর্বে অটোস্টিন বা কার্বেনডাজিম দিয়ে বীজ শোধন করুন। সুষম মাত্রায় পটাশ সার ব্যবহার করুন।',
        imageUrl: 'https://images.unsplash.com/photo-1628352081506-83c43123ed6d?w=800&auto=format&fit=crop&q=80',
      ),
      const PestDiseaseModel(
        id: 'pest_bph',
        cropId: 'crop_rice_boro',
        cropNameBn: 'ধান',
        nameBn: 'বাদামি গাছফড়িং / কারেন্ট পোকা (BPH)',
        symptoms: 'পোকা গাছের গোড়ায় দলবদ্ধভাবে অবস্থান করে রস চুষে খায়। আক্রান্ত ধান গাছ দ্রুত শুকিয়ে খড়ের রঙের মতো হয়ে গোল গোল আকারে মারা যায়, একে হপার বার্ন (Hopper Burn) বলা হয়।',
        organicCure: 'জমির পানি সরিয়ে দিয়ে ২-৩ দিন শুকিয়ে ফেলুন। জমিতে বাঁশের কঞ্চি বা আলো ফাঁদ (Light trap) ব্যবহার করে পোকা দমন করুন। হাঁস নামিয়ে পোকা খাওয়ানো যায়।',
        chemicalCure: 'গাছের গোড়ায় পাইমেট্রোজিন জাতীয় কীটনাশক (যেমন: প্যাক্সিস / চেস ৫০ ডব্লিউজি) প্রতি লিটার পানিতে ০.৫ গ্রাম অথবা ডিনোটেফুরান (যেমন: ভেনম) প্রতি লিটার পানিতে ০.৫ গ্রাম হারে ভালো করে গাছের গোড়া ভিজিয়ে স্প্রে করুন।',
        precaution: 'গাছের গোড়ায় পর্যাপ্ত আলো-বাতাস চলাচলের জন্য প্রতি ১০ সারি পর পর ১ সারি ফাঁকা (লগো পদ্ধতি) রাখুন।',
        imageUrl: 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=800&auto=format&fit=crop&q=80',
      ),
      const PestDiseaseModel(
        id: 'pest_late_blight',
        cropId: 'crop_potato',
        cropNameBn: 'আলু',
        nameBn: 'আলুর নাবি ধসা রোগ (Late Blight)',
        symptoms: 'কুয়াশাচ্ছন্ন আবহাওয়ায় পাতার কিনারায় বা ডগায় ভেজা জলছাপের মতো দাগ দেখা যায়। দ্রুত এই দাগ পুরো পাতায় ছড়িয়ে কালো হয়ে পচে যায় এবং জমিতে পোড়া গন্ধ বের হয়।',
        organicCure: 'রোগাক্রান্ত গাছ তুলে মাটিতে পুঁতে ফেলুন। নিম তেলের দ্রবণ (প্রতি লিটার পানিতে ৫ মিলি) বা রসুন বাটা পানির সাথে মিশিয়ে স্প্রে করুন।',
        chemicalCure: 'কুয়াশা থাকলে রোগ হওয়ার আগেই ম্যানকোজেব (যেমন: ডাইথেন এম-৪৫) প্রতি লিটার পানিতে ২ গ্রাম হারে স্প্রে করুন। রোগ আক্রমণ করলে মেটাল্যাক্সিল+ম্যানকোজেব (যেমন: রিডোমিল গোল্ড) প্রতি লিটার পানিতে ২ গ্রাম অথবা এক্রোবেট এমজেড স্প্রে করুন।',
        precaution: 'মেঘলা ও কুয়াশাচ্ছন্ন আবহাওয়ায় জমিতে সেচ দেওয়া সাময়িকভাবে বন্ধ রাখুন। প্রত্যয়িত রোগমুক্ত বীজ ব্যবহার করুন।',
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800&auto=format&fit=crop&q=80',
      ),
      const PestDiseaseModel(
        id: 'pest_brinjal_borer',
        cropId: 'crop_brinjal',
        cropNameBn: 'বেগুন',
        nameBn: 'বেগুনের ডগা ও ফল ছিদ্রকারী পোকা',
        symptoms: 'পোকার কীড়া কচি ডগা ও ফলের ভেতর ছিদ্র করে ঢুকে ভিতরের অংশ খায়। আক্রান্ত ডগা নুয়ে পড়ে শুকিয়ে যায় এবং ফল খাওয়ার অনুপযোগী হয়ে পড়ে।',
        organicCure: 'সেক্স ফেরোমন ফাঁদ ব্যবহার করুন। আক্রান্ত ডগা ও ফল হাত দিয়ে সংগ্রহ করে মাটির নিচে পুঁতে ফেলুন। ট্রাইকোগ্রামা পরজীবী পোকা ছেড়ে জৈব দমন করুন।',
        chemicalCure: 'এমামেকটিন বেনজোয়েট (যেমন: প্রোক্লেম ৫ এসজি) প্রতি লিটার পানিতে ১ গ্রাম অথবা স্পাইনোস্যাড (যেমন: সাকসেস ২.৫ এসসি) প্রতি লিটার পানিতে ১.২ মিলি স্প্রে করুন।',
        precaution: 'একই জমিতে বারবার বেগুনের চাষ করবেন না, শস্য পর্যায় অবলম্বন করুন।',
        imageUrl: 'https://images.unsplash.com/photo-1528825871115-3581a5387919?w=800&auto=format&fit=crop&q=80',
      ),
    ];
  }

  static List<MarketPriceModel> getInitialMarketPrices() {
    final now = DateTime.now();
    return [
      MarketPriceModel(
        id: 'price_1',
        district: 'বগুড়া',
        marketName: 'মহাস্থানগড় হাট',
        cropName: 'বোরো ধান (ব্রি-২৮)',
        unit: 'মণ (৪০ কেজি)',
        price: 1250.0,
        retailPrice: 1300.0,
        trend: 'up',
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      MarketPriceModel(
        id: 'price_2',
        district: 'ঢাকা',
        marketName: 'কাওরান বাজার পাইকারি আড়ৎ',
        cropName: 'গোল আলু (ডায়মন্ড)',
        unit: 'কেজি',
        price: 38.0,
        retailPrice: 45.0,
        trend: 'down',
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      MarketPriceModel(
        id: 'price_3',
        district: 'যশোর',
        marketName: 'ঝিকরগাছা হাট',
        cropName: 'টমেটো (পাকা)',
        unit: 'কেজি',
        price: 60.0,
        retailPrice: 75.0,
        trend: 'stable',
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      MarketPriceModel(
        id: 'price_4',
        district: 'রাজশাহী',
        marketName: 'বানেশ্বর হাট',
        cropName: 'পেঁয়াজ (দেশি)',
        unit: 'কেজি',
        price: 90.0,
        retailPrice: 105.0,
        trend: 'up',
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      MarketPriceModel(
        id: 'price_5',
        district: 'ময়মনসিংহ',
        marketName: 'মেছুয়া বাজার',
        cropName: 'বেগুন (গোল)',
        unit: 'কেজি',
        price: 45.0,
        retailPrice: 55.0,
        trend: 'stable',
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      MarketPriceModel(
        id: 'price_6',
        district: 'রংপুর',
        marketName: 'নবাবগঞ্জ বাজার',
        cropName: 'সরিষা',
        unit: 'মণ (৪০ কেজি)',
        price: 3400.0,
        retailPrice: 3550.0,
        trend: 'up',
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  static List<WeatherAlertModel> getInitialAlerts() {
    final now = DateTime.now();
    return [
      WeatherAlertModel(
        id: 'alert_1',
        title: 'কালবৈশাখী ঝড় ও শিলাবৃষ্টির সতর্কতা',
        description: 'দেশের উত্তর ও মধ্যাঞ্চলে আগামী ২৪ ঘণ্টায় তীব্র বাতাস ও শিলাবৃষ্টির সম্ভাবনা রয়েছে। পাকা ধান থাকলে দ্রুত কেটে নিরাপদ স্থানে সংরক্ষণ করুন।',
        severity: 'critical',
        district: 'সারাদেশ',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      WeatherAlertModel(
        id: 'alert_2',
        title: 'অতিরিক্ত আর্দ্রতায় ছত্রাক রোগের ঝুঁকি',
        description: 'টানা মেঘলা আবহাওয়া ও আর্দ্রতার কারণে আলু এবং শীতকালীন সবজিতে ছত্রাকের সংক্রমণ ঘটতে পারে। প্রতিরোধমূলক ছত্রাকনাশক প্রস্তুত রাখুন।',
        severity: 'warning',
        district: 'রংপুর ও রাজশাহী বিভাগ',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  static List<CommunityPostModel> getInitialCommunityPosts() {
    final now = DateTime.now();
    return [
      CommunityPostModel(
        postId: 'post_1',
        authorId: 'user_101',
        authorName: 'মো: আব্দুল করিম',
        authorPhone: '০১৭১১-২২৩৩৪৪',
        content: 'আমার বোরো ধানের পাতার আগা হলুদ হয়ে শুকিয়ে যাচ্ছে। গত ২ দিন ধরে সমস্যাটি বেশি দেখা যাচ্ছে। অভিজ্ঞ ভাইদের পরামর্শ চাচ্ছি, কী সার বা স্প্রে করা যায়?',
        imageUrl: 'https://images.unsplash.com/photo-1536657464919-892534f60d6e?w=800&auto=format&fit=crop&q=80',
        likesCount: 14,
        commentsCount: 5,
        likedBy: ['guest_user'],
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      CommunityPostModel(
        postId: 'post_2',
        authorId: 'user_102',
        authorName: 'রফিকুল ইসলাম (কৃষি উদ্যোক্তা)',
        authorPhone: '০১৮২২-৩৩৪৪৫৫',
        content: 'আলহামদুলিল্লাহ! জৈব সার ও সেক্স ফেরোমন ফাঁদ ব্যবহার করে এবার বেগুনে কোনো পোকার আক্রমণ ছাড়াই ভালো ফলন পেয়েছি। রাসায়নিকের চেয়ে জৈব পদ্ধতিতে খরচও অর্ধেকের কম হয়েছে।',
        imageUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop&q=80',
        likesCount: 38,
        commentsCount: 9,
        likedBy: [],
        timestamp: now.subtract(const Duration(hours: 7)),
      ),
    ];
  }

  static List<NotificationModel> getInitialNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'notif_1',
        title: 'কালবৈশাখী ঝড় ও ভারি বৃষ্টির সতর্কতা',
        message: 'আগামী ২৪ ঘণ্টায় রাজশাহী ও রংপুর বিভাগে তীব্র বাতাস ও শিলাবৃষ্টির সম্ভাবনা রয়েছে। পাকা ফসল থাকলে দ্রুত ঘরে তুলুন।',
        timestamp: now.subtract(const Duration(minutes: 25)),
        isSeen: false,
        type: 'weather',
      ),
      NotificationModel(
        id: 'notif_2',
        title: 'বোরো ধানের ব্লাস্ট রোগ প্রতিরোধ পরামর্শ',
        message: 'আবহাওয়ায় আর্দ্রতা বেশি থাকায় শীষ ব্লাস্টের আক্রমণ হতে পারে। ট্রাইসাইক্লাজোল গ্রুপের ছত্রাকনাশক স্প্রে করার পরামর্শ দেওয়া হচ্ছে।',
        timestamp: now.subtract(const Duration(hours: 2)),
        isSeen: false,
        type: 'crop',
      ),
      NotificationModel(
        id: 'notif_3',
        title: 'আজকের পাইকারি বাজার দর আপডেট হয়েছে',
        message: 'বগুড়া ও নওগাঁর মহাস্থান ও রানীনগর মোকামে বোরো ধান এবং নতুন আলুর পাইকারি দর হালনাগাদ করা হয়েছে। বিস্তারিত বাজার দর ট্যাবে দেখুন।',
        timestamp: now.subtract(const Duration(hours: 8)),
        isSeen: true,
        type: 'market',
      ),
      NotificationModel(
        id: 'notif_4',
        title: 'বিনামূল্যে কৃষি কর্মকর্তা পরামর্শ সেবা চালু',
        message: 'যেকোনো কৃষি সমস্যায় সরাসরি কৃষি কর্মকর্তার সাথে বিনামূল্যে কথা বলতে ১৬১২৩ নম্বরে কল করুন। সকাল ৯টা থেকে বিকাল ৫টা পর্যন্ত সেবা চালু রয়েছে।',
        timestamp: now.subtract(const Duration(days: 1)),
        isSeen: true,
        type: 'general',
      ),
    ];
  }
}
