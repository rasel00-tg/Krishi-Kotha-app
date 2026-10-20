# কৃষি কথা – Krishi Kotha

**কৃষি কথা (Krishi Kotha)** হলো বাংলাদেশের কৃষক ও কৃষি উদ্যোক্তাদের জন্য নির্মিত একটি আধুনিক, স্কেলযোগ্য এবং সম্পূর্ণ বাংলা ইন্টারফেস সম্বলিত স্মার্ট কৃষি মোবাইল অ্যাপ্লিকেশন। 

অ্যাপটি কৃষকবান্ধব মেটেরিয়াল ৩ (Material 3) ডিজাইন, উচ্চ বৈসাদৃশ্যপূর্ণ রঙের প্যালেট (`#2E7D32`, `#4CAF50`, `#F1F8E9`), বড় স্পর্শযোগ্য বাটন (Large Accessible Touch Targets), বাংলা সংখ্যা রূপান্তরকারী এবং রিয়েল-টাইম ফায়ারবেস ক্লাউড ফায়ারস্টোর (Firestore StreamBuilder) দ্বারা চালিত।

---

## 🌾 প্রধান বৈশিষ্ট্যসমূহ (Key Features)

### ১. অথেনটিকেশন ও অনবোর্ডিং (Authentication & Onboarding)
* **ফোন নম্বর ওটিপি লগইন:** ফায়ারবেস অথেন্টিকেশন (`FirebaseAuth`) এর মাধ্যমে সুরক্ষিত মোবাইল ওটিপি যাচাই।
* **গেস্ট / ব্রাউজ মোড:** লগইন ছাড়াই তাৎক্ষণিকভাবে অ্যাপের সমস্ত তথ্য ব্রাউজ করার সুযোগ।
* **কৃষক প্রোফাইল সেটআপ:** কৃষকের নাম, জেলা ও উপজেলা নির্বাচন এবং চাষকৃত প্রধান ফসলের তালিকা সংরক্ষণ।

### ২. স্মার্ট হোম ড্যাশবোর্ড (Smart Dashboard)
* **রিয়েল-টাইম আবহাওয়া কার্ড:** বর্তমান তাপমাত্রা (°C), বৃষ্টির সম্ভাবনা (Rain Probability %), আর্দ্রতা এবং ৩ দিনের বিশেষ কৃষি পূর্বাভাস।
* **জরুরি কৃষি সতর্কতা ব্যানার:** প্রাকৃতিক দুর্যোগ (যেমন: কালবৈশাখী, শিলাবৃষ্টি, জলাবদ্ধতা) সম্পর্কে ফায়ারস্টোর রিয়েল-টাইম স্ট্রিমে নোটিফিকেশন ব্যানার।
* **কুইক সার্ভিস গ্রিড:** ফসলের তথ্য, লাইভ বাজার দর, সার ক্যালকুলেটর, রোগবালাই গাইড, ফোরাম ও হেল্পলাইনের এক-ট্যাপ শর্টকাট।

### ৩. ফসলের গাইডলাইন ও পরিচর্যা (Crop Advisory)
* ক্যাটাগরিভিত্তিক ফসলের তালিকা (দানাদার শস্য, শাকসবজি, ফলমূল, মসলা জাতীয়, তেল ও ডাল)।
* প্রতিটি ফসলের জন্য বপন/রোপণ সময়, মাটি ও জমি তৈরি, সেচ ব্যবস্থাপনা এবং জীবনচক্রভিত্তিক সার প্রয়োগের সঠিক নিয়ম।

### ৪. রোগবালাই ও কীটশত্রু ক্যাটালগ (Pest & Disease Diagnosis)
* ধানের ব্লাস্ট, কারেন্ট পোকা (BPH), আলুর নাবি ধসা, বেগুনের ডগা ও ফল ছিদ্রকারী পোকার স্পষ্ট নমুনা ছবিসহ ক্যাটালগ।
* **দ্বিমুখী সমাধান:** পরিবেশবান্ধব **জৈব প্রতিকার** (Organic Cure) এবং অনুমোদিত **রাসায়নিক সমাধান** (Chemical Remedy) এর সুস্পষ্ট মাত্রা ও প্রয়োগবিধি।

### ৫. কৃষি বাজার দর (Live Market Prices)
* কাওরান বাজার, মহাস্থানগড়, বানেশ্বর, ঝিকরগাছাসহ সারাদেশের পাইকারি ও খুচরা বাজার দর।
* জেলা ও ফসলের নাম দিয়ে তাৎক্ষণিক সার্চ ও ফিল্টার।
* মূল্যের গতিবিধি সূচক (উর্ধ্বমুখী / নিম্নমুখী / স্থিতিশীল)।

### ৬. সার ও কীটনাশক ক্যালকুলেটর (Fertilizer Calculator)
* জমির পরিমাপ ইনপুট: **শতাংশ (শতক)**, **বিঘা (৩৩ শতক)**, **একর (১০০ শতক)**।
* বাংলাদেশ কৃষি গবেষণা ইনস্টিটিউট (BARI) ও ব্রি (BRRI) এর অনুমোদিত মাত্রায় ইউরিয়া, টিএসপি, ডিএপি, এমওপি/পটাশ, জিপসাম, জিঙ্ক ও জৈব সারের সঠিক কেজির হিসাব।
* ৪০ কেজির উপরে হলে স্বয়ংক্রিয়ভাবে মণ ও কেজিতে রূপান্তর।
* কখন কোন কিস্তিতে সার প্রয়োগ করতে হবে তার পূর্ণাঙ্গ নির্দেশনা।

### ৭. কৃষক ফোরাম ও কমিউনিটি ফিড (Community Feed)
* ফসলের ছবি ও প্রশ্ন দিয়ে নতুন পোস্ট তৈরির সুবিধা।
* রিয়েল-টাইম লাইক (`StreamBuilder` এবং Transaction দিয়ে সংগতিপূর্ণ)।
* কমেন্ট ও কৃষি কর্মকর্তাদের উত্তরের রিয়েল-টাইম থ্রেড।

### ৮. বিশেষজ্ঞ পরামর্শ ও হেল্পলাইন (Expert Helpline & Support)
* **সরাসরি ডায়াল ১৬১২৩:** কৃষি মন্ত্রণালয়ের সরকারি কৃষি কল সেন্টারে এক ক্লিকে কল দেওয়ার সুবিধা।
* **উপজেলা কর্মকর্তার নিকট প্রশ্ন:** স্থানীয় কৃষি কর্মকর্তার নিকট ফসলের ছবি সংযুক্ত করে টিকিট আকারে প্রশ্ন পাঠানো এবং উত্তরের নোটিফিকেশন।

---

## 🏗️ আর্কিটেকচার ও ফোল্ডার কাঠামো (Clean Modular Architecture)

```
krishi_kotha/
├── pubspec.yaml                       # ডিপেনডেন্সি ও অ্যাসেট কনফিগ
├── analysis_options.yaml              # লিন্টার রুলস
├── android/                           # অ্যান্ড্রয়েড নেটিভ কনফিগারেশন ও পারমিশন
│   └── app/src/main/AndroidManifest.xml
└── lib/
    ├── main.dart                      # অ্যাপ এন্ট্রি পয়েন্ট ও মাল্টি-প্রোভাইডার গেট
    ├── core/                          # কোর ইউটিলিটি, থিম এবং কনস্ট্যান্ট
    │   ├── constants/
    │   │   ├── app_colors.dart        # সবুজ ও মাটির রঙের মেটেরিয়াল ৩ প্যালেট
    │   │   ├── app_strings.dart       # সকল বাংলা টেক্সট ও লেবেল
    │   │   └── app_theme.dart         # অ্যাক্সেসিবল থিম ও ফন্ট স্টাইলিং
    │   ├── utils/
    │   │   ├── bangla_number_converter.dart # বাংলা সংখ্যা ও কারেন্সি রূপান্তর
    │   │   ├── date_formatter.dart    # বাংলা রিলেটিভ টাইম ("৫ মিনিট আগে", ইত্যাদি)
    │   │   └── district_data.dart     # বাংলাদেশের ৬৪ জেলা ও উপজেলার তালিকা
    │   └── widgets/
    │       ├── custom_app_bar.dart    # রিইউজেবল অ্যাপবার
    │       ├── custom_button.dart     # বড় টাচ-টার্গেট সমৃদ্ধ বাটন
    │       ├── shimmer_loader.dart    # শিমার লোডিং স্কেলিটন
    │       ├── error_state_widget.dart# বাংলা এরর হ্যান্ডলিং উইজেট
    │       └── empty_state_widget.dart# বাংলা এম্পটি স্টেট উইজেট
    ├── data/
    │   ├── models/                    # ডাটা মডেল (Firestore Serialization)
    │   │   ├── user_model.dart
    │   │   ├── crop_model.dart
    │   │   ├── pest_disease_model.dart
    │   │   ├── market_price_model.dart
    │   │   ├── community_post_model.dart
    │   │   ├── comment_model.dart
    │   │   ├── weather_alert_model.dart
    │   │   ├── weather_info_model.dart
    │   │   └── support_ticket_model.dart
    │   └── services/                  # ফায়ারবেস ও ব্যাকএন্ড সার্ভিস
    │       ├── firebase_service.dart  # অফলাইন পারসিস্টেন্স কনফিগারেশন
    │       ├── auth_service.dart      # ফোন ওটিপি ও গেস্ট অথ
    │       ├── firestore_service.dart # রিয়েল-টাইম স্ট্রিম ও মিউটেশন
    │       ├── storage_service.dart   # ফায়ারবেস স্টোরেজ ইমেজ আপলোড
    │       ├── weather_service.dart   # জেলাভিত্তিক কৃষি আবহাওয়া সার্ভিস
    │       └── dummy_data_seeder.dart # সমৃদ্ধ প্রাথমিক বাংলা ডেমো ডাটা
    ├── providers/                     # স্টেট ম্যানেজমেন্ট (Provider)
    │   ├── auth_provider.dart
    │   ├── weather_provider.dart
    │   ├── crop_provider.dart
    │   ├── market_price_provider.dart
    │   ├── community_provider.dart
    │   ├── fertilizer_calculator_provider.dart
    │   └── support_provider.dart
    └── presentation/                  # UI ও স্ক্রিন লেয়ার
        ├── navigation/
        │   └── main_navigation_screen.dart # মেটেরিয়াল ৩ নেভিগেশন বার
        ├── auth/
        │   ├── phone_login_screen.dart
        │   ├── otp_verification_screen.dart
        │   └── profile_setup_screen.dart
        ├── home/
        │   ├── home_screen.dart
        │   └── widgets/
        │       ├── weather_card_widget.dart
        │       ├── emergency_alert_banner.dart
        │       └── quick_action_grid.dart
        ├── crops/
        │   ├── crop_list_screen.dart
        │   ├── crop_detail_screen.dart
        │   ├── pest_catalog_screen.dart
        │   └── pest_detail_screen.dart
        ├── market/
        │   └── market_price_screen.dart
        ├── calculator/
        │   └── fertilizer_calculator_screen.dart
        ├── community/
        │   ├── community_feed_screen.dart
        │   ├── create_post_screen.dart
        │   └── post_detail_screen.dart
        ├── support/
        │   ├── expert_helpline_screen.dart
        │   └── new_query_screen.dart
        └── profile/
            └── user_profile_screen.dart
```

---

## 🗄️ ক্লাউড ফায়ারস্টোর স্কিমা (Firestore Schema & Collections)

1. **`users`**
   ```json
   {
     "uid": "String (auth uid)",
     "name": "String (মো: রফিকুল ইসলাম)",
     "phone": "String (+8801711223344)",
     "district": "String (বগুড়া)",
     "upazila": "String (শেরপুর)",
     "preferred_crops": ["বোরো ধান", "আলু"],
     "createdAt": "Timestamp"
   }
   ```

2. **`crops`**
   ```json
   {
     "name_bn": "String (বোরো ধান)",
     "category": "String (দানাদার শস্য)",
     "season": "String (রবি)",
     "soil_type": "String (দোআঁশ)",
     "sowing_time": "String (নভেম্বর - ডিসেম্বর)",
     "imageUrl": "String",
     "stages": [
       {
         "stage_name": "বীজতলা ও জমি তৈরি",
         "description": "...",
         "irrigation": "...",
         "fertilizer": "..."
       }
     ]
   }
   ```

3. **`pests_diseases`**
   ```json
   {
     "crop_id": "String",
     "crop_name_bn": "String (ধান)",
     "name_bn": "String (ধানের ব্লাস্ট রোগ)",
     "symptoms": "String (লক্ষণসমূহ...)",
     "organic_cure": "String (জৈব সমাধান...)",
     "chemical_cure": "String (রাসায়নিক স্প্রে...)",
     "precaution": "String (সতর্কতা...)",
     "imageUrl": "String"
   }
   ```

4. **`market_prices`**
   ```json
   {
     "district": "String (বগুড়া)",
     "market_name": "String (মহাস্থানগড় হাট)",
     "crop_name": "String (বোরো ধান)",
     "unit": "String (মণ)",
     "price": 1250.0,
     "retail_price": 1300.0,
     "trend": "up | down | stable",
     "updatedAt": "Timestamp"
   }
   ```

5. **`community_posts`**
   ```json
   {
     "postId": "String",
     "authorId": "String",
     "authorName": "String",
     "authorPhone": "String",
     "content": "String",
     "imageUrl": "String?",
     "likesCount": 14,
     "commentsCount": 5,
     "likedBy": ["uid1", "uid2"],
     "timestamp": "Timestamp"
   }
   ```

6. **`weather_alerts`**
   ```json
   {
     "title": "String (কালবৈশাখী ঝড়ের পূর্বাভাস)",
     "description": "String",
     "severity": "critical | warning | info",
     "district": "String (সারাদেশ)",
     "timestamp": "Timestamp"
   }
   ```

---

## 🚀 কীভাবে চালু করবেন (Getting Started)

1. **ফ্লাটার প্রজেক্ট ডিপেনডেন্সি ইনস্টল করুন:**
   ```bash
   flutter pub get
   ```

2. **ফায়ারবেস কনফিগারেশন (ঐচ্ছিক কিন্তু প্রোডাকশনের জন্য প্রযোজ্য):**
   * ফায়ারবেস কনসোলে গিয়ে একটি নতুন প্রজেক্ট তৈরি করুন।
   * Android এর জন্য `google-services.json` ডাউনলোড করে `android/app/` ডিরেক্টরিতে রাখুন।
   * iOS এর জন্য `GoogleService-Info.plist` ফাইলটি `ios/Runner/` এ রাখুন।
   * *উল্লেখ্য:* ফায়ারবেস শংসাপত্র তাৎক্ষণিকভাবে যুক্ত না থাকলেও অ্যাপটি স্বয়ংক্রিয়ভাবে এর সমন্বিত অফলাইন ক্যাশ ও ডেমো ডাটা সিডার দিয়ে মসৃণভাবে চলবে!

3. **অ্যাপ রান করুন:**
   ```bash
   flutter run
   ```
