class AppStrings {
 final String locale;

 AppStrings._(this.locale);

 static AppStrings of(String langCode) {
 return AppStrings._(langCode);
 }

 String get _l => locale;

 // ── Splash ──
 String get splashSubtitle => _t({
 'ko': '외국인 구인정보',
 'en': 'Jobs for foreigners',
 'zh': '外国人招聘信息',
 'hi': 'विदेशियों के लिए नौकरी की जानकारी',
 'ja': '外国人向け求人情報',
 'th': 'ข้อมูลหางานสำหรับชาวต่างชาติ',
 'vi': 'Việc làm cho người nước ngoài',
 'bn': 'বিদেশীদের জন্য চাকরির তথ্য',
 'ru': 'Вакансии для иностранцев',
 'id': 'Info lowongan kerja untuk orang asing',
 'ne': 'विदेशीहरूको लागि रोजगारी जानकारी',
 'km': 'ព័ត៌មានការងារសម្រាប់ជនបរទេស',
 'my': 'နိုင်ငံခြားသားများအတွက် အလုပ်အကိုင်',
 'si': 'විදේශිකයින් සඳහා රැකියා',
 'uz': 'Chet elliklar uchun ish o\'rinlari',
 'mn': 'Гадаадын иргэдэд зориулсан ажлын мэдээлэл',
 }, 'Jobs for foreigners');

 // ── Onboarding: Language ──
 String get selectLanguage => _t({
 'ko': '언어를 선택하세요',
 'en': 'Select language',
 'zh': '请选择语言',
 'hi': 'भाषा चुनें',
 'ja': '言語を選択',
 'th': 'เลือกภาษา',
 'vi': 'Chọn ngôn ngữ',
 'bn': 'ভাষা নির্বাচন করুন',
 'ru': 'Выберите язык',
 'id': 'Pilih bahasa',
 'ne': 'भाषा छान्नुहोस्',
 'km': 'ជ្រើសរើសភាសា',
 'my': 'ဘာသာစကားရွေးချယ်ပါ',
 'si': 'භාෂාව තෝරන්න',
 'uz': 'Tilni tanlang',
 'mn': 'Хэл сонгоно уу',
 }, 'Select language');

 String get getStarted => _t({
 'ko': '시작하기',
 'en': 'Get started',
 'zh': '开始',
 'hi': 'शुरू करें',
 'ja': '始める',
 'th': 'เริ่มต้น',
 'vi': 'Bắt đầu',
 'bn': 'শুরু করুন',
 'ru': 'Начать',
 'id': 'Mulai',
 'ne': 'सुरु गर्नुहोस्',
 'km': 'ចាប់ផ្តើម',
 'my': 'စတင်ပါ',
 'si': 'ආරම්භ කරන්න',
 'uz': 'Boshlash',
 'mn': 'Эхлэх',
 }, 'Get started');

 // ── Onboarding: Visa ──
 String get selectVisa => _t({
 'ko': '비자타입을 선택하세요',
 'en': 'Select your visa type',
 'zh': '请选择签证类型',
 'hi': 'अपना वीज़ा प्रकार चुनें',
 'ja': 'ビザを選択してください',
 'th': 'เลือกประเภทวีซ่า',
 'vi': 'Chọn loại visa',
 'bn': 'আপনার ভিসার ধরন নির্বাচন করুন',
 'ru': 'Выберите тип визы',
 'id': 'Pilih jenis visa',
 'ne': 'तपाईंको भिसा प्रकार छान्नुहोस्',
 'km': 'ជ្រើសរើសប្រភេទទិដ្ឋាការ',
 'my': 'ဗီဇာအမျိုးအစားရွေးချယ်ပါ',
 'si': 'ඔබගේ වීසා වර්ගය තෝරන්න',
 'uz': 'Viza turini tanlang',
 'mn': 'Визний төрлөө сонгоно уу',
 }, 'Select your visa type');

 String get selectVisaDesc => _t({
 'ko': '해당하는 비자를 모두 선택해주세요\n맞춤 공고를 먼저 보여드릴게요',
 'en': 'Select all your visa types\nWe\'ll show matching jobs first',
 'zh': '请选择您的所有签证类型\n我们将优先显示匹配的职位',
 'hi': 'अपने सभी वीज़ा प्रकार चुनें\nहम पहले मिलते-जुलते जॉब दिखाएंगे',
 'ja': 'すべてのビザタイプを選択してください\n該当する求人を優先表示します',
 'th': 'เลือกวีซ่าทั้งหมดของคุณ\nเราจะแสดงงานที่เหมาะก่อน',
 'vi': 'Chọn tất cả visa của bạn\nChúng tôi sẽ hiển thị việc phù hợp trước',
 'bn': 'আপনার সব ভিসার ধরন নির্বাচন করুন\nমিলে যাওয়া চাকরি আগে দেখাব',
 'ru': 'Выберите все ваши типы виз\nМы покажем подходящие вакансии первыми',
 'id': 'Pilih semua jenis visa Anda\nKami akan menampilkan lowongan yang cocok terlebih dahulu',
 'ne': 'तपाईंको सबै भिसा प्रकार छान्नुहोस्\nमिल्दो जागिर पहिला देखाउनेछौं',
 'km': 'ជ្រើសរើសប្រភេទទិដ្ឋាការទាំងអស់\nយើងនឹងបង្ហាញការងារដែលត្រូវគ្នាមុន',
 'my': 'သင့်ဗီဇာအမျိုးအစားအားလုံးရွေးချယ်ပါ\nကိုက်ညီသောအလုပ်များကို ဦးစွာပြသပါမည်',
 'si': 'ඔබගේ සියලු වීසා වර්ග තෝරන්න\nගැලපෙන රැකියා මුලින් පෙන්වන්නෙමු',
 'uz': 'Barcha viza turlarini tanlang\nMos keluvchi ishlarni avval ko\'rsatamiz',
 'mn': 'Бүх визний төрлөө сонгоно уу\nТохирох ажлыг эхлээд харуулна',
 }, 'Select all your visa types\nWe\'ll show matching jobs first');

 String get next => _t({
 'ko': '다음',
 'en': 'Next',
 'zh': '下一步',
 'hi': 'अगला',
 'ja': '次へ',
 'th': 'ถัดไป',
 'vi': 'Tiếp theo',
 'bn': 'পরবর্তী',
 'ru': 'Далее',
 'id': 'Selanjutnya',
 'ne': 'अर्को',
 'km': 'បន្ទាប់',
 'my': 'နောက်တစ်ခု',
 'si': 'ඊළඟ',
 'uz': 'Keyingi',
 'mn': 'Дараах',
 }, 'Next');

 String get skip => _t({
 'ko': '건너뛰기',
 'en': 'Skip',
 'zh': '跳过',
 'hi': 'छोड़ें',
 'ja': 'スキップ',
 'th': 'ข้าม',
 'vi': 'Bỏ qua',
 'bn': 'এড়িয়ে যান',
 'ru': 'Пропустить',
 'id': 'Lewati',
 'ne': 'छोड्नुहोस्',
 'km': 'រំលង',
 'my': 'ကျော်ပါ',
 'si': 'මඟ හරින්න',
 'uz': 'O\'tkazib yuborish',
 'mn': 'Алгасах',
 }, 'Skip');

 // ── Onboarding: Location ──
 String get locationTitle => _t({
 'ko': '주변 공고를 찾고 있어요',
 'en': 'Finding jobs near you',
 'zh': '正在查找附近的招聘信息',
 'hi': 'आपके पास की नौकरियाँ खोज रहे हैं',
 'ja': '近くの求人を探しています',
 'th': 'กำลังค้นหางานใกล้คุณ',
 'vi': 'Đang tìm việc gần bạn',
 'bn': 'আপনার কাছের চাকরি খুঁজছি',
 'ru': 'Ищем вакансии рядом',
 'id': 'Mencari lowongan di sekitar Anda',
 'ne': 'तपाईंको नजिकको जागिर खोज्दै',
 'km': 'កំពុងស្វែងរកការងារនៅជិតអ្នក',
 'my': 'သင့်အနီးအနားရှိ အလုပ်များရှာဖွေနေသည်',
 'si': 'ඔබ අසල රැකියා සොයමින්',
 'uz': 'Yaqin atrofdagi ishlarni qidirmoqda',
 'mn': 'Ойролцоох ажлын зар хайж байна',
 }, 'Finding jobs near you');

 String get locationDesc => _t({
 'ko': '현재 위치를 허용하면\n가까운 구인 공고를 먼저 보여드릴게요',
 'en': 'Allow location to\nshow nearby jobs first',
 'zh': '允许定位后\n我们会优先显示附近的招聘信息',
 'hi': 'स्थान की अनुमति दें\nनजदीकी नौकरियाँ पहले दिखाएंगे',
 'ja': '位置情報を許可すると\n近くの求人を優先表示します',
 'th': 'อนุญาตตำแหน่ง\nเพื่อแสดงงานใกล้คุณก่อน',
 'vi': 'Cho phép vị trí\nđể xem việc làm gần bạn trước',
 'bn': 'অবস্থান অনুমতি দিন\nকাছের চাকরি আগে দেখাব',
 'ru': 'Разрешите геолокацию,\nчтобы видеть ближайшие вакансии',
 'id': 'Izinkan lokasi untuk\nmenampilkan lowongan terdekat',
 'ne': 'स्थान अनुमति दिनुहोस्\nनजिकको जागिर पहिला देखाउनेछौं',
 'km': 'អនុញ្ញាតទីតាំងដើម្បី\nបង្ហាញការងារនៅជិតមុន',
 'my': 'တည်နေရာခွင့်ပြုပါ\nအနီးအနားရှိအလုပ်များကို ဦးစွာပြသပါမည်',
 'si': 'රැකියා මුලින් පෙන්වීමට\nස්ථානය අනුමත කරන්න',
 'uz': 'Yaqin atrofdagi ishlarni\nko\'rish uchun joylashuvga ruxsat bering',
 'mn': 'Ойролцоох ажлыг эхлээд\nхаруулахын тулд байршлыг зөвшөөрнө үү',
 }, 'Allow location to\nshow nearby jobs first');

 String get locationPerm1 => _t({
 'ko': '현재 위치 기반 공고 우선 표시',
 'en': 'Show nearby jobs first',
 'zh': '优先显示附近职位',
 'hi': 'नजदीकी नौकरियाँ पहले दिखाएं',
 'ja': '近くの求人を優先表示',
 'th': 'แสดงงานใกล้เคียงก่อน',
 'vi': 'Hiển thị việc gần bạn trước',
 'bn': 'কাছের চাকরি আগে দেখান',
 'ru': 'Сначала показывать ближайшие вакансии',
 'id': 'Tampilkan lowongan terdekat terlebih dahulu',
 'ne': 'नजिकको जागिर पहिला देखाउनुहोस्',
 'km': 'បង្ហាញការងារនៅជិតមុន',
 'my': 'အနီးအနားရှိအလုပ်များကို ဦးစွာပြသပါ',
 'si': 'අසල රැකියා මුලින් පෙන්වන්න',
 'uz': 'Yaqin atrofdagi ishlarni avval ko\'rsatish',
 'mn': 'Ойролцоох ажлыг эхлээд харуулах',
 }, 'Show nearby jobs first');

 String get locationPerm2 => _t({
 'ko': '위치 정보는 공고 검색에만 사용해요',
 'en': 'Location is used only for job search',
 'zh': '位置信息仅用于搜索职位',
 'hi': 'स्थान केवल नौकरी खोज के लिए उपयोग होता है',
 'ja': '位置情報は求人検索にのみ使用されます',
 'th': 'ตำแหน่งใช้สำหรับค้นหางานเท่านั้น',
 'vi': 'Vị trí chỉ dùng để tìm việc',
 'bn': 'অবস্থান শুধু চাকরি খোঁজার জন্য ব্যবহৃত হয়',
 'ru': 'Местоположение используется только для поиска вакансий',
 'id': 'Lokasi hanya digunakan untuk mencari lowongan',
 'ne': 'स्थान जागिर खोजको लागि मात्र प्रयोग हुन्छ',
 'km': 'ទីតាំងប្រើសម្រាប់ស្វែងរកការងារប៉ុណ្ណោះ',
 'my': 'တည်နေရာကို အလုပ်ရှာဖွေရန်သာ အသုံးပြုသည်',
 'si': 'ස්ථානය රැකියා සෙවීම සඳහා පමණි',
 'uz': 'Joylashuv faqat ish qidirish uchun ishlatiladi',
 'mn': 'Байршил зөвхөн ажил хайхад ашиглагдана',
 }, 'Location is used only for job search');

 String get locationPerm3 => _t({
 'ko': '언제든지 설정에서 변경할 수 있어요',
 'en': 'You can change this in settings anytime',
 'zh': '您可以随时在设置中更改',
 'hi': 'आप इसे कभी भी सेटिंग्स में बदल सकते हैं',
 'ja': 'いつでも設定で変更できます',
 'th': 'คุณสามารถเปลี่ยนได้ในการตั้งค่าเมื่อไหร่ก็ได้',
 'vi': 'Bạn có thể thay đổi trong cài đặt bất cứ lúc nào',
 'bn': 'আপনি যেকোনো সময় সেটিংসে পরিবর্তন করতে পারেন',
 'ru': 'Вы можете изменить это в настройках в любое время',
 'id': 'Anda dapat mengubahnya di pengaturan kapan saja',
 'ne': 'तपाईं यो सेटिङमा जुनसुकै बेला परिवर्तन गर्न सक्नुहुन्छ',
 'km': 'អ្នកអាចផ្លាស់ប្តូរវានៅក្នុងការកំណត់គ្រប់ពេល',
 'my': 'ဤအရာကို ဆက်တင်များတွင် အချိန်မရွေးပြောင်းလဲနိုင်သည်',
 'si': 'ඔබට මෙය ඕනෑම වේලාවක සැකසීම් තුළ වෙනස් කළ හැක',
 'uz': 'Buni istalgan vaqtda sozlamalardan o\'zgartirishingiz mumkin',
 'mn': 'Та үүнийг тохиргооноос хэдийд ч өөрчлөх боломжтой',
 }, 'You can change this in settings anytime');

 String get allowLocation => _t({
 'ko': '위치 허용하기',
 'en': 'Allow location',
 'zh': '允许定位',
 'hi': 'स्थान की अनुमति दें',
 'ja': '位置情報を許可',
 'th': 'อนุญาตตำแหน่ง',
 'vi': 'Cho phép vị trí',
 'bn': 'অবস্থান অনুমতি দিন',
 'ru': 'Разрешить геолокацию',
 'id': 'Izinkan lokasi',
 'ne': 'स्थान अनुमति दिनुहोस्',
 'km': 'អនុញ្ញាតទីតាំង',
 'my': 'တည်နေရာခွင့်ပြုပါ',
 'si': 'ස්ථානය අනුමත කරන්න',
 'uz': 'Joylashuvga ruxsat berish',
 'mn': 'Байршил зөвшөөрөх',
 }, 'Allow location');

 String get denyLocation => _t({
 'ko': '허용 안 함',
 'en': 'Don\'t allow',
 'zh': '不允许',
 'hi': 'अनुमति न दें',
 'ja': '許可しない',
 'th': 'ไม่อนุญาต',
 'vi': 'Không cho phép',
 'bn': 'অনুমতি দেবেন না',
 'ru': 'Не разрешать',
 'id': 'Tidak izinkan',
 'ne': 'अनुमति नदिनुहोस्',
 'km': 'មិនអនុញ្ញាត',
 'my': 'ခွင့်မပြုပါ',
 'si': 'අනුමත නොකරන්න',
 'uz': 'Ruxsat bermaslik',
 'mn': 'Зөвшөөрөхгүй',
 }, 'Don\'t allow');

 String get locationSelectTitle => _t({
 'ko': '지역을 선택하세요',
 'en': 'Select your region',
 'zh': '请选择地区',
 'hi': 'अपना क्षेत्र चुनें',
 'ja': '地域を選択',
 'th': 'เลือกพื้นที่',
 'vi': 'Chọn khu vực',
 'bn': 'অঞ্চল নির্বাচন করুন',
 'ru': 'Выберите регион',
 'id': 'Pilih wilayah',
 'ne': 'क्षेत्र छान्नुहोस्',
 'km': 'ជ្រើសរើសតំបន់',
 'my': 'ဒေသရွေးချယ်ပါ',
 'si': 'ප්‍රදේශය තෝරන්න',
 'uz': 'Hududni tanlang',
 'mn': 'Бүс нутгаа сонгоно уу',
 }, 'Select your region');

 String get locationSelectDesc => _t({
 'ko': '관심 지역의 공고를 먼저 볼 수 있어요',
 'en': 'See job listings in your area first',
 'zh': '优先查看您所在地区的招聘信息',
 'hi': 'अपने क्षेत्र की नौकरियां पहले देखें',
 'ja': 'お住まいの地域の求人を優先表示',
 'th': 'ดูงานในพื้นที่ของคุณก่อน',
 'vi': 'Xem việc làm trong khu vực của bạn trước',
 'bn': 'আপনার এলাকার চাকরি আগে দেখুন',
 'ru': 'Смотрите вакансии в вашем регионе первыми',
 'id': 'Lihat lowongan di wilayah Anda terlebih dahulu',
 'ne': 'तपाईंको क्षेत्रका जागिरहरू पहिले हेर्नुहोस्',
 'km': 'មើលការងារក្នុងតំបន់របស់អ្នកជាមុន',
 'my': 'သင့်ဒေသရှိ အလုပ်များကို ဦးစွာကြည့်ပါ',
 'si': 'ඔබගේ ප්‍රදේශයේ රැකියා පළමුව බලන්න',
 'uz': 'Hududingizdagi ish e\'lonlarini birinchi ko\'ring',
 'mn': 'Өөрийн бүс нутгийн ажлын зарыг эхлээд харна уу',
 }, 'See job listings in your area first');

 String get locationSelectGuGun => _t({
 'ko': '상세 지역을 선택하세요',
 'en': 'Select district',
 'zh': '请选择区县',
 'hi': 'जिला चुनें',
 'ja': '区市町村を選択',
 'th': 'เลือกเขต',
 'vi': 'Chọn quận/huyện',
 'bn': 'জেলা নির্বাচন করুন',
 'ru': 'Выберите район',
 'id': 'Pilih kecamatan',
 'ne': 'जिल्ला छान्नुहोस्',
 'km': 'ជ្រើសរើសស្រុក',
 'my': 'ခရိုင်ရွေးချယ်ပါ',
 'si': 'දිස්ත්‍රික්කය තෝරන්න',
 'uz': 'Tumanni tanlang',
 'mn': 'Дүүргээ сонгоно уу',
 }, 'Select district');

 String get skipLocation => _t({
 'ko': '건너뛰기',
 'en': 'Skip',
 'zh': '跳过',
 'hi': 'छोड़ें',
 'ja': 'スキップ',
 'th': 'ข้าม',
 'vi': 'Bỏ qua',
 'bn': 'এড়িয়ে যান',
 'ru': 'Пропустить',
 'id': 'Lewati',
 'ne': 'छोड्नुहोस्',
 'km': 'រំលង',
 'my': 'ကျော်ရန်',
 'si': 'මඟහරින්න',
 'uz': 'O\'tkazib yuborish',
 'mn': 'Алгасах',
 }, 'Skip');

 String get locationSkipMessage => _t({
 'ko': '나중에 필터에서 지역을 설정할 수 있습니다.',
 'en': 'You can set your region later in the filter.',
 'zh': '您可以稍后在筛选中设置地区。',
 'hi': 'आप बाद में फ़िल्टर में क्षेत्र सेट कर सकते हैं।',
 'ja': 'フィルターで後から地域を設定できます。',
 'th': 'คุณสามารถตั้งค่าพื้นที่ภายหลังในตัวกรอง',
 'vi': 'Bạn có thể cài đặt khu vực sau trong bộ lọc.',
 'bn': 'আপনি পরে ফিল্টারে অঞ্চল সেট করতে পারেন।',
 'ru': 'Вы можете установить регион позже в фильтре.',
 'id': 'Anda dapat mengatur wilayah nanti di filter.',
 'ne': 'तपाईं पछि फिल्टरमा क्षेत्र सेट गर्न सक्नुहुन्छ।',
 'km': 'អ្នកអាចកំណត់តំបន់នៅពេលក្រោយក្នុងតម្រង។',
 'my': 'စစ်ထုတ်မှုတွင် နောက်မှ ဒေသကို သတ်မှတ်နိုင်ပါသည်။',
 'si': 'ඔබට පසුව පෙරහනෙහි ප්‍රදේශය සැකසිය හැක.',
 'uz': 'Hududni keyinroq filtrda sozlashingiz mumkin.',
 'mn': 'Та шүүлтүүрээс бүс нутгийг дараа тохируулж болно.',
 }, 'You can set your region later in the filter.');

 String get districtSkipMessage => _t({
 'ko': '나중에 필터에서 상세 지역을 설정할 수 있습니다.',
 'en': 'You can set a specific district later in the filter.',
 'zh': '您可以稍后在筛选中设置具体区域。',
 'hi': 'आप बाद में फ़िल्टर में विशिष्ट जिला सेट कर सकते हैं।',
 'ja': 'フィルターで後から詳細な地域を設定できます。',
 'th': 'คุณสามารถตั้งค่าเขตเฉพาะภายหลังในตัวกรอง',
 'vi': 'Bạn có thể cài đặt quận/huyện cụ thể sau trong bộ lọc.',
 'bn': 'আপনি পরে ফিল্টারে নির্দিষ্ট জেলা সেট করতে পারেন।',
 'ru': 'Вы можете установить конкретный район позже в фильтре.',
 'id': 'Anda dapat mengatur kecamatan tertentu nanti di filter.',
 'ne': 'तपाईं पछि फिल्टरमा विशेष जिल्ला सेट गर्न सक्नुहुन्छ।',
 'km': 'អ្នកអាចកំណត់ស្រុកជាក់លាក់នៅពេលក្រោយក្នុងតម្រង។',
 'my': 'စစ်ထုတ်မှုတွင် နောက်မှ တိကျသော ခရိုင်ကို သတ်မှတ်နိုင်ပါသည်။',
 'si': 'ඔබට පසුව පෙරහනෙහි නිශ්චිත දිස්ත්‍රික්කය සැකසිය හැක.',
 'uz': 'Aniq tumanni keyinroq filtrda sozlashingiz mumkin.',
 'mn': 'Тодорхой дүүргийг шүүлтүүрээс дараа тохируулж болно.',
 }, 'You can set a specific district later in the filter.');

 // ── Home ──
 String get searchHint => _t({
 'ko': '비자, 직종, 회사명 검색',
 'en': 'Search visa, job type, company',
 'zh': '搜索签证、职种、公司',
 'hi': 'वीज़ा, नौकरी, कंपनी खोजें',
 'ja': 'ビザ、職種、会社名を検索',
 'th': 'ค้นหาวีซ่า อาชีพ บริษัท',
 'vi': 'Tìm visa, nghề, công ty',
 'bn': 'ভিসা, পেশা, কোম্পানি খুঁজুন',
 'ru': 'Поиск по визе, профессии, компании',
 'id': 'Cari visa, pekerjaan, perusahaan',
 'ne': 'भिसा, जागिर, कम्पनी खोज्नुहोस्',
 'km': 'ស្វែងរកទិដ្ឋាការ ការងារ ក្រុមហ៊ុន',
 'my': 'ဗီဇာ၊ အလုပ်၊ ကုမ္ပဏီ ရှာဖွေပါ',
 'si': 'වීසා, රැකියා, සමාගම සොයන්න',
 'uz': 'Viza, kasb, kompaniya qidirish',
 'mn': 'Виз, мэргэжил, компани хайх',
 }, 'Search visa, job type, company');

 String get filter => _t({
 'ko': '필터',
 'en': 'Filter',
 'zh': '筛选',
 'hi': 'फ़िल्टर',
 'ja': 'フィルター',
 'th': 'ตัวกรอง',
 'vi': 'Bộ lọc',
 'bn': 'ফিল্টার',
 'ru': 'Фильтр',
 'id': 'Filter',
 'ne': 'फिल्टर',
 'km': 'តម្រង',
 'my': 'စစ်ထုတ်ရန်',
 'si': 'පෙරහන',
 'uz': 'Filtr',
 'mn': 'Шүүлтүүр',
 }, 'Filter');

 String get filterTooltip => _t({
 'ko': '비자, 지역, 급여 등으로 검색!',
 'en': 'Search by visa, region, salary & more!',
 'zh': '按签证、地区、薪资等搜索！',
 'hi': 'वीज़ा, क्षेत्र, वेतन आदि से खोजें!',
 'ja': 'ビザ・地域・給与などで検索！',
 'th': 'ค้นหาตามวีซ่า พื้นที่ เงินเดือน!',
 'vi': 'Tìm theo visa, khu vực, lương!',
 'bn': 'ভিসা, এলাকা, বেতন দিয়ে খুঁজুন!',
 'ru': 'Поиск по визе, региону, зарплате!',
 'id': 'Cari berdasarkan visa, wilayah, gaji!',
 'ne': 'भिसा, क्षेत्र, तलब आदिले खोज्नुहोस्!',
 'km': 'ស្វែងរកតាមទិដ្ឋាការ តំបន់ ប្រាក់ខែ!',
 'my': 'ဗီဇာ၊ ဒေသ၊ လစာဖြင့် ရှာဖွေပါ!',
 'si': 'වීසා, ප්‍රදේශය, වැටුප් මගින් සොයන්න!',
 'uz': 'Viza, hudud, maosh bo\'yicha qidiring!',
 'mn': 'Виз, бүс, цалингаар хайх!',
 }, 'Search by visa, region, salary & more!');

 String get filterMore => _t({
 'ko': '+ 더보기',
 'en': '+ More',
 'zh': '+ 更多',
 'hi': '+ और',
 'ja': '+ 他',
 'th': '+ เพิ่ม',
 'vi': '+ Thêm',
 'bn': '+ আরও',
 'ru': '+ Ещё',
 'id': '+ Lainnya',
 'ne': '+ थप',
 'km': '+ ទៀត',
 'my': '+ နောက်ထပ်',
 'si': '+ තවත්',
 'uz': '+ Boshqa',
 'mn': '+ Бусад',
 }, '+ More');

 // ── Settings ──

 String get settings => _t({
 'ko': '설정', 'en': 'Settings', 'zh': '设置', 'hi': 'सेटिंग्स',
 'ja': '設定', 'th': 'ตั้งค่า', 'vi': 'Cài đặt', 'bn': 'সেটিংস',
 'ru': 'Настройки', 'id': 'Pengaturan', 'ne': 'सेटिङ', 'km': 'ការកំណត់',
 'my': 'ဆက်တင်', 'si': 'සැකසීම්', 'uz': 'Sozlamalar', 'mn': 'Тохиргоо',
 }, 'Settings');

 String get notifications => _t({
 'ko': '알림', 'en': 'Notifications', 'zh': '通知', 'hi': 'सूचनाएं',
 'ja': '通知', 'th': 'การแจ้งเตือน', 'vi': 'Thông báo', 'bn': 'বিজ্ঞপ্তি',
 'ru': 'Уведомления', 'id': 'Notifikasi', 'ne': 'सूचना', 'km': 'ការជូនដំណឹង',
 'my': 'အသိပေးချက်', 'si': 'දැනුම්දීම්', 'uz': 'Bildirishnomalar', 'mn': 'Мэдэгдэл',
 }, 'Notifications');

 String get newJobAlerts => _t({
 'ko': '신규 공고 알림', 'en': 'New job alerts', 'zh': '新职位提醒', 'hi': 'नई नौकरी अलर्ट',
 'ja': '新着求人通知', 'th': 'แจ้งเตือนงานใหม่', 'vi': 'Thông báo việc mới', 'bn': 'নতুন চাকরির সতর্কতা',
 'ru': 'Уведомления о новых вакансиях', 'id': 'Notifikasi lowongan baru', 'ne': 'नयाँ जागिर सूचना', 'km': 'ការជូនដំណឹងការងារថ្មី',
 'my': 'အလုပ်သစ် အသိပေးချက်', 'si': 'නව රැකියා දැනුම්දීම්', 'uz': 'Yangi ish bildirishnomalari', 'mn': 'Шинэ ажлын мэдэгдэл',
 }, 'New job alerts');

 String get newJobAlertsDesc => _t({
 'ko': '내 필터에 맞는 신규 공고가 등록되면 알림', 'en': 'Get notified when new jobs match your filters',
 'zh': '当有符合筛选条件的新职位时通知', 'hi': 'जब आपके फ़िल्टर से मेल खाने वाली नई नौकरी हो तो सूचना पाएं',
 'ja': 'フィルターに合う新着求人があれば通知', 'th': 'รับแจ้งเตือนเมื่อมีงานใหม่ตรงกับตัวกรอง',
 'vi': 'Nhận thông báo khi có việc mới phù hợp bộ lọc', 'bn': 'আপনার ফিল্টারের সাথে মিলে নতুন চাকরি হলে জানান',
 'ru': 'Получайте уведомления о вакансиях по вашим фильтрам', 'id': 'Dapatkan notifikasi saat ada lowongan baru sesuai filter',
 'ne': 'तपाईंको फिल्टरसँग मिल्ने नयाँ जागिर आउँदा सूचना', 'km': 'ទទួលបានការជូនដំណឹងពេលមានការងារថ្មីត្រូវនឹងតម្រង',
 'my': 'သင့်စစ်ထုတ်မှုနှင့်ကိုက်ညီသော အလုပ်သစ်ရှိသောအခါ အသိပေးချက်', 'si': 'ඔබේ පෙරහන් සමඟ ගැළපෙන නව රැකියා ඇති විට දැනුම්දීම්',
 'uz': 'Filtringizga mos yangi ish chiqsa xabar olish', 'mn': 'Таны шүүлтүүрт тохирох шинэ ажил гарвал мэдэгдэл',
 }, 'Get notified when new jobs match your filters');

 String get language => _t({
 'ko': '언어', 'en': 'Language', 'zh': '语言', 'hi': 'भाषा',
 'ja': '言語', 'th': 'ภาษา', 'vi': 'Ngôn ngữ', 'bn': 'ভাষা',
 'ru': 'Язык', 'id': 'Bahasa', 'ne': 'भाषा', 'km': 'ភាសា',
 'my': 'ဘာသာစကား', 'si': 'භාෂාව', 'uz': 'Til', 'mn': 'Хэл',
 }, 'Language');

 String get appLanguage => _t({
 'ko': '앱 언어', 'en': 'App language', 'zh': '应用语言', 'hi': 'ऐप भाषा',
 'ja': 'アプリ言語', 'th': 'ภาษาแอป', 'vi': 'Ngôn ngữ ứng dụng', 'bn': 'অ্যাপ ভাষা',
 'ru': 'Язык приложения', 'id': 'Bahasa aplikasi', 'ne': 'एप भाषा', 'km': 'ភាសាកម្មវិធី',
 'my': 'အက်ပ်ဘာသာစကား', 'si': 'යෙදුම් භාෂාව', 'uz': 'Ilova tili', 'mn': 'Аппын хэл',
 }, 'App language');

 String get enableNotificationsInSettings => _t({
 'ko': '알림을 받으려면 설정에서 허용해주세요',
 'en': 'Please enable notifications in settings',
 'zh': '请在设置中开启通知',
 'hi': 'कृपया सेटिंग्स में सूचनाएं सक्षम करें',
 'ja': '設定から通知を許可してください',
 'th': 'กรุณาเปิดการแจ้งเตือนในตั้งค่า',
 'vi': 'Vui lòng bật thông báo trong cài đặt',
 'bn': 'অনুগ্রহ করে সেটিংসে বিজ্ঞপ্তি চালু করুন',
 'ru': 'Включите уведомления в настройках',
 'id': 'Aktifkan notifikasi di pengaturan',
 'ne': 'कृपया सेटिङमा सूचना सक्षम गर्नुहोस्',
 'km': 'សូមបើកការជូនដំណឹងក្នុងការកំណត់',
 'my': 'ဆက်တင်တွင် အသိပေးချက်ကို ဖွင့်ပါ',
 'si': 'කරුණාකර සැකසීම් තුළ දැනුම්දීම් සක්‍රීය කරන්න',
 'uz': 'Sozlamalarda bildirishnomalarni yoqing',
 'mn': 'Тохиргооноос мэдэгдлийг зөвшөөрнө үү',
 }, 'Please enable notifications in settings');

 String get housingChip => _t({
 'ko': '숙소',
 'en': 'Housing',
 'zh': '住宿',
 'hi': 'आवास',
 'ja': '住居',
 'th': 'ที่พัก',
 'vi': 'Nhà ở',
 'bn': 'বাসস্থান',
 'ru': 'Жильё',
 'id': 'Tempat tinggal',
 'ne': 'आवास',
 'km': 'កន្លែងស្នាក់',
 'my': 'အိမ်ရာ',
 'si': 'නිවාස',
 'uz': 'Turar joy',
 'mn': 'Байр',
 }, 'Housing');

 String get favoriteAddedMsg => _t({
 'ko': '즐겨찾기에 추가했습니다',
 'en': 'Added to favorites',
 'zh': '已添加到收藏',
 'hi': 'पसंदीदा में जोड़ा गया',
 'ja': 'お気に入りに追加しました',
 'th': 'เพิ่มในรายการโปรดแล้ว',
 'vi': 'Đã thêm vào yêu thích',
 'bn': 'পছন্দে যোগ করা হয়েছে',
 'ru': 'Добавлено в избранное',
 'id': 'Ditambahkan ke favorit',
 'ne': 'मनपर्नेमा थपियो',
 'km': 'បានបន្ថែមទៅសំណព្វ',
 'my': 'အကြိုက်ဆုံးထဲ ထည့်ပြီးပါပြီ',
 'si': 'ප්‍රියතමයන්ට එකතු කළා',
 'uz': 'Sevimlilarga qo\'shildi',
 'mn': 'Дуртайд нэмэгдлээ',
 }, 'Added to favorites');

 String get favoriteRemovedMsg => _t({
 'ko': '즐겨찾기에서 제거했습니다',
 'en': 'Removed from favorites',
 'zh': '已从收藏中移除',
 'hi': 'पसंदीदा से हटाया गया',
 'ja': 'お気に入りから削除しました',
 'th': 'ลบออกจากรายการโปรดแล้ว',
 'vi': 'Đã xóa khỏi yêu thích',
 'bn': 'পছন্দ থেকে সরানো হয়েছে',
 'ru': 'Удалено из избранного',
 'id': 'Dihapus dari favorit',
 'ne': 'मनपर्नेबाट हटाइयो',
 'km': 'បានដកចេញពីសំណព្វ',
 'my': 'အကြိုက်ဆုံးမှ ဖယ်ရှားပြီးပါပြီ',
 'si': 'ප්‍රියතමයන්ගෙන් ඉවත් කළා',
 'uz': 'Sevimlilardan olib tashlandi',
 'mn': 'Дуртайгаас хасагдлаа',
 }, 'Removed from favorites');

 String totalCount(int count) => '${totalPrefix}$count${totalSuffix}';

 String get totalPrefix => _t({
 'ko': '전체 ',
 'en': 'Total ',
 'zh': '共 ',
 'hi': 'कुल ',
 'ja': '全 ',
 'th': 'ทั้งหมด ',
 'vi': 'Tổng ',
 'bn': 'মোট ',
 'ru': 'Всего ',
 'id': 'Total ',
 'ne': 'जम्मा ',
 'km': 'សរុប ',
 'my': 'စုစုပေါင်း ',
 'si': 'මුළු ',
 'uz': 'Jami ',
 'mn': 'Нийт ',
 }, 'Total ');

 String get totalSuffix => _t({
 'ko': '개',
 'en': '',
 'zh': ' 个',
 'hi': '',
 'ja': ' 件',
 'th': '',
 'vi': '',
 'bn': ' টি',
 'ru': '',
 'id': '',
 'ne': '',
 'km': '',
 'my': '',
 'si': '',
 'uz': '',
 'mn': '',
 }, '');

 String get onlyPartTime => _t({
 'ko': '알바만 보기',
 'en': 'Part-time only',
 'zh': '仅兼职',
 'hi': 'केवल पार्ट-टाइम',
 'ja': 'バイトのみ',
 'th': 'เฉพาะพาร์ทไทม์',
 'vi': 'Chỉ bán thời gian',
 'bn': 'শুধু খণ্ডকালীন',
 'ru': 'Только подработка',
 'id': 'Hanya paruh waktu',
 'ne': 'पार्ट-टाइम मात्र',
 'km': 'ក្រៅម៉ោងប៉ុណ្ណោះ',
 'my': 'အချိန်ပိုင်းသာ',
 'si': 'අර්ධ කාලීන පමණි',
 'uz': 'Faqat yarim stavka',
 'mn': 'Зөвхөн хагас цагийн',
 }, 'Part-time only');

 String get loading => _t({
 'ko': '로딩 중...',
 'en': 'Loading...',
 'zh': '加载中...',
 'hi': 'लोड हो रहा है...',
 'ja': '読み込み中...',
 'th': 'กำลังโหลด...',
 'vi': 'Đang tải...',
 'bn': 'লোড হচ্ছে...',
 'ru': 'Загрузка...',
 'id': 'Memuat...',
 'ne': 'लोड हुँदैछ...',
 'km': 'កំពុងផ្ទុក...',
 'my': 'ဖွင့်နေသည်...',
 'si': 'පූරණය වෙමින්...',
 'uz': 'Yuklanmoqda...',
 'mn': 'Ачааллаж байна...',
 }, 'Loading...');

 String get sortLatest => _t({
 'ko': '최신순',
 'en': 'Latest',
 'zh': '最新',
 'hi': 'नवीनतम',
 'ja': '新着順',
 'th': 'ล่าสุด',
 'vi': 'Mới nhất',
 'bn': 'সর্বশেষ',
 'ru': 'Новые',
 'id': 'Terbaru',
 'ne': 'नवीनतम',
 'km': 'ថ្មីបំផុត',
 'my': 'နောက်ဆုံးထွက်',
 'si': 'නවතම',
 'uz': 'Eng yangi',
 'mn': 'Шинэ',
 }, 'Latest');

 String get sortAccuracy => _t({
 'ko': '정확도순',
 'en': 'Relevance',
 'zh': '相关度',
 'hi': 'प्रासंगिकता',
 'ja': '関連度順',
 'th': 'ตรงที่สุด',
 'vi': 'Phù hợp nhất',
 'bn': 'প্রাসঙ্গিকতা',
 'ru': 'По релевантности',
 'id': 'Relevansi',
 'ne': 'सान्दर्भिकता',
 'km': 'ពាក់ព័ន្ធបំផុត',
 'my': 'သက်ဆိုင်မှုအစဉ်',
 'si': 'අදාළත්වය',
 'uz': 'Moslik',
 'mn': 'Хамааралтай',
 }, 'Relevance');

 String get sortSalaryHigh => _t({
 'ko': '급여높은순',
 'en': 'Highest salary',
 'zh': '薪资最高',
 'hi': 'सबसे अधिक वेतन',
 'ja': '給与高い順',
 'th': 'เงินเดือนสูงสุด',
 'vi': 'Lương cao nhất',
 'bn': 'সর্বোচ্চ বেতন',
 'ru': 'Самая высокая зарплата',
 'id': 'Gaji tertinggi',
 'ne': 'सबैभन्दा बढी तलब',
 'km': 'ប្រាក់ខែខ្ពស់បំផុត',
 'my': 'လစာအမြင့်ဆုံး',
 'si': 'ඉහළම වැටුප',
 'uz': 'Eng yuqori maosh',
 'mn': 'Цалин өндөр',
 }, 'Highest salary');

 String get noJobs => _t({
 'ko': '공고가 없습니다',
 'en': 'No jobs found',
 'zh': '没有招聘信息',
 'hi': 'कोई नौकरी नहीं मिली',
 'ja': '求人が見つかりません',
 'th': 'ไม่มีงาน',
 'vi': 'Không có việc làm',
 'bn': 'কোনো চাকরি নেই',
 'ru': 'Вакансий нет',
 'id': 'Tidak ada lowongan',
 'ne': 'कुनै जागिर भेटिएन',
 'km': 'រកមិនឃើញការងារ',
 'my': 'အလုပ်မတွေ့ပါ',
 'si': 'රැකියා හමු නොවීය',
 'uz': 'Ish topilmadi',
 'mn': 'Ажлын зар алга',
 }, 'No jobs found');

 String errorOccurred(String e) => _t({
 'ko': '오류가 발생했습니다: $e',
 'en': 'An error occurred: $e',
 'zh': '发生错误: $e',
 'hi': 'एक त्रुटि हुई: $e',
 'ja': 'エラーが発生しました: $e',
 'th': 'เกิดข้อผิดพลาด: $e',
 'vi': 'Đã xảy ra lỗi: $e',
 'bn': 'একটি ত্রুটি ঘটেছে: $e',
 'ru': 'Произошла ошибка: $e',
 'id': 'Terjadi kesalahan: $e',
 'ne': 'त्रुटि भयो: $e',
 'km': 'មានកំហុសកើតឡើង: $e',
 'my': 'အမှားတစ်ခုဖြစ်ပွားခဲ့သည်: $e',
 'si': 'දෝෂයක් සිදු විය: $e',
 'uz': 'Xatolik yuz berdi: $e',
 'mn': 'Алдаа гарлаа: $e',
 }, 'An error occurred: $e');

 String get changeLanguage => _t({
 'ko': '언어 변경',
 'en': 'Change language',
 'zh': '更改语言',
 'hi': 'भाषा बदलें',
 'ja': '言語変更',
 'th': 'เปลี่ยนภาษา',
 'vi': 'Đổi ngôn ngữ',
 'bn': 'ভাষা পরিবর্তন',
 'ru': 'Сменить язык',
 'id': 'Ubah bahasa',
 'ne': 'भाषा परिवर्तन गर्नुहोस्',
 'km': 'ប្តូរភាសា',
 'my': 'ဘာသာစကားပြောင်းပါ',
 'si': 'භාෂාව වෙනස් කරන්න',
 'uz': 'Tilni o\'zgartirish',
 'mn': 'Хэл солих',
 }, 'Change language');

 String get languageChanged => _t({
 'ko': '언어가 변경되었어요',
 'en': 'Language changed',
 'zh': '语言已更改',
 'hi': 'भाषा बदल दी गई',
 'ja': '言語が変更されました',
 'th': 'เปลี่ยนภาษาแล้ว',
 'vi': 'Đã đổi ngôn ngữ',
 'bn': 'ভাষা পরিবর্তন হয়েছে',
 'ru': 'Язык изменён',
 'id': 'Bahasa diubah',
 'ne': 'भाषा परिवर्तन भयो',
 'km': 'ភាសាត្រូវបានប្តូរ',
 'my': 'ဘာသာစကားပြောင်းလဲပြီးပါပြီ',
 'si': 'භාෂාව වෙනස් විය',
 'uz': 'Til o\'zgartirildi',
 'mn': 'Хэл солигдлоо',
 }, 'Language changed');

 // ── Search ──
 String get searchPlaceholder => _t({
 'ko': '검색어 입력...',
 'en': 'Enter keyword...',
 'zh': '输入搜索词...',
 'hi': 'कीवर्ड दर्ज करें...',
 'ja': 'キーワードを入力...',
 'th': 'พิมพ์คำค้นหา...',
 'vi': 'Nhập từ khóa...',
 'bn': 'কীওয়ার্ড লিখুন...',
 'ru': 'Введите ключевое слово...',
 'id': 'Masukkan kata kunci...',
 'ne': 'कीवर्ड लेख्नुहोस्...',
 'km': 'បញ្ចូលពាក្យគន្លឹះ...',
 'my': 'သော့ချက်စာလုံးရိုက်ထည့်ပါ...',
 'si': 'මූල පදය ඇතුළත් කරන්න...',
 'uz': 'Kalit so\'z kiriting...',
 'mn': 'Түлхүүр үг оруулна уу...',
 }, 'Enter keyword...');

 String get cancel => _t({
 'ko': '취소',
 'en': 'Cancel',
 'zh': '取消',
 'hi': 'रद्द करें',
 'ja': 'キャンセル',
 'th': 'ยกเลิก',
 'vi': 'Hủy',
 'bn': 'বাতিল',
 'ru': 'Отмена',
 'id': 'Batal',
 'ne': 'रद्द गर्नुहोस्',
 'km': 'បោះបង់',
 'my': 'ပယ်ဖျက်ပါ',
 'si': 'අවලංගු කරන්න',
 'uz': 'Bekor qilish',
 'mn': 'Цуцлах',
 }, 'Cancel');

 String get recentSearches => _t({
 'ko': '최근 검색',
 'en': 'Recent',
 'zh': '最近搜索',
 'hi': 'हाल की खोज',
 'ja': '最近の検索',
 'th': 'ค้นหาล่าสุด',
 'vi': 'Tìm gần đây',
 'bn': 'সাম্প্রতিক অনুসন্ধান',
 'ru': 'Недавние',
 'id': 'Terbaru',
 'ne': 'हालको खोज',
 'km': 'ស្វែងរកថ្មីៗ',
 'my': 'မကြာသေးမီရှာဖွေမှု',
 'si': 'මෑත',
 'uz': 'Oxirgi qidiruvlar',
 'mn': 'Сүүлийн хайлт',
 }, 'Recent');

 String searchFor(String q) => _t({
 'ko': "'$q' 검색",
 'en': "Search '$q'",
 'zh': "搜索 '$q'",
 'hi': "'$q' खोजें",
 'ja': "'$q' を検索",
 'th': "ค้นหา '$q'",
 'vi': "Tìm '$q'",
 'bn': "'$q' অনুসন্ধান",
 'ru': "Искать '$q'",
 'id': "Cari '$q'",
 'ne': "'$q' खोज्नुहोस्",
 'km': "ស្វែងរក '$q'",
 'my': "'$q' ရှာဖွေပါ",
 'si': "'$q' සොයන්න",
 'uz': "'$q' qidirish",
 'mn': "'$q' хайх",
 }, "Search '$q'");

 String get clearAll => _t({
 'ko': '전체 삭제',
 'en': 'Clear all',
 'zh': '清除全部',
 'hi': 'सब हटाएं',
 'ja': '全削除',
 'th': 'ลบทั้งหมด',
 'vi': 'Xóa tất cả',
 'bn': 'সব মুছুন',
 'ru': 'Очистить всё',
 'id': 'Hapus semua',
 'ne': 'सबै हटाउनुहोस्',
 'km': 'លុបទាំងអស់',
 'my': 'အားလုံးဖျက်ပါ',
 'si': 'සියල්ල මකන්න',
 'uz': 'Hammasini tozalash',
 'mn': 'Бүгдийг устгах',
 }, 'Clear all');

 String get searchGuide => _t({
 'ko': '직종·회사명 등 무엇이든 검색 (회사명은 한국어/영어로)',
 'en': 'Search job type, company & more (company names in Korean/English)',
 'zh': '搜索职位、公司等 (公司名请用韩语/英语)',
 'hi': 'नौकरी, कंपनी आदि खोजें (कंपनी नाम कोरियाई/अंग्रेज़ी में)',
 'ja': '職種・会社名など何でも検索 (会社名は韓国語/英語で)',
 'th': 'ค้นหาตำแหน่งงาน บริษัท ฯลฯ (ชื่อบริษัทเป็นภาษาเกาหลี/อังกฤษ)',
 'vi': 'Tìm ngành nghề, công ty... (tên công ty bằng tiếng Hàn/Anh)',
 'bn': 'চাকরি, কোম্পানি ইত্যাদি খুঁজুন (কোম্পানির নাম কোরিয়ান/ইংরেজিতে)',
 'ru': 'Ищите вакансии, компании и др. (название компании на корейском/английском)',
 'id': 'Cari pekerjaan, perusahaan, dll (nama perusahaan dalam Korea/Inggris)',
 'ne': 'पेशा, कम्पनी आदि खोज्नुहोस् (कम्पनीको नाम कोरियाली/अंग्रेजीमा)',
 'km': 'ស្វែងរកមុខរបរ ក្រុមហ៊ុន ។ល។ (ឈ្មោះក្រុមហ៊ុនជាភាសាកូរ៉េ/អង់គ្លេស)',
 'my': 'အလုပ်အကိုင်၊ ကုမ္ပဏီ စသည် ရှာဖွေပါ (ကုမ္ပဏီအမည်ကို ကိုရီးယား/အင်္ဂလိပ်)',
 'si': 'රැකියා, සමාගම් ආදිය සොයන්න (සමාගම් නම කොරියානු/ඉංග්‍රීසියෙන්)',
 'uz': 'Kasb, kompaniya va h.k. qidiring (kompaniya nomi koreys/ingliz tilida)',
 'mn': 'Мэргэжил, компани зэргийг хайна уу (компанийн нэр солонгос/англиар)',
 }, 'Search job type, company & more (company names in Korean/English)');

 String get searchEmptyHint => _t({
 'ko': '비자, 직종, 회사명을 검색해보세요',
 'en': 'Search visa, job type, company',
 'zh': '搜索签证、职种、公司',
 'hi': 'वीज़ा, नौकरी, कंपनी खोजें',
 'ja': 'ビザ、職種、会社名を検索',
 'th': 'ค้นหาวีซ่า อาชีพ บริษัท',
 'vi': 'Tìm visa, nghề, công ty',
 'bn': 'ভিসা, পেশা, কোম্পানি খুঁজুন',
 'ru': 'Ищите по визе, профессии, компании',
 'id': 'Cari visa, pekerjaan, perusahaan',
 'ne': 'भिसा, जागिर, कम्पनी खोज्नुहोस्',
 'km': 'ស្វែងរកទិដ្ឋាការ ការងារ ក្រុមហ៊ុន',
 'my': 'ဗီဇာ၊ အလုပ်၊ ကုမ္ပဏီ ရှာဖွေပါ',
 'si': 'වීසා, රැකියා, සමාගම සොයන්න',
 'uz': 'Viza, kasb, kompaniya qidiring',
 'mn': 'Виз, мэргэжил, компани хайна уу',
 }, 'Search visa, job type, company');

 String get noSearchResults => _t({
 'ko': '검색 결과가 없어요',
 'en': 'No results found',
 'zh': '没有搜索结果',
 'hi': 'कोई परिणाम नहीं मिला',
 'ja': '検索結果がありません',
 'th': 'ไม่พบผลลัพธ์',
 'vi': 'Không có kết quả',
 'bn': 'কোনো ফলাফল নেই',
 'ru': 'Ничего не найдено',
 'id': 'Tidak ada hasil',
 'ne': 'कुनै नतिजा भेटिएन',
 'km': 'រកមិនឃើញលទ្ធផល',
 'my': 'ရလဒ်မတွေ့ပါ',
 'si': 'ප්‍රතිඵල හමු නොවීය',
 'uz': 'Natija topilmadi',
 'mn': 'Үр дүн олдсонгүй',
 }, 'No results found');

 String get tryOtherKeyword => _t({
 'ko': '다른 검색어로 다시\n시도해보세요',
 'en': 'Try a different\nkeyword',
 'zh': '请尝试其他\n搜索词',
 'hi': 'कोई दूसरा\nकीवर्ड आज़माएं',
 'ja': '別のキーワードで\nお試しください',
 'th': 'ลองค้นหาด้วย\nคำอื่น',
 'vi': 'Hãy thử từ khóa\nkhác',
 'bn': 'অন্য কীওয়ার্ড\nচেষ্টা করুন',
 'ru': 'Попробуйте другое\nключевое слово',
 'id': 'Coba kata kunci\nlain',
 'ne': 'अर्को कीवर्ड\nप्रयास गर्नुहोस्',
 'km': 'សាកល្បងពាក្យគន្លឹះ\nផ្សេង',
 'my': 'အခြားသော့ချက်စာလုံး\nစမ်းကြည့်ပါ',
 'si': 'වෙනත් මූල පදයක්\nඅත්හදා බලන්න',
 'uz': 'Boshqa kalit so\'z\nbilan urinib ko\'ring',
 'mn': 'Өөр түлхүүр үгээр\nдахин оролдоно уу',
 }, 'Try a different\nkeyword');

 String get useFilter => _t({
 'ko': '필터로 찾아보기',
 'en': 'Use filters',
 'zh': '使用筛选',
 'hi': 'फ़िल्टर का उपयोग करें',
 'ja': 'フィルターで探す',
 'th': 'ใช้ตัวกรอง',
 'vi': 'Dùng bộ lọc',
 'bn': 'ফিল্টার ব্যবহার করুন',
 'ru': 'Использовать фильтр',
 'id': 'Gunakan filter',
 'ne': 'फिल्टर प्रयोग गर्नुहोस्',
 'km': 'ប្រើតម្រង',
 'my': 'စစ်ထုတ်မှုသုံးပါ',
 'si': 'පෙරහන් භාවිතා කරන්න',
 'uz': 'Filtrdan foydalaning',
 'mn': 'Шүүлтүүр ашиглах',
 }, 'Use filters');

 // ── Filter ──
 String get tabVisa => _t({
 'ko': '비자',
 'en': 'Visa',
 'zh': '签证',
 'hi': 'वीज़ा',
 'ja': 'ビザ',
 'th': 'วีซ่า',
 'vi': 'Visa',
 'bn': 'ভিসা',
 'ru': 'Виза',
 'id': 'Visa',
 'ne': 'भिसा',
 'km': 'ទិដ្ឋាការ',
 'my': 'ဗီဇာ',
 'si': 'වීසා',
 'uz': 'Viza',
 'mn': 'Виз',
 }, 'Visa');

 String get tabJobType => _t({
 'ko': '직종',
 'en': 'Job Category',
 'zh': '职种',
 'hi': 'नौकरी का प्रकार',
 'ja': '職種',
 'th': 'อาชีพ',
 'vi': 'Nghề',
 'bn': 'পেশার ধরন',
 'ru': 'Тип работы',
 'id': 'Jenis pekerjaan',
 'ne': 'जागिर प्रकार',
 'km': 'ប្រភេទការងារ',
 'my': 'အလုပ်အမျိုးအစား',
 'si': 'රැකියා වර්ගය',
 'uz': 'Ish turi',
 'mn': 'Ажлын төрөл',
 }, 'Job type');

 String get tabRegion => _t({
 'ko': '지역',
 'en': 'Region',
 'zh': '地区',
 'hi': 'क्षेत्र',
 'ja': '地域',
 'th': 'ภูมิภาค',
 'vi': 'Khu vực',
 'bn': 'অঞ্চল',
 'ru': 'Регион',
 'id': 'Wilayah',
 'ne': 'क्षेत्र',
 'km': 'តំបន់',
 'my': 'ဒေသ',
 'si': 'ප්‍රදේශය',
 'uz': 'Hudud',
 'mn': 'Бүс',
 }, 'Region');

 String get tabSalary => _t({
 'ko': '급여',
 'en': 'Salary',
 'zh': '薪资',
 'hi': 'वेतन',
 'ja': '給与',
 'th': 'เงินเดือน',
 'vi': 'Lương',
 'bn': 'বেতন',
 'ru': 'Зарплата',
 'id': 'Gaji',
 'ne': 'तलब',
 'km': 'ប្រាក់ខែ',
 'my': 'လစာ',
 'si': 'වැටුප',
 'uz': 'Maosh',
 'mn': 'Цалин',
 }, 'Salary');

 String get tabEmployType => _t({
 'ko': '고용형태',
 'en': 'Employment',
 'zh': '雇佣形式',
 'hi': 'रोज़गार प्रकार',
 'ja': '雇用形態',
 'th': 'ประเภทจ้างงาน',
 'vi': 'Hình thức',
 'bn': 'কর্মসংস্থানের ধরন',
 'ru': 'Тип занятости',
 'id': 'Tipe kerja',
 'ne': 'रोजगार प्रकार',
 'km': 'ទម្រង់ការងារ',
 'my': 'အလုပ်ခန့်ထားမှုပုံစံ',
 'si': 'රැකියා වර්ගය',
 'uz': 'Bandlik turi',
 'mn': 'Ажил эрхлэлтийн хэлбэр',
 }, 'Type');

 String get tabBenefits => _t({
 'ko': '복리후생',
 'en': 'Benefits',
 'zh': '福利待遇',
 'hi': 'लाभ',
 'ja': '福利厚生',
 'th': 'สวัสดิการ',
 'vi': 'Phúc lợi',
 'bn': 'সুবিধা',
 'ru': 'Льготы',
 'id': 'Tunjangan',
 'ne': 'सुविधा',
 'km': 'អត្ថប្រយោជន៍',
 'my': 'ခံစားခွင့်',
 'si': 'ප්‍රතිලාභ',
 'uz': 'Imtiyozlar',
 'mn': 'Нийгмийн халамж',
 }, 'Benefits');

 String get tabSite => _t({
 'ko': '채용사이트',
 'en': 'Job Site',
 'zh': '招聘网站',
 'hi': 'जॉब साइट',
 'ja': '求人サイト',
 'th': 'เว็บไซต์หางาน',
 'vi': 'Trang tuyển dụng',
 'bn': 'চাকরির সাইট',
 'ru': 'Сайт вакансий',
 'id': 'Situs lowongan',
 'ne': 'जागिर साइट',
 'km': 'គេហទំព័រការងារ',
 'my': 'အလုပ်ရှာဖွေရေးဆိုက်',
 'uz': 'Ish sayti',
 'mn': 'Ажлын сайт',
 'si': 'රැකියා අඩවිය',
 }, 'Job Site');

 String get tabCountry => _t({
 'ko': '국가',
 'en': 'Country',
 'zh': '国家',
 'hi': 'देश',
 'ja': '国',
 'th': 'ประเทศ',
 'vi': 'Quốc gia',
 'bn': 'দেশ',
 'ru': 'Страна',
 'id': 'Negara',
 'ne': 'देश',
 'km': 'ប្រទេស',
 'my': 'နိုင်ငံ',
 'si': 'රට',
 'uz': 'Davlat',
 'mn': 'Улс',
 }, 'Country');

 String get tabKoreanLevel => _t({
 'ko': '한국어',
 'en': 'Korean',
 'zh': '韩语水平',
 'hi': 'कोरियाई',
 'ja': '韓国語',
 'th': 'ภาษาเกาหลี',
 'vi': 'Tiếng Hàn',
 'bn': 'কোরিয়ান',
 'ru': 'Корейский',
 'id': 'B. Korea',
 'ne': 'कोरियाली',
 'km': 'ភាសាកូរ៉េ',
 'my': 'ကိုရီးယား',
 'si': 'කොරියානු',
 'uz': 'Koreys tili',
 'mn': 'Солонгос хэл',
 }, 'Korean');

 String get tabWorkSchedule => _t({
 'ko': '근무요일',
 'en': 'Schedule',
 'zh': '工作日',
 'hi': 'कार्यसूची',
 'ja': '勤務日',
 'th': 'วันทำงาน',
 'vi': 'Lịch làm',
 'bn': 'কর্মসূচি',
 'ru': 'График',
 'id': 'Jadwal',
 'ne': 'तालिका',
 'km': 'កាលវិភាគ',
 'my': 'အချိန်ဇယား',
 'si': 'කාලසටහන',
 'uz': 'Jadval',
 'mn': 'Хуваарь',
 }, 'Schedule');

 String get tabLanguage => _t({
 'ko': '언어',
 'en': 'Language',
 'zh': '语言',
 'hi': 'भाषा',
 'ja': '言語',
 'th': 'ภาษา',
 'vi': 'Ngôn ngữ',
 'bn': 'ভাষা',
 'ru': 'Язык',
 'id': 'Bahasa',
 'ne': 'भाषा',
 'km': 'ភាសា',
 'my': 'ဘာသာစကား',
 'si': 'භාෂාව',
 'uz': 'Til',
 'mn': 'Хэл',
 }, 'Language');

 // ── Visa group names ──
 String get visaGroupAny => _t({
 'ko': '비자 무관', 'en': 'Any visa', 'zh': '不限签证', 'hi': 'कोई भी वीज़ा', 'ja': 'ビザ不問', 'th': 'วีซ่าใดก็ได้', 'vi': 'Không giới hạn visa', 'bn': 'যেকোনো ভিসা',
 'ru': 'Любая виза', 'id': 'Visa apa saja', 'ne': 'कुनै पनि भिसा', 'km': 'ទិដ្ឋាការណាមួយ', 'my': 'မည်သည့်ဗီဇာမဆို',
 'si': 'ඕනෑම වීසා',
   'uz': 'Istalgan viza', 'mn': 'Ямар ч виз',
 }, 'Any visa');

 String get visaGroupE => _t({
 'ko': 'E — 취업/전문', 'en': 'E — Employment/Professional', 'zh': 'E — 就业/专业', 'hi': 'E — रोजगार/पेशेवर', 'ja': 'E — 就業/専門', 'th': 'E — จ้างงาน/วิชาชีพ', 'vi': 'E — Việc làm/Chuyên gia', 'bn': 'E — কর্মসংস্থান/পেশাদার',
 'ru': 'E — Трудоустройство', 'id': 'E — Pekerjaan/Profesional', 'ne': 'E — रोजगार/पेशेवर', 'km': 'E — ការងារ/វិជ្ជាជីវៈ', 'my': 'E — အလုပ်/ပညာရှင်',
 'si': 'E — රැකියා/වෘත්තීය',
   'uz': 'E — Ish/Mutaxassis', 'mn': 'E — Хөдөлмөр/Мэргэжил',
 }, 'E — Employment/Professional');

 String get visaGroupH => _t({
 'ko': 'H — 워킹홀리데이/방문취업', 'en': 'H — Working Holiday/Visit', 'zh': 'H — 打工度假/访问就业', 'hi': 'H — वर्किंग हॉलिडे/विज़िट', 'ja': 'H — ワーキングホリデー/訪問就業', 'th': 'H — วันหยุดทำงาน/เยี่ยมชม', 'vi': 'H — Working Holiday/Thăm', 'bn': 'H — ওয়ার্কিং হলিডে/ভিজিট',
 'ru': 'H — Рабочие каникулы', 'id': 'H — Working Holiday/Kunjungan', 'ne': 'H — वर्किंग हलिडे/भ्रमण', 'km': 'H — ថ្ងៃឈប់សម្រាកការងារ/ទស្សនកិច្ច', 'my': 'H — အလုပ်အားလပ်ရက်/လည်ပတ်',
 'si': 'H — වැඩ නිවාඩු/සංචාරය',
   'uz': 'H — Ishchi ta\'til/Tashrif', 'mn': 'H — Ажлын амралт/Айлчлал',
 }, 'H — Working Holiday/Visit');

 String get visaGroupF => _t({
 'ko': 'F — 재외동포/거주', 'en': 'F — Overseas Korean/Residence', 'zh': 'F — 海外同胞/居住', 'hi': 'F — विदेशी कोरियाई/निवास', 'ja': 'F — 在外同胞/居住', 'th': 'F — ชาวเกาหลีโพ้นทะเล/ถิ่นที่อยู่', 'vi': 'F — Kiều bào Hàn/Cư trú', 'bn': 'F — প্রবাসী কোরিয়ান/বসবাস',
 'ru': 'F — Зарубежные корейцы/Проживание', 'id': 'F — Korea perantauan/Tinggal', 'ne': 'F — विदेशी कोरियन/बसोबास', 'km': 'F — កូរ៉េក្រៅប្រទេស/លំនៅដ្ឋាន', 'my': 'F — နိုင်ငံခြားကိုရီးယား/နေထိုင်',
 'si': 'F — විදේශ කොරියානු/පදිංචිය',
   'uz': 'F — Yashash/Chet eldagi koreys', 'mn': 'F — Оршин суух/Гадаад солонгос',
 }, 'F — Overseas Korean/Residence');

 String get visaGroupD => _t({
 'ko': 'D — 유학/연수/투자', 'en': 'D — Study/Training/Investment', 'zh': 'D — 留学/研修/投资', 'hi': 'D — अध्ययन/प्रशिक्षण/निवेश', 'ja': 'D — 留学/研修/投資', 'th': 'D — เรียน/ฝึกงาน/ลงทุน', 'vi': 'D — Du học/Thực tập/Đầu tư', 'bn': 'D — পড়াশোনা/প্রশিক্ষণ/বিনিয়োগ',
 'ru': 'D — Учёба/Стажировка/Инвестиции', 'id': 'D — Studi/Pelatihan/Investasi', 'ne': 'D — अध्ययन/तालिम/लगानी', 'km': 'D — សិក្សា/បណ្ដុះបណ្ដាល/វិនិយោគ', 'my': 'D — ပညာ/လေ့ကျင့်/ရင်းနှီးမြှုပ်နှံ',
 'si': 'D — අධ්‍යයනය/පුහුණුව/ආයෝජනය',
   'uz': 'D — O\'qish/Amaliyot/Investitsiya', 'mn': 'D — Суралцах/Дадлага/Хөрөнгө оруулалт',
 }, 'D — Study/Training/Investment');

 String get visaGroupC => _t({
 'ko': 'C — 단기', 'en': 'C — Short-term', 'zh': 'C — 短期', 'hi': 'C — अल्पकालिक', 'ja': 'C — 短期', 'th': 'C — ระยะสั้น', 'vi': 'C — Ngắn hạn', 'bn': 'C — স্বল্পমেয়াদী',
 'ru': 'C — Краткосрочная', 'id': 'C — Jangka pendek', 'ne': 'C — अल्पकालीन', 'km': 'C — រយៈពេលខ្លី', 'my': 'C — ရေတိုကာလ',
 'si': 'C — කෙටි කාලීන',
   'uz': 'C — Qisqa muddatli', 'mn': 'C — Богино хугацааны',
 }, 'C — Short-term');

 String get visaGroupOther => _t({
 'ko': '기타', 'en': 'Other', 'zh': '其他', 'hi': 'अन्य', 'ja': 'その他', 'th': 'อื่นๆ', 'vi': 'Khác', 'bn': 'অন্যান্য',
 'ru': 'Другое', 'id': 'Lainnya', 'ne': 'अन्य', 'km': 'ផ្សេងៗ', 'my': 'အခြား',
 'si': 'වෙනත්',
   'uz': 'Boshqa', 'mn': 'Бусад',
 }, 'Other');

 String get tabVisaSponsorship => _t({
 'ko': '비자지원',
 'en': 'Visa sponsor',
 'zh': '签证赞助',
 'hi': 'वीज़ा प्रायोजन',
 'ja': 'ビザサポート',
 'th': 'สปอนเซอร์วีซ่า',
 'vi': 'Bảo lãnh visa',
 'bn': 'ভিসা স্পনসর',
 'ru': 'Визовая поддержка',
 'id': 'Sponsor visa',
 'ne': 'भिसा प्रायोजन',
 'km': 'ឧបត្ថម្ភទិដ្ឋាការ',
 'my': 'ဗီဇာပံ့ပိုးမှု',
 'si': 'වීසා අනුග්‍රාහකය',
 'uz': 'Viza homiylik',
 'mn': 'Визний ивээн тэтгэгч',
 }, 'Visa sponsor');

 String get tabGender => _t({
 'ko': '성별', 'en': 'Gender', 'zh': '性别', 'hi': 'लिंग', 'ja': '性別', 'th': 'เพศ', 'vi': 'Giới tính', 'bn': 'লিঙ্গ',
 'ru': 'Пол', 'id': 'Jenis kelamin', 'ne': 'लिङ्ग', 'km': 'ភេទ', 'my': 'လိင်',
 'si': 'ස්ත්‍රී පුරුෂ භාවය',
   'uz': 'Jins', 'mn': 'Хүйс',
 }, 'Gender');

 String get genderMale => _t({
 'ko': '남성', 'en': 'Male', 'zh': '男', 'hi': 'पुरुष', 'ja': '男性', 'th': 'ชาย', 'vi': 'Nam', 'bn': 'পুরুষ',
 'ru': 'Мужской', 'id': 'Pria', 'ne': 'पुरुष', 'km': 'ប្រុស', 'my': 'အမျိုးသား',
 'si': 'පුරුෂ',
   'uz': 'Erkak', 'mn': 'Эрэгтэй',
 }, 'Male');

 String get genderFemale => _t({
 'ko': '여성', 'en': 'Female', 'zh': '女', 'hi': 'महिला', 'ja': '女性', 'th': 'หญิง', 'vi': 'Nữ', 'bn': 'মহিলা',
 'ru': 'Женский', 'id': 'Wanita', 'ne': 'महिला', 'km': 'ស្រី', 'my': 'အမျိုးသမီး',
 'si': 'ස්ත්‍රී',
   'uz': 'Ayol', 'mn': 'Эмэгтэй',
 }, 'Female');

 String get genderAny => _t({
 'ko': '무관', 'en': 'Any', 'zh': '不限', 'hi': 'कोई भी', 'ja': '不問', 'th': 'ไม่จำกัด', 'vi': 'Không giới hạn', 'bn': 'যেকোনো',
 'ru': 'Любой', 'id': 'Semua', 'ne': 'कुनै पनि', 'km': 'មិនកំណត់', 'my': 'မရွေး',
 'si': 'ඕනෑම',
   'uz': 'Farqi yo\'q', 'mn': 'Хамаагүй',
 }, 'Any');

 String get tabSalaryType => _t({
 'ko': '급여유형', 'en': 'Pay type', 'zh': '薪资类型', 'hi': 'वेतन प्रकार', 'ja': '給与形態', 'th': 'ประเภทเงินเดือน', 'vi': 'Loại lương', 'bn': 'বেতনের ধরন',
 'ru': 'Тип зарплаты', 'id': 'Jenis gaji', 'ne': 'तलब प्रकार', 'km': 'ប្រភេទប្រាក់ខែ', 'my': 'လစာအမျိုးအစား',
 'si': 'ගෙවීම් වර්ගය',
   'uz': 'Ish haqi turi', 'mn': 'Цалингийн төрөл',
 }, 'Pay type');

 String get tabEducation => _t({
 'ko': '학력', 'en': 'Education', 'zh': '学历', 'hi': 'शिक्षा', 'ja': '学歴', 'th': 'การศึกษา', 'vi': 'Học vấn', 'bn': 'শিক্ষা',
 'ru': 'Образование', 'id': 'Pendidikan', 'ne': 'शिक्षा', 'km': 'ការអប់រំ', 'my': 'ပညာရေး',
 'si': 'අධ්‍යාපනය',
   'uz': 'Ma\'lumot', 'mn': 'Боловсрол',
 }, 'Education');

 String get tabExperience => _t({
 'ko': '경력', 'en': 'Experience', 'zh': '经验', 'hi': 'अनुभव', 'ja': '経験', 'th': 'ประสบการณ์', 'vi': 'Kinh nghiệm', 'bn': 'অভিজ্ঞতা',
 'ru': 'Опыт', 'id': 'Pengalaman', 'ne': 'अनुभव', 'km': 'បទពិសោធន៍', 'my': 'အတွေ့အကြုံ',
 'si': 'පළපුරුද්ද',
   'uz': 'Tajriba', 'mn': 'Туршлага',
 }, 'Experience');

 // ── Education codes ──
 String get eduNone => _t({
 'ko': '학력 무관', 'en': 'Any', 'zh': '不限', 'hi': 'कोई भी', 'ja': '不問', 'th': 'ไม่จำกัด', 'vi': 'Không yêu cầu', 'bn': 'যেকোনো',
 'ru': 'Любое', 'id': 'Semua', 'ne': 'कुनै पनि', 'km': 'មិនកំណត់', 'my': 'မရွေး',
 'si': 'ඕනෑම',
   'uz': 'Farqi yo\'q', 'mn': 'Хамаагүй',
 }, 'Any');
 String get eduMiddleSchool => _t({
 'ko': '중졸', 'en': 'Middle school', 'zh': '初中', 'hi': 'मिडिल स्कूल', 'ja': '中卒', 'th': 'มัธยมต้น', 'vi': 'THCS', 'bn': 'মাধ্যমিক',
 'ru': 'Средняя школа', 'id': 'SMP', 'ne': 'माध्यमिक', 'km': 'អនុវិទ្យាល័យ', 'my': 'အလယ်တန်း',
 'si': 'මධ්‍යම පාසල',
   'uz': 'O\'rta maktab', 'mn': 'Дунд сургууль',
 }, 'Middle school');
 String get eduHighSchool => _t({
 'ko': '고졸', 'en': 'High school', 'zh': '高中', 'hi': 'हाई स्कूल', 'ja': '高卒', 'th': 'มัธยมปลาย', 'vi': 'THPT', 'bn': 'উচ্চ মাধ্যমিক',
 'ru': 'Среднее', 'id': 'SMA', 'ne': 'उच्च माध्यमिक', 'km': 'វិទ្យាល័យ', 'my': 'အထက်တန်း',
 'si': 'උසස් පාසල',
   'uz': 'Yuqori maktab', 'mn': 'Ахлах сургууль',
 }, 'High school');
 String get eduCollege => _t({
 'ko': '전문대졸', 'en': 'College', 'zh': '大专', 'hi': 'कॉलेज', 'ja': '短大・専門卒', 'th': 'อนุปริญญา', 'vi': 'Cao đẳng', 'bn': 'কলেজ',
 'ru': 'Колледж', 'id': 'D3', 'ne': 'कलेज', 'km': 'មហាវិទ្យាល័យ', 'my': 'ကောလိပ်',
 'si': 'විද්‍යාලය',
   'uz': 'Kollej', 'mn': 'Коллеж',
 }, 'College');
 String get eduBachelor => _t({
 'ko': '대졸', 'en': 'Bachelor\'s', 'zh': '本科', 'hi': 'स्नातक', 'ja': '大卒', 'th': 'ปริญญาตรี', 'vi': 'Đại học', 'bn': 'স্নাতক',
 'ru': 'Бакалавр', 'id': 'S1', 'ne': 'स्नातक', 'km': 'បរិញ្ញាបត្រ', 'my': 'ဘွဲ့ရ', 'si': 'උපාධිය',
   'uz': 'Bakalavr', 'mn': 'Бакалавр',
 }, 'Bachelor\'s');
 String get eduMaster => _t({
 'ko': '석사', 'en': 'Master\'s', 'zh': '硕士', 'hi': 'परास्नातक', 'ja': '修士', 'th': 'ปริญญาโท', 'vi': 'Thạc sĩ', 'bn': 'স্নাতকোত্তর',
 'ru': 'Магистр', 'id': 'S2', 'ne': 'स्नातकोत्तर', 'km': 'អនុបណ្ឌិត', 'my': 'မဟာဘွဲ့', 'si': 'ශාස්ත්‍රපති',
   'uz': 'Magistr', 'mn': 'Магистр',
 }, 'Master\'s');
 String get eduDoctor => _t({
 'ko': '박사', 'en': 'Doctorate', 'zh': '博士', 'hi': 'डॉक्टरेट', 'ja': '博士', 'th': 'ปริญญาเอก', 'vi': 'Tiến sĩ', 'bn': 'ডক্টরেট',
 'ru': 'Доктор', 'id': 'S3', 'ne': 'विद्यावारिधि', 'km': 'បណ្ឌិត', 'my': 'ပါရဂူ',
 'si': 'ආචාර්ය',
   'uz': 'Doktorantura', 'mn': 'Доктор',
 }, 'Doctorate');

 // ── Experience codes ──
 String get expNone => _t({
 'ko': '경력 무관', 'en': 'Any', 'zh': '不限', 'hi': 'कोई भी', 'ja': '不問', 'th': 'ไม่จำกัด', 'vi': 'Không yêu cầu', 'bn': 'যেকোনো',
 'ru': 'Любой', 'id': 'Semua', 'ne': 'कुनै पनि', 'km': 'មិនកំណត់', 'my': 'မရွေး',
 'si': 'ඕනෑම',
   'uz': 'Farqi yo\'q', 'mn': 'Хамаагүй',
 }, 'Any');
 String get expNewcomer => _t({
 'ko': '신입', 'en': 'Entry level', 'zh': '应届', 'hi': 'फ्रेशर', 'ja': '新卒', 'th': 'จบใหม่', 'vi': 'Mới ra trường', 'bn': 'নবীন',
 'ru': 'Начинающий', 'id': 'Fresh graduate', 'ne': 'नयाँ', 'km': 'អ្នកចូលថ្មី', 'my': 'အသစ်',
 'si': 'ආරම්භක මට්ටම',
   'uz': 'Yangi boshlovchi', 'mn': 'Шинэ ажилтан',
 }, 'Entry level');
 String get exp1y => _t({
 'ko': '1년 이상', 'en': '1+ years', 'zh': '1年以上', 'hi': '1+ वर्ष', 'ja': '1年以上', 'th': '1+ ปี', 'vi': '1+ năm', 'bn': '1+ বছর',
 'ru': '1+ год', 'id': '1+ tahun', 'ne': '1+ वर्ष', 'km': '1+ ឆ្នាំ', 'my': '1+ နှစ်',
 'si': 'අවුරුදු 1+',
   'uz': '1+ yil', 'mn': '1+ жил',
 }, '1+ years');
 String get exp3y => _t({
 'ko': '3년 이상', 'en': '3+ years', 'zh': '3年以上', 'hi': '3+ वर्ष', 'ja': '3年以上', 'th': '3+ ปี', 'vi': '3+ năm', 'bn': '3+ বছর',
 'ru': '3+ года', 'id': '3+ tahun', 'ne': '3+ वर्ष', 'km': '3+ ឆ្នាំ', 'my': '3+ နှစ်',
 'si': 'අවුරුදු 3+',
   'uz': '3+ yil', 'mn': '3+ жил',
 }, '3+ years');
 String get exp5y => _t({
 'ko': '5년 이상', 'en': '5+ years', 'zh': '5年以上', 'hi': '5+ वर्ष', 'ja': '5年以上', 'th': '5+ ปี', 'vi': '5+ năm', 'bn': '5+ বছর',
 'ru': '5+ лет', 'id': '5+ tahun', 'ne': '5+ वर्ष', 'km': '5+ ឆ្នាំ', 'my': '5+ နှစ်',
 'si': 'අවුරුදු 5+',
   'uz': '5+ yil', 'mn': '5+ жил',
 }, '5+ years');
 String get exp10y => _t({
 'ko': '10년 이상', 'en': '10+ years', 'zh': '10年以上', 'hi': '10+ वर्ष', 'ja': '10年以上', 'th': '10+ ปี', 'vi': '10+ năm', 'bn': '10+ বছর',
 'ru': '10+ лет', 'id': '10+ tahun', 'ne': '10+ वर्ष', 'km': '10+ ឆ្នាំ', 'my': '10+ နှစ်',
 'si': 'අවුරුදු 10+',
   'uz': '10+ yil', 'mn': '10+ жил',
 }, '10+ years');

 String educationLabel(String code) {
 switch (code) {
 case 'none': return eduNone;
 case 'middle_school': return eduMiddleSchool;
 case 'high_school': return eduHighSchool;
 case 'college': return eduCollege;
 case 'bachelor': return eduBachelor;
 case 'master': return eduMaster;
 case 'doctor': return eduDoctor;
 default: return code;
 }
 }

 String experienceLabel(String code) {
 switch (code) {
 case 'none': return expNone;
 case 'newcomer': return expNewcomer;
 case '1y': return exp1y;
 case '3y': return exp3y;
 case '5y': return exp5y;
 case '10y': return exp10y;
 default: return code;
 }
 }

 String get tabQualification => _t({
 'ko': '지원자격', 'en': 'Qualification', 'zh': '应聘条件', 'hi': 'योग्यता', 'ja': '応募資格', 'th': 'คุณสมบัติ', 'vi': 'Điều kiện', 'bn': 'যোগ্যতা',
 'ru': 'Квалификация', 'id': 'Kualifikasi', 'ne': 'योग्यता', 'km': 'គុណវុឌ្ឍិ', 'my': 'အရည်အချင်း',
 'si': 'සුදුසුකම්',
   'uz': 'Talablar', 'mn': 'Шаардлага',
 }, 'Qualification');

 String get tabWork => _t({
 'ko': '근무', 'en': 'Work', 'zh': '工作', 'hi': 'कार्य', 'ja': '勤務', 'th': 'การทำงาน', 'vi': 'Công việc', 'bn': 'কাজ',
 'ru': 'Работа', 'id': 'Kerja', 'ne': 'काम', 'km': 'ការងារ', 'my': 'အလုပ်',
 'si': 'වැඩ',
   'uz': 'Ish', 'mn': 'Ажил',
 }, 'Work');

 // ── Salary filter options ──
 String get salaryAll => _t({
 'ko': '전체',
 'en': 'All',
 'zh': '全部',
 'hi': 'सभी',
 'ja': 'すべて',
 'th': 'ทั้งหมด',
 'vi': 'Tất cả',
 'bn': 'সব',
 'ru': 'Все',
 'id': 'Semua',
 'ne': 'सबै',
 'km': 'ទាំងអស់',
 'my': 'အားလုံး',
 'si': 'සියල්ල',
 'uz': 'Barchasi',
 'mn': 'Бүгд',
 }, 'All');

 String get salaryUnder100 => _t({
 'ko': '100만원 미만',
 'en': 'Under 1M',
 'zh': '100万以下',
 'hi': '1M से कम',
 'ja': '100万未満',
 'th': 'ต่ำกว่า 1 ล้าน',
 'vi': 'Dưới 1 triệu',
 'bn': '১ মিলিয়নের কম',
 'ru': 'Менее 1М',
 'id': 'Di bawah 1 juta',
 'ne': '१ मिलियन भन्दा कम',
 'km': 'ក្រោម 1 លាន',
 'my': '1 သန်းအောက်',
 'si': '1M ට අඩු',
 'uz': '1M dan kam',
 'mn': '1 саяас доош',
 }, 'Under 1M');

 String get salary100to200 => _t({
 'ko': '100~200만원',
 'en': '1M - 2M',
 'zh': '100-200万',
 'hi': '1M - 2M',
 'ja': '100〜200万',
 'th': '1-2 ล้าน',
 'vi': '1-2 triệu',
 'bn': '1M - 2M',
 'ru': '1М - 2М',
 'id': '1 juta - 2 juta',
 'ne': '1M - 2M',
 'km': '1 - 2 លាន',
 'my': '1 - 2 သန်း',
 'si': '1M - 2M',
 'uz': '1M - 2M',
 'mn': '1 - 2 сая',
 }, '1M - 2M');

 String get salary200to300 => _t({
 'ko': '200~300만원',
 'en': '2M - 3M',
 'zh': '200-300万',
 'hi': '2M - 3M',
 'ja': '200〜300万',
 'th': '2-3 ล้าน',
 'vi': '2-3 triệu',
 'bn': '2M - 3M',
 'ru': '2М - 3М',
 'id': '2 juta - 3 juta',
 'ne': '2M - 3M',
 'km': '2 - 3 លាន',
 'my': '2 - 3 သန်း',
 'si': '2M - 3M',
 'uz': '2M - 3M',
 'mn': '2 - 3 сая',
 }, '2M - 3M');

 String get salary300to400 => _t({
 'ko': '300~400만원',
 'en': '3M - 4M',
 'zh': '300-400万',
 'hi': '3M - 4M',
 'ja': '300〜400万',
 'th': '3-4 ล้าน',
 'vi': '3-4 triệu',
 'bn': '3M - 4M',
 'ru': '3М - 4М',
 'id': '3 juta - 4 juta',
 'ne': '3M - 4M',
 'km': '3 - 4 លាន',
 'my': '3 - 4 သန်း',
 'si': '3M - 4M',
 'uz': '3M - 4M',
 'mn': '3 - 4 сая',
 }, '3M - 4M');

 String get salaryOver400 => _t({
 'ko': '400만원 이상',
 'en': 'Over 4M',
 'zh': '400万以上',
 'hi': '4M से अधिक',
 'ja': '400万以上',
 'th': 'มากกว่า 4 ล้าน',
 'vi': 'Trên 4 triệu',
 'bn': '4 মিলিয়নের বেশি',
 'ru': 'Более 4М',
 'id': 'Di atas 4 juta',
 'ne': '4 मिलियन भन्दा बढी',
 'km': 'ជាង 4 លាន',
 'my': '4 သန်းအထက်',
 'si': '4M ට වැඩි',
 'uz': '4M dan ko\'p',
 'mn': '4 саяас дээш',
 }, 'Over 4M');

 // 월급 범위
 List<String> get salaryMonthlyOptions => [salaryAll, salaryUnder100, salary100to200, salary200to300, salary300to400, salaryOver400];

 // 시급 범위
 String get hourlyUnder10000 => _t({
 'ko': '10,000원 미만',
 'en': 'Under ₩10,000',
 'zh': '1万以下',
 'hi': '₩10,000 से कम',
 'ja': '1万円未満',
 'th': 'ต่ำกว่า 10,000',
 'vi': 'Dưới 10,000',
 'bn': '₩10,000 এর কম',
 'ru': 'Менее ₩10 000',
 'id': 'Di bawah ₩10.000',
 'ne': '₩10,000 भन्दा कम',
 'km': 'ក្រោម ₩10,000',
 'my': '₩10,000 အောက်',
 'si': '₩10,000 ට අඩු',
 'uz': '₩10,000 dan kam',
 'mn': '₩10,000-аас доош',
 }, 'Under ₩10,000');

 String get hourly10000to12000 => _t({
 'ko': '10,000~12,000원',
 'en': '₩10,000 - ₩12,000',
 'zh': '1万-1.2万',
 'hi': '₩10,000 - ₩12,000',
 'ja': '1万〜1.2万円',
 'th': '10,000-12,000',
 'vi': '10,000-12,000',
 'bn': '₩10,000 - ₩12,000',
 'ru': '₩10 000 - ₩12 000',
 'id': '₩10.000 - ₩12.000',
 'ne': '₩10,000 - ₩12,000',
 'km': '₩10,000 - ₩12,000',
 'my': '₩10,000 - ₩12,000',
 'si': '₩10,000 - ₩12,000',
 'uz': '₩10,000 - ₩12,000',
 'mn': '₩10,000 - ₩12,000',
 }, '₩10,000 - ₩12,000');

 String get hourly12000to15000 => _t({
 'ko': '12,000~15,000원',
 'en': '₩12,000 - ₩15,000',
 'zh': '1.2万-1.5万',
 'hi': '₩12,000 - ₩15,000',
 'ja': '1.2万〜1.5万円',
 'th': '12,000-15,000',
 'vi': '12,000-15,000',
 'bn': '₩12,000 - ₩15,000',
 'ru': '₩12 000 - ₩15 000',
 'id': '₩12.000 - ₩15.000',
 'ne': '₩12,000 - ₩15,000',
 'km': '₩12,000 - ₩15,000',
 'my': '₩12,000 - ₩15,000',
 'si': '₩12,000 - ₩15,000',
 'uz': '₩12,000 - ₩15,000',
 'mn': '₩12,000 - ₩15,000',
 }, '₩12,000 - ₩15,000');

 String get hourlyOver15000 => _t({
 'ko': '15,000원 이상',
 'en': 'Over ₩15,000',
 'zh': '1.5万以上',
 'hi': '₩15,000 से अधिक',
 'ja': '1.5万円以上',
 'th': 'มากกว่า 15,000',
 'vi': 'Trên 15,000',
 'bn': '₩15,000 এর বেশি',
 'ru': 'Более ₩15 000',
 'id': 'Di atas ₩15.000',
 'ne': '₩15,000 भन्दा बढी',
 'km': 'ជាង ₩15,000',
 'my': '₩15,000 အထက်',
 'si': '₩15,000 ට වැඩි',
 'uz': '₩15,000 dan ko\'p',
 'mn': '₩15,000-аас дээш',
 }, 'Over ₩15,000');

 List<String> get salaryHourlyOptions => [salaryAll, hourly10000to12000, hourly12000to15000, hourlyOver15000];

 // 연봉 범위
 String get annualUnder2000 => _t({
 'ko': '2,000만원 미만',
 'en': 'Under 20M',
 'zh': '2千万以下',
 'hi': '20M से कम',
 'ja': '2000万未満',
 'th': 'ต่ำกว่า 20 ล้าน',
 'vi': 'Dưới 20 triệu',
 'bn': '20 মিলিয়নের কম',
 'ru': 'Менее 20М',
 'id': 'Di bawah 20 juta',
 'ne': '20 मिलियन भन्दा कम',
 'km': 'ក្រោម 20 លាន',
 'my': '20 သန်းအောက်',
 'si': '20M ට අඩු',
 'uz': '20M dan kam',
 'mn': '20 саяас доош',
 }, 'Under 20M');

 String get annual2000to3000 => _t({
 'ko': '2,000~3,000만원',
 'en': '20M - 30M',
 'zh': '2千-3千万',
 'hi': '20M - 30M',
 'ja': '2000万〜3000万',
 'th': '20-30 ล้าน',
 'vi': '20-30 triệu',
 'bn': '20M - 30M',
 'ru': '20М - 30М',
 'id': '20 juta - 30 juta',
 'ne': '20M - 30M',
 'km': '20 - 30 លាន',
 'my': '20 - 30 သန်း',
 'si': '20M - 30M',
 'uz': '20M - 30M',
 'mn': '20 - 30 сая',
 }, '20M - 30M');

 String get annual3000to4000 => _t({
 'ko': '3,000~4,000만원',
 'en': '30M - 40M',
 'zh': '3千-4千万',
 'hi': '30M - 40M',
 'ja': '3000万〜4000万',
 'th': '30-40 ล้าน',
 'vi': '30-40 triệu',
 'bn': '30M - 40M',
 'ru': '30М - 40М',
 'id': '30 juta - 40 juta',
 'ne': '30M - 40M',
 'km': '30 - 40 លាន',
 'my': '30 - 40 သန်း',
 'si': '30M - 40M',
 'uz': '30M - 40M',
 'mn': '30 - 40 сая',
 }, '30M - 40M');

 String get annual4000to5000 => _t({
 'ko': '4,000~5,000만원',
 'en': '40M - 50M',
 'zh': '4千-5千万',
 'hi': '40M - 50M',
 'ja': '4000万〜5000万',
 'th': '40-50 ล้าน',
 'vi': '40-50 triệu',
 'bn': '40M - 50M',
 'ru': '40М - 50М',
 'id': '40 juta - 50 juta',
 'ne': '40M - 50M',
 'km': '40 - 50 លាន',
 'my': '40 - 50 သန်း',
 'si': '40M - 50M',
 'uz': '40M - 50M',
 'mn': '40 - 50 сая',
 }, '40M - 50M');

 String get annualOver5000 => _t({
 'ko': '5,000만원 이상',
 'en': 'Over 50M',
 'zh': '5千万以上',
 'hi': '50M से अधिक',
 'ja': '5000万以上',
 'th': 'มากกว่า 50 ล้าน',
 'vi': 'Trên 50 triệu',
 'bn': '50 মিলিয়নের বেশি',
 'ru': 'Более 50М',
 'id': 'Di atas 50 juta',
 'ne': '50 मिलियन भन्दा बढी',
 'km': 'ជាង 50 លាន',
 'my': '50 သန်းအထက်',
 'si': '50M ට වැඩි',
 'uz': '50M dan ko\'p',
 'mn': '50 саяас дээш',
 }, 'Over 50M');

 List<String> get salaryAnnualOptions => [salaryAll, annualUnder2000, annual2000to3000, annual3000to4000, annual4000to5000, annualOver5000];

 String get selectAll => _t({
 'ko': '전체 선택',
 'en': 'Select all',
 'zh': '全选',
 'hi': 'सभी चुनें',
 'ja': '全て選択',
 'th': 'เลือกทั้งหมด',
 'vi': 'Chọn tất cả',
 'bn': 'সব নির্বাচন',
 'ru': 'Выбрать все',
 'id': 'Pilih semua',
 'ne': 'सबै छान्नुहोस्',
 'km': 'ជ្រើសរើសទាំងអស់',
 'my': 'အားလုံးရွေးချယ်ပါ',
 'si': 'සියල්ල තෝරන්න',
 'uz': 'Hammasini tanlash',
 'mn': 'Бүгдийг сонгох',
 }, 'Select all');

 String get deselectAll => _t({
 'ko': '전체 해제',
 'en': 'Deselect all',
 'zh': '取消全选',
 'hi': 'सभी अचयनित करें',
 'ja': '全て解除',
 'th': 'ยกเลิกทั้งหมด',
 'vi': 'Bỏ chọn tất cả',
 'bn': 'সব নির্বাচন বাতিল',
 'ru': 'Снять все',
 'id': 'Batalkan semua',
 'ne': 'सबै अचयन गर्नुहोस्',
 'km': 'ដកជម្រើសទាំងអស់',
 'my': 'အားလုံးရွေးချယ်မှုဖြုတ်ပါ',
 'si': 'සියල්ල ඉවත් කරන්න',
 'uz': 'Hammasini bekor qilish',
 'mn': 'Бүгдийг цуцлах',
 }, 'Deselect all');

 String get reset => _t({
 'ko': '초기화',
 'en': 'Reset',
 'zh': '重置',
 'hi': 'रीसेट',
 'ja': 'リセット',
 'th': 'รีเซ็ต',
 'vi': 'Đặt lại',
 'bn': 'রিসেট',
 'ru': 'Сбросить',
 'id': 'Reset',
 'ne': 'रिसेट',
 'km': 'កំណត់ឡើងវិញ',
 'my': 'ပြန်လည်သတ်မှတ်ပါ',
 'si': 'නැවත සකසන්න',
 'uz': 'Qayta o\'rnatish',
 'mn': 'Дахин тохируулах',
 }, 'Reset');

 String get showResults => _t({
 'ko': '결과보기',
 'en': 'Show results',
 'zh': '查看结果',
 'hi': 'परिणाम दिखाएं',
 'ja': '結果を見る',
 'th': 'ดูผลลัพธ์',
 'vi': 'Xem kết quả',
 'bn': 'ফলাফল দেখুন',
 'ru': 'Показать',
 'id': 'Lihat hasil',
 'ne': 'नतिजा हेर्नुहोस्',
 'km': 'មើលលទ្ធផល',
 'my': 'ရလဒ်များကြည့်ပါ',
 'si': 'ප්‍රතිඵල පෙන්වන්න',
 'uz': 'Natijalarni ko\'rish',
 'mn': 'Үр дүн харах',
 }, 'Show results');

 String showResultsCount(int count) => _t({
 'ko': '결과보기 ($count개 적용)',
 'en': 'Show results ($count applied)',
 'zh': '查看结果（已选$count项）',
 'hi': 'परिणाम दिखाएं ($count लागू)',
 'ja': '結果を見る ($count件適用)',
 'th': 'ดูผลลัพธ์ (เลือก $count)',
 'vi': 'Xem kết quả ($count đã chọn)',
 'bn': 'ফলাফল দেখুন ($count প্রযুক্ত)',
 'ru': 'Показать ($count применено)',
 'id': 'Lihat hasil ($count diterapkan)',
 'ne': 'नतिजा हेर्नुहोस् ($count लागू)',
 'km': 'មើលលទ្ធផល ($count បានអនុវត្ត)',
 'my': 'ရလဒ်ကြည့်ပါ ($count အသုံးပြု)',
 'si': 'ප්‍රතිඵල පෙන්වන්න ($count යොදා ඇත)',
 'uz': 'Natijalarni ko\'rish ($count qo\'llanildi)',
 'mn': 'Үр дүн харах ($count хэрэглэсэн)',
 }, 'Show results ($count applied)');

 // ── Job Detail ──
 String get jobDetail => _t({
 'ko': '공고 상세',
 'en': 'Job detail',
 'zh': '招聘详情',
 'hi': 'नौकरी विवरण',
 'ja': '求人詳細',
 'th': 'รายละเอียดงาน',
 'vi': 'Chi tiết việc làm',
 'bn': 'চাকরির বিবরণ',
 'ru': 'Подробности вакансии',
 'id': 'Detail lowongan',
 'ne': 'जागिर विवरण',
 'km': 'ព័ត៌មានលម្អិតការងារ',
 'my': 'အလုပ်အသေးစိတ်',
 'si': 'රැකියා විස්තර',
 'uz': 'Ish tafsilotlari',
 'mn': 'Ажлын дэлгэрэнгүй',
 }, 'Job detail');

 String get jobNotFound => _t({
 'ko': '공고를 찾을 수 없습니다',
 'en': 'Job not found',
 'zh': '找不到招聘信息',
 'hi': 'नौकरी नहीं मिली',
 'ja': '求人が見つかりません',
 'th': 'ไม่พบงาน',
 'vi': 'Không tìm thấy việc làm',
 'bn': 'চাকরি পাওয়া যায়নি',
 'ru': 'Вакансия не найдена',
 'id': 'Lowongan tidak ditemukan',
 'ne': 'जागिर भेटिएन',
 'km': 'រកមិនឃើញការងារ',
 'my': 'အလုပ်မတွေ့ပါ',
 'si': 'රැකියාව හමු නොවීය',
 'uz': 'Ish topilmadi',
 'mn': 'Ажил олдсонгүй',
 }, 'Job not found');

 String get infoSalary => _t({
 'ko': '급여',
 'en': 'Salary',
 'zh': '薪资',
 'hi': 'वेतन',
 'ja': '給与',
 'th': 'เงินเดือน',
 'vi': 'Lương',
 'bn': 'বেতন',
 'ru': 'Зарплата',
 'id': 'Gaji',
 'ne': 'तलब',
 'km': 'ប្រាក់ខែ',
 'my': 'လစာ',
 'si': 'වැටුප',
 'uz': 'Maosh',
 'mn': 'Цалин',
 }, 'Salary');

 String get salaryByCompany => _t({
 'ko': '회사 내규',
 'en': 'Company policy',
 'zh': '公司内部规定',
 'hi': 'कंपनी नियमावली',
 'ja': '社内規定',
 'th': 'ระเบียบบริษัท',
 'vi': 'Nội quy công ty',
 'bn': 'কোম্পানির নীতি',
 'ru': 'Внутренние правила',
 'id': 'Kebijakan perusahaan',
 'ne': 'कम्पनी नियमावली',
 'km': 'បទបញ្ជាក្រុមហ៊ុន',
 'my': 'ကုမ္ပဏီစည်းမျဉ်း',
 'si': 'සමාගම් ප්‍රතිපත්තිය',
 'uz': 'Kompaniya nizomi',
 'mn': 'Компанийн дотоод журам',
 }, 'Company policy');

 String get salaryHourly => _t({
 'ko': '시급',
 'en': 'Hourly',
 'zh': '时薪',
 'hi': 'प्रति घंटा',
 'ja': '時給',
 'th': 'รายชั่วโมง',
 'vi': 'Theo giờ',
 'bn': 'ঘণ্টায়',
 'ru': 'Почасовая',
 'id': 'Per jam',
 'ne': 'प्रति घण्टा',
 'km': 'ក្នុងមួយម៉ោង',
 'my': 'နာရီစား',
 'si': 'පැයට',
 'uz': 'Soatlik',
 'mn': 'Цагийн',
 }, 'Hourly');

 String get salaryWeekly => _t({
 'ko': '주급',
 'en': 'Weekly',
 'zh': '周薪',
 'hi': 'साप्ताहिक',
 'ja': '週給',
 'th': 'รายสัปดาห์',
 'vi': 'Theo tuần',
 'bn': 'সাপ্তাহিক',
 'ru': 'Еженедельная',
 'id': 'Mingguan',
 'ne': 'साप्ताहिक',
 'km': 'ប្រចាំសប្តាហ៍',
 'my': 'အပတ်စဉ်',
 'si': 'සතිපතා',
 'uz': 'Haftalik',
 'mn': '7 хоногийн',
 }, 'Weekly');

 String get salaryDaily => _t({
 'ko': '일급',
 'en': 'Daily',
 'zh': '日薪',
 'hi': 'दैनिक',
 'ja': '日給',
 'th': 'รายวัน',
 'vi': 'Theo ngày',
 'bn': 'দৈনিক',
 'ru': 'Дневная',
 'id': 'Harian',
 'ne': 'दैनिक',
 'km': 'ប្រចាំថ្ងៃ',
 'my': 'နေ့စဉ်',
 'si': 'දිනකට',
 'uz': 'Kunlik',
 'mn': 'Өдрийн',
 }, 'Daily');

 String get salaryMonthly => _t({
 'ko': '월급',
 'en': 'Monthly',
 'zh': '月薪',
 'hi': 'मासिक',
 'ja': '月給',
 'th': 'รายเดือน',
 'vi': 'Theo tháng',
 'bn': 'মাসিক',
 'ru': 'Ежемесячная',
 'id': 'Bulanan',
 'ne': 'मासिक',
 'km': 'ប្រចាំខែ',
 'my': 'လစဉ်',
 'si': 'මාසිකව',
 'uz': 'Oylik',
 'mn': 'Сарын',
 }, 'Monthly');

 String get salaryAnnual => _t({
 'ko': '연봉',
 'en': 'Annual',
 'zh': '年薪',
 'hi': 'वार्षिक',
 'ja': '年収',
 'th': 'รายปี',
 'vi': 'Theo năm',
 'bn': 'বার্ষিক',
 'ru': 'Годовая',
 'id': 'Tahunan',
 'ne': 'वार्षिक',
 'km': 'ប្រចាំឆ្នាំ',
 'my': 'နှစ်စဉ်',
 'si': 'වාර්ෂිකව',
 'uz': 'Yillik',
 'mn': 'Жилийн',
 }, 'Annual');

 String get salaryNegotiable => _t({
 'ko': '협의',
 'en': 'Negotiable',
 'zh': '面议',
 'hi': 'बातचीत योग्य',
 'ja': '応相談',
 'th': 'ต่อรองได้',
 'vi': 'Thỏa thuận',
 'bn': 'আলোচনা সাপেক্ষে',
 'ru': 'Договорная',
 'id': 'Bisa dinegosiasi',
 'ne': 'सम्झौता योग्य',
 'km': 'អាចចរចាបាន',
 'my': 'ညှိနှိုင်းနိုင်',
 'si': 'සාකච්ඡා කළ හැක',
 'uz': 'Kelishiladi',
 'mn': 'Тохиролцоно',
 }, 'Negotiable');

 /// 급여 포맷: salaryAmount + salaryType → 다국어 표시
 String formatSalary(String salaryTypeRaw, int amount) {
 final typeLabel = switch (salaryTypeRaw) {
 'hourly' => salaryHourly,
 'daily' => salaryDaily,
 'weekly' => salaryWeekly,
 'monthly' => salaryMonthly,
 'annual' => salaryAnnual,
 _ => '',
 };

 // 한국어: 만원 단위 사용
 if (_l == 'ko') {
 final amountStr = _formatKorean(amount);
 return '$typeLabel $amountStr';
 }

 // 일본어: 万円 단위
 if (_l == 'ja') {
 final amountStr = _formatJapanese(amount);
 return '$typeLabel $amountStr';
 }

 // 중국어: 万韩元 단위
 if (_l == 'zh' || _l == 'zh-yue') {
 final amountStr = _formatChinese(amount);
 return '$typeLabel $amountStr';
 }

 // 독일어/프랑스어/포르투갈어/스페인어/이탈리아어/폴란드어/러시아어/터키어: 마침표 천단위
 if ({'de', 'fr', 'pt', 'es', 'it', 'pl', 'ru', 'tr'}.contains(_l)) {
 final amountStr = _formatDot(amount);
 return '₩$amountStr / $typeLabel';
 }

 // 아랍어/히브리어: RTL
 if (_l == 'ar' || _l == 'he') {
 final amountStr = _formatComma(amount);
 return '$typeLabel ₩$amountStr';
 }

 // 힌디/네팔/벵갈: 인도식 (lakh 구분)
 if ({'hi', 'ne', 'bn'}.contains(_l)) {
 final amountStr = _formatIndian(amount);
 return '₩$amountStr / $typeLabel';
 }

 // 그 외: ₩10,030 / Hourly
 final amountStr = _formatComma(amount);
 return '₩$amountStr / $typeLabel';
 }

 /// 금액만 포맷 (타입 라벨 없이, 범위 표시용)
 String formatSalaryAmount(int amount) {
 if (_l == 'ko') return _formatKorean(amount);
 if (_l == 'ja') return _formatJapanese(amount);
 if (_l == 'zh' || _l == 'zh-yue') return _formatChinese(amount);
 if ({'de', 'fr', 'pt', 'es', 'it', 'pl', 'ru', 'tr'}.contains(_l)) return '₩${_formatDot(amount)}';
 if ({'hi', 'ne', 'bn'}.contains(_l)) return '₩${_formatIndian(amount)}';
 return '₩${_formatComma(amount)}';
 }

 /// 범위 표시: 타입 라벨 한 번만
 String formatSalaryRangeDisplay(String typeLabel, String minAmount, String maxAmount) {
 // ko/ja/zh/ar/he: 타입이 앞에 오는 언어
 if ({'ko', 'ja', 'zh', 'zh-yue', 'ar', 'he'}.contains(_l)) {
   return '$typeLabel $minAmount ~ $maxAmount';
 }
 // 그 외: 금액 ~ 금액 / 타입
 return '$minAmount ~ $maxAmount / $typeLabel';
 }

 /// 한국어: 10,030원, 200만원, 3,000만원
 String _formatKorean(int n) {
 if (n >= 10000 && n % 10000 == 0) {
 final man = n ~/ 10000;
 return '${_formatComma(man)}만원';
 }
 return '${_formatComma(n)}원';
 }

 /// 일본어: 1万300ウォン, 200万ウォン
 String _formatJapanese(int n) {
 if (n >= 10000 && n % 10000 == 0) {
 final man = n ~/ 10000;
 return '${_formatComma(man)}万ウォン';
 }
 return '${_formatComma(n)}ウォン';
 }

 /// 중국어: 200万韩元
 String _formatChinese(int n) {
 if (n >= 10000 && n % 10000 == 0) {
 final wan = n ~/ 10000;
 return '${_formatComma(wan)}万韩元';
 }
 return '${_formatComma(n)}韩元';
 }

 /// 콤마 구분 (영어 등): 2,000,000
 String _formatComma(int n) {
 final str = n.toString();
 final buf = StringBuffer();
 for (var i = 0; i < str.length; i++) {
 if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
 buf.write(str[i]);
 }
 return buf.toString();
 }

 /// 마침표 구분 (독일/프랑스 등): 2.000.000
 String _formatDot(int n) {
 final str = n.toString();
 final buf = StringBuffer();
 for (var i = 0; i < str.length; i++) {
 if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
 buf.write(str[i]);
 }
 return buf.toString();
 }

 /// 인도식 구분: 20,00,000
 String _formatIndian(int n) {
 final str = n.toString();
 if (str.length <= 3) return str;
 final buf = StringBuffer();
 final last3 = str.substring(str.length - 3);
 final rest = str.substring(0, str.length - 3);
 for (var i = 0; i < rest.length; i++) {
 if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
 buf.write(rest[i]);
 }
 buf.write(',');
 buf.write(last3);
 return buf.toString();
 }

 String get infoWorkDays => _t({
 'ko': '근무요일',
 'en': 'Work days',
 'zh': '工作日',
 'hi': 'कार्य दिवस',
 'ja': '勤務日',
 'th': 'วันทำงาน',
 'vi': 'Ngày làm',
 'bn': 'কর্মদিবস',
 'ru': 'Рабочие дни',
 'id': 'Hari kerja',
 'ne': 'काम गर्ने दिन',
 'km': 'ថ្ងៃធ្វើការ',
 'my': 'အလုပ်လုပ်ရက်',
 'si': 'වැඩ දින',
 'uz': 'Ish kunlari',
 'mn': 'Ажлын өдөр',
 }, 'Work days');

 String get infoWorkTime => _t({
 'ko': '근무시간',
 'en': 'Work hours',
 'zh': '工作时间',
 'hi': 'कार्य समय',
 'ja': '勤務時間',
 'th': 'เวลาทำงาน',
 'vi': 'Giờ làm',
 'bn': 'কাজের সময়',
 'ru': 'Рабочие часы',
 'id': 'Jam kerja',
 'ne': 'काम गर्ने समय',
 'km': 'ម៉ោងធ្វើការ',
 'my': 'အလုပ်ချိန်',
 'si': 'වැඩ වේලාව',
 'uz': 'Ish soatlari',
 'mn': 'Ажлын цаг',
 }, 'Work hours');

 String get infoWorkModel => _t({
 'ko': '근무형태',
 'en': 'Work type',
 'zh': '工作方式',
 'hi': 'कार्य प्रकार',
 'ja': '勤務形態',
 'th': 'รูปแบบงาน',
 'vi': 'Hình thức',
 'bn': 'কাজের ধরন',
 'ru': 'Тип работы',
 'id': 'Jenis kerja',
 'ne': 'काम गर्ने तरिका',
 'km': 'ប្រភេទការងារ',
 'my': 'အလုပ်ပုံစံ',
 'si': 'වැඩ ආකාරය',
 'uz': 'Ish turi',
 'mn': 'Ажлын хэлбэр',
 }, 'Work type');

 String get infoEmployType => _t({
 'ko': '고용형태',
 'en': 'Employment',
 'zh': '雇佣形式',
 'hi': 'रोज़गार',
 'ja': '雇用形態',
 'th': 'ประเภทจ้างงาน',
 'vi': 'Loại hợp đồng',
 'bn': 'কর্মসংস্থান',
 'ru': 'Занятость',
 'id': 'Pekerjaan',
 'ne': 'रोजगार',
 'km': 'ការងារ',
 'my': 'အလုပ်ခန့်ထားမှု',
 'si': 'සේවා නියුක්තිය',
 'uz': 'Bandlik',
 'mn': 'Ажил эрхлэлт',
 }, 'Employment');

 String get infoJobType => _t({
 'ko': '직종',
 'en': 'Job type',
 'zh': '职种',
 'hi': 'नौकरी का प्रकार',
 'ja': '職種',
 'th': 'อาชีพ',
 'vi': 'Nghề',
 'bn': 'পেশার ধরন',
 'ru': 'Тип работы',
 'id': 'Jenis pekerjaan',
 'ne': 'जागिर प्रकार',
 'km': 'ប្រភេទការងារ',
 'my': 'အလုပ်အမျိုးအစား',
 'si': 'රැකියා වර්ගය',
 'uz': 'Ish turi',
 'mn': 'Ажлын төрөл',
 }, 'Job type');

 String get infoDeadline => _t({
 'ko': '마감일',
 'en': 'Deadline',
 'zh': '截止日期',
 'hi': 'अंतिम तिथि',
 'ja': '締切日',
 'th': 'วันหมดเขต',
 'vi': 'Hạn nộp',
 'bn': 'সময়সীমা',
 'ru': 'Срок',
 'id': 'Batas waktu',
 'ne': 'अन्तिम मिति',
 'km': 'ថ្ងៃផុតកំណត់',
 'my': 'နောက်ဆုံးရက်',
 'si': 'අවසන් දිනය',
 'uz': 'Oxirgi muddat',
 'mn': 'Эцсийн хугацаа',
 }, 'Deadline');

 String get infoWorkplace => _t({
 'ko': '근무지',
 'en': 'Workplace',
 'zh': '工作地点',
 'hi': 'कार्यस्थल',
 'ja': '勤務地',
 'th': 'สถานที่ทำงาน',
 'vi': 'Nơi làm việc',
 'bn': 'কর্মস্থল',
 'ru': 'Рабочее место',
 'id': 'Tempat kerja',
 'ne': 'कार्यस्थल',
 'km': 'កន្លែងធ្វើការ',
 'my': 'အလုပ်နေရာ',
 'si': 'සේවා ස්ථානය',
 'uz': 'Ish joyi',
 'mn': 'Ажлын байр',
 }, 'Workplace');

 String get translateToKorean => _t({
 'ko': '한글로 번역',
 'en': 'Translate to Korean',
 'zh': '翻译为韩语',
 'hi': 'कोरियन में अनुवाद',
 'ja': '韓国語に翻訳',
 'th': 'แปลเป็นเกาหลี',
 'vi': 'Dịch sang tiếng Hàn',
 'bn': 'কোরীয় ভাষায় অনুবাদ',
 'ru': 'Перевести на корейский',
 'id': 'Terjemahkan ke Korea',
 'ne': 'कोरियनमा अनुवाद',
 'km': 'បកប្រែជាភាសាកូរ៉េ',
 'my': 'ကိုရီးယားဘာသာသို့ ဘာသာပြန်',
 'si': 'කොරියානු භාෂාවට පරිවර්තනය',
 'uz': 'Koreychaga tarjima',
 'mn': 'Солонгос руу орчуулах',
 }, 'Translate to Korean');

 String get translateToEnglish => _t({
 'ko': '영어로 번역',
 'en': 'English',
 'zh': '英语',
 'hi': 'अंग्रेज़ी',
 'ja': '英語',
 'th': 'อังกฤษ',
 'vi': 'Tiếng Anh',
 'bn': 'ইংরেজি',
 'ru': 'Английский',
 'id': 'Inggris',
 'ne': 'अंग्रेजी',
 'km': 'អង់គ្លេស',
 'my': 'အင်္ဂလိပ်',
 'si': 'ඉංග්‍රීසි',
 'uz': 'Inglizcha',
 'mn': 'Англи',
 }, 'English');

 String get infoSource => _t({
 'ko': '공고 출처',
 'en': 'Source',
 'zh': '信息来源',
 'hi': 'स्रोत',
 'ja': '情報元',
 'th': 'แหล่งที่มา',
 'vi': 'Nguồn',
 'bn': 'উৎস',
 'ru': 'Источник',
 'id': 'Sumber',
 'ne': 'स्रोत',
 'km': 'ប្រភព',
 'my': 'ရင်းမြစ်',
 'si': 'මූලාශ්‍රය',
 'uz': 'Manba',
 'mn': 'Эх сурвалж',
 }, 'Source');

 /// 지원 WebView 로드 실패 화면
 String get pageLoadFailed => _t({
 'ko': '페이지를 열 수 없어요',
 'en': 'Couldn\'t open the page',
 'zh': '无法打开页面',
 'hi': 'पेज नहीं खुल सका',
 'ja': 'ページを開けません',
 'th': 'ไม่สามารถเปิดหน้านี้ได้',
 'vi': 'Không thể mở trang',
 'bn': 'পৃষ্ঠাটি খোলা যায়নি',
 'ru': 'Не удалось открыть страницу',
 'id': 'Tidak dapat membuka halaman',
 'ne': 'पृष्ठ खोल्न सकिएन',
 'km': 'មិនអាចបើកទំព័របានទេ',
 'my': 'စာမျက်နှာကို ဖွင့်၍မရပါ',
 'si': 'පිටුව විවෘත කළ නොහැක',
 'uz': 'Sahifani ochib bo\'lmadi',
 'mn': 'Хуудсыг нээж чадсангүй',
 }, 'Couldn\'t open the page');

 String get openInBrowser => _t({
 'ko': '외부 브라우저로 열기',
 'en': 'Open in browser',
 'zh': '在浏览器中打开',
 'hi': 'ब्राउज़र में खोलें',
 'ja': 'ブラウザで開く',
 'th': 'เปิดในเบราว์เซอร์',
 'vi': 'Mở trong trình duyệt',
 'bn': 'ব্রাউজারে খুলুন',
 'ru': 'Открыть в браузере',
 'id': 'Buka di browser',
 'ne': 'ब्राउजरमा खोल्नुहोस्',
 'km': 'បើកក្នុងកម្មវិធីរុករក',
 'my': 'ဘရောက်ဆာတွင် ဖွင့်ရန်',
 'si': 'බ්‍රවුසරයේ විවෘත කරන්න',
 'uz': 'Brauzerda ochish',
 'mn': 'Хөтөч дээр нээх',
 }, 'Open in browser');

 /// 상세 "비자지원" 행 값 (행 자체가 true일 때만 표시됨)
 String get visaSponsorshipYes => _t({
 'ko': '지원',
 'en': 'Yes',
 'zh': '支持',
 'hi': 'हाँ',
 'ja': '支援あり',
 'th': 'มี',
 'vi': 'Có',
 'bn': 'হ্যাঁ',
 'ru': 'Да',
 'id': 'Ya',
 'ne': 'छ',
 'km': 'មាន',
 'my': 'ရှိသည်',
 'si': 'ඔව්',
 'uz': 'Ha',
 'mn': 'Тийм',
 }, 'Yes');

 // ── 지원방법 (Apply methods) ──
 String get infoApplyMethod => _t({
 'ko': '지원방법',
 'en': 'How to apply',
 'zh': '申请方式',
 'hi': 'आवेदन का तरीका',
 'ja': '応募方法',
 'th': 'วิธีสมัคร',
 'vi': 'Cách ứng tuyển',
 'bn': 'আবেদনের পদ্ধতি',
 'ru': 'Способ подачи',
 'id': 'Cara melamar',
 'ne': 'आवेदन गर्ने तरिका',
 'km': 'របៀបដាក់ពាក្យ',
 'my': 'လျှောက်ထားနည်း',
 'si': 'අයදුම් කරන ආකාරය',
 'uz': 'Ariza berish usuli',
 'mn': 'Өргөдөл гаргах арга',
 }, 'How to apply');

 String get applyMethodOnline => _t({
 'ko': '온라인 지원',
 'en': 'Online',
 'zh': '在线申请',
 'hi': 'ऑनलाइन',
 'ja': 'オンライン応募',
 'th': 'ออนไลน์',
 'vi': 'Trực tuyến',
 'bn': 'অনলাইন',
 'ru': 'Онлайн',
 'id': 'Online',
 'ne': 'अनलाइन',
 'km': 'អនឡាញ',
 'my': 'အွန်လိုင်း',
 'si': 'මාර්ගගත',
 'uz': 'Onlayn',
 'mn': 'Онлайн',
 }, 'Online');

 String get applyMethodHomepage => _t({
 'ko': '홈페이지 지원',
 'en': 'Homepage',
 'zh': '官网申请',
 'hi': 'वेबसाइट',
 'ja': 'ホームページ',
 'th': 'เว็บไซต์',
 'vi': 'Trang web',
 'bn': 'ওয়েবসাইট',
 'ru': 'Сайт',
 'id': 'Situs web',
 'ne': 'वेबसाइट',
 'km': 'គេហទំព័រ',
 'my': 'ဝဘ်ဆိုက်',
 'si': 'වෙබ් අඩවිය',
 'uz': 'Veb-sayt',
 'mn': 'Вэбсайт',
 }, 'Homepage');

 String get applyMethodEmail => _t({
 'ko': '이메일 지원',
 'en': 'Email',
 'zh': '电子邮件',
 'hi': 'ईमेल',
 'ja': 'メール',
 'th': 'อีเมล',
 'vi': 'Email',
 'bn': 'ইমেইল',
 'ru': 'Эл. почта',
 'id': 'Email',
 'ne': 'इमेल',
 'km': 'អ៊ីមែល',
 'my': 'အီးမေးလ်',
 'si': 'ඊමේල්',
 'uz': 'Email',
 'mn': 'Имэйл',
 }, 'Email');

 String get applyMethodPhone => _t({
 'ko': '전화 지원',
 'en': 'Phone',
 'zh': '电话申请',
 'hi': 'फ़ोन',
 'ja': '電話',
 'th': 'โทรศัพท์',
 'vi': 'Điện thoại',
 'bn': 'ফোন',
 'ru': 'Телефон',
 'id': 'Telepon',
 'ne': 'फोन',
 'km': 'ទូរស័ព្ទ',
 'my': 'ဖုန်း',
 'si': 'දුරකථන',
 'uz': 'Telefon',
 'mn': 'Утас',
 }, 'Phone');

 String get applyMethodSms => _t({
 'ko': '문자 지원',
 'en': 'Text (SMS)',
 'zh': '短信申请',
 'hi': 'एसएमएस',
 'ja': 'SMS',
 'th': 'ข้อความ SMS',
 'vi': 'Tin nhắn SMS',
 'bn': 'এসএমএস',
 'ru': 'СМС',
 'id': 'SMS',
 'ne': 'एसएमएस',
 'km': 'សារ SMS',
 'my': 'SMS',
 'si': 'කෙටි පණිවිඩ',
 'uz': 'SMS',
 'mn': 'SMS',
 }, 'Text (SMS)');

 String get applyMethodSimple => _t({
 'ko': '간편 지원',
 'en': 'Easy apply',
 'zh': '快捷申请',
 'hi': 'आसान आवेदन',
 'ja': 'かんたん応募',
 'th': 'สมัครง่าย',
 'vi': 'Ứng tuyển nhanh',
 'bn': 'সহজ আবেদন',
 'ru': 'Быстрый отклик',
 'id': 'Lamar cepat',
 'ne': 'सजिलो आवेदन',
 'km': 'ដាក់ពាក្យរហ័ស',
 'my': 'လွယ်ကူစွာလျှောက်ရန်',
 'si': 'පහසු අයදුම්',
 'uz': 'Tez ariza',
 'mn': 'Хялбар өргөдөл',
 }, 'Easy apply');

 String get applyMethodChat => _t({
 'ko': '채팅 문의',
 'en': 'Chat',
 'zh': '聊天咨询',
 'hi': 'चैट',
 'ja': 'チャット',
 'th': 'แชท',
 'vi': 'Trò chuyện',
 'bn': 'চ্যাট',
 'ru': 'Чат',
 'id': 'Chat',
 'ne': 'च्याट',
 'km': 'ជជែក',
 'my': 'ချတ်',
 'si': 'කතාබහ',
 'uz': 'Chat',
 'mn': 'Чат',
 }, 'Chat');

 String get applyMethodVisit => _t({
 'ko': '방문 접수',
 'en': 'Visit',
 'zh': '现场应聘',
 'hi': 'व्यक्तिगत रूप से',
 'ja': '訪問受付',
 'th': 'สมัครด้วยตนเอง',
 'vi': 'Nộp trực tiếp',
 'bn': 'সরাসরি জমা',
 'ru': 'Лично',
 'id': 'Datang langsung',
 'ne': 'प्रत्यक्ष भेट',
 'km': 'មកដល់ផ្ទាល់',
 'my': 'ကိုယ်တိုင်လာရန်',
 'si': 'පැමිණ ඉදිරිපත්',
 'uz': 'Shaxsan',
 'mn': 'Биечлэн ирэх',
 }, 'Visit');

 String get applyMethodOther => _t({
 'ko': '기타(우편 등)',
 'en': 'Other',
 'zh': '其他',
 'hi': 'अन्य',
 'ja': 'その他',
 'th': 'อื่นๆ',
 'vi': 'Khác',
 'bn': 'অন্যান্য',
 'ru': 'Другое',
 'id': 'Lainnya',
 'ne': 'अन्य',
 'km': 'ផ្សេងៗ',
 'my': 'အခြား',
 'si': 'වෙනත්',
 'uz': 'Boshqa',
 'mn': 'Бусад',
 }, 'Other');

 // 정규화 코드 → 라벨. 미지 코드는 null(칩 생략).
 String? applyMethodLabel(String code) {
 switch (code) {
 case 'online': return applyMethodOnline;
 case 'homepage': return applyMethodHomepage;
 case 'email': return applyMethodEmail;
 case 'phone': return applyMethodPhone;
 case 'sms': return applyMethodSms;
 case 'simple': return applyMethodSimple;
 case 'chat': return applyMethodChat;
 case 'visit': return applyMethodVisit;
 case 'other': return applyMethodOther;
 default: return null;
 }
 }

 String get chooseSource => _t({
 'ko': '출처 선택',
 'en': 'Choose source',
 'zh': '选择来源',
 'hi': 'स्रोत चुनें',
 'ja': '情報元を選択',
 'th': 'เลือกแหล่งที่มา',
 'vi': 'Chọn nguồn',
 'bn': 'উৎস নির্বাচন করুন',
 'ru': 'Выберите источник',
 'id': 'Pilih sumber',
 'ne': 'स्रोत छान्नुहोस्',
 'km': 'ជ្រើសរើសប្រភព',
 'my': 'ရင်းမြစ်ရွေးချယ်ပါ',
 'si': 'මූලාශ්‍රය තෝරන්න',
 'uz': 'Manbani tanlang',
 'mn': 'Эх сурвалж сонгох',
 }, 'Choose source');

 String deadlineText(int dDay) => 'D-${dDay.abs()}';

 String get detailContent => _t({
 'ko': '상세 내용',
 'en': 'Details',
 'zh': '详细内容',
 'hi': 'विवरण',
 'ja': '詳細内容',
 'th': 'รายละเอียด',
 'vi': 'Chi tiết',
 'bn': 'বিবরণ',
 'ru': 'Подробности',
 'id': 'Detail',
 'ne': 'विवरण',
 'km': 'ព័ត៌មានលម្អិត',
 'my': 'အသေးစိတ်',
 'si': 'විස්තර',
 'uz': 'Tafsilotlar',
 'mn': 'Дэлгэрэнгүй',
 }, 'Details');

 String get disclaimer => _t({
 'ko': '본 공고는 외부 사이트에서 수집된 정보입니다.\n채용 관련 문의는 해당 사이트를 이용해 주세요.',
 'en': 'This information is collected from external sites.\nPlease contact the original site for inquiries.',
 'zh': '本信息来自外部网站。\n招聘相关咨询请联系原网站。',
 'hi': 'यह जानकारी बाहरी साइटों से एकत्रित है।\nपूछताछ के लिए कृपया मूल साइट से संपर्क करें।',
 'ja': 'この情報は外部サイトから収集されたものです。\n採用に関するお問い合わせは元のサイトをご利用ください。',
 'th': 'ข้อมูลนี้รวบรวมจากเว็บไซต์ภายนอก\nกรุณาติดต่อเว็บไซต์ต้นทาง',
 'vi': 'Thông tin này được thu thập từ trang web bên ngoài.\nVui lòng liên hệ trang web gốc để biết thêm.',
 'bn': 'এই তথ্য বাহ্যিক সাইট থেকে সংগৃহীত।\nজিজ্ঞাসার জন্য মূল সাইটে যোগাযোগ করুন।',
 'ru': 'Информация собрана с внешних сайтов.\nПо вопросам обращайтесь на оригинальный сайт.',
 'id': 'Informasi ini dikumpulkan dari situs eksternal.\nSilakan hubungi situs asli untuk pertanyaan.',
 'ne': 'यो जानकारी बाह्य साइटहरूबाट संकलित हो।\nसोधपुछको लागि मूल साइटमा सम्पर्क गर्नुहोस्।',
 'km': 'ព័ត៌មាននេះប្រមូលពីគេហទំព័រខាងក្រៅ។\nសូមទាក់ទងគេហទំព័រដើមសម្រាប់សំណួរ។',
 'my': 'ဤအချက်အလက်များကို ပြင်ပဝဘ်ဆိုက်များမှ စုဆောင်းထားသည်။\nစုံစမ်းမေးမြန်းရန် မူရင်းဆိုက်သို့ ဆက်သွယ်ပါ။',
 'si': 'මෙම තොරතුරු බාහිර වෙබ් අඩවි වලින් එකතු කර ඇත.\nවිමසීම් සඳහා මුල් වෙබ් අඩවිය අමතන්න.',
 'uz': 'Bu ma\'lumotlar tashqi saytlardan to\'plangan.\nSavollar uchun asl saytga murojaat qiling.',
 'mn': 'Энэ мэдээлэл гадны сайтаас цуглуулагдсан.\nЛавлагааны асуулт байвал эх сайтруу хандана уу.',
 }, 'This information is collected from external sites.\nPlease contact the original site for inquiries.');

 String get apply => _t({
 'ko': '지원하러 가기',
 'en': 'Move to Apply',
 'zh': '前往申请',
 'hi': 'आवेदन पर जाएं',
 'ja': '応募ページへ',
 'th': 'ไปสมัครงาน',
 'vi': 'Đến trang ứng tuyển',
 'bn': 'আবেদনে যান',
 'ru': 'Перейти к заявке',
 'id': 'Menuju Lamaran',
 'ne': 'आवेदनमा जानुहोस्',
 'km': 'ទៅដាក់ពាក្យ',
 'my': 'လျှောက်ထားရန် သွားပါ',
 'si': 'අයදුම් කිරීමට යන්න',
 'uz': 'Arizaga o\'tish',
 'mn': 'Өргөдөл рүү очих',
 }, 'Move to Apply');

 // ── 회사명 비공개 (company NULL) ──
 String get companyUndisclosed => _t({
 'ko': '비공개',
 'en': 'Undisclosed',
 'zh': '未公开',
 'hi': 'गोपनीय',
 'ja': '非公開',
 'th': 'ไม่เปิดเผย',
 'vi': 'Không tiết lộ',
 'bn': 'অপ্রকাশিত',
 'ru': 'Не указано',
 'id': 'Tidak diungkap',
 'ne': 'सार्वजनिक छैन',
 'km': 'មិនបង្ហាញ',
 'my': 'မဖော်ပြထား',
 'si': 'හෙළි නොකළ',
 'uz': 'Oshkor etilmagan',
 'mn': 'Нээлттэй бус',
 }, 'Undisclosed');

 // ── 닫기 (WebView 등) ──
 String get close => _t({
 'ko': '닫기',
 'en': 'Close',
 'zh': '关闭',
 'hi': 'बंद करें',
 'ja': '閉じる',
 'th': 'ปิด',
 'vi': 'Đóng',
 'bn': 'বন্ধ করুন',
 'ru': 'Закрыть',
 'id': 'Tutup',
 'ne': 'बन्द गर्नुहोस्',
 'km': 'បិទ',
 'my': 'ပိတ်ရန်',
 'si': 'වසන්න',
 'uz': 'Yopish',
 'mn': 'Хаах',
 }, 'Close');

 // ── 상시채용 ──
 String get alwaysOpen => _t({
 'ko': '상시',
 'en': 'Open',
 'zh': '长期',
 'hi': 'हमेशा खुला',
 'ja': '常時',
 'th': 'ตลอดเวลา',
 'vi': 'Thường xuyên',
 'bn': 'সর্বদা',
 'ru': 'Постоянно',
 'id': 'Selalu buka',
 'ne': 'सधैं खुला',
 'km': 'បើកជានិច្ច',
 'my': 'အမြဲဖွင့်',
 'si': 'විවෘත කරන්න',
 'uz': 'Doim ochiq',
 'mn': 'Байнга нээлттэй',
 }, 'Open');

 String get expired => _t({
       'ko': '마감',
       'en': 'Closed',
       'zh': '已截止',
       'hi': 'समाप्त',
       'ja': '締切',
       'th': 'ปิดรับ',
       'vi': 'Đã hết hạn',
       'bn': 'মেয়াদ শেষ',
       'ru': 'Закрыто',
       'id': 'Ditutup',
       'ne': 'बन्द',
       'km': 'បិទ',
       'my': 'ပိတ်ပြီး',
       'si': 'වසා ඇත',
       'uz': 'Yopiq',
       'mn': 'Хаалттай',
     }, 'Closed');

 // ── Favorites ──
 String get favorites => _t({
 'ko': '즐겨찾기',
 'en': 'Favorites',
 'zh': '收藏',
 'hi': 'पसंदीदा',
 'ja': 'お気に入り',
 'th': 'รายการโปรด',
 'vi': 'Yêu thích',
 'bn': 'পছন্দ',
 'ru': 'Избранное',
 'id': 'Favorit',
 'ne': 'मनपर्ने',
 'km': 'ចំណូលចិត្ត',
 'my': 'အကြိုက်ဆုံး',
 'si': 'ප්‍රියතම',
 'uz': 'Sevimlilar',
 'mn': 'Дуртай',
 }, 'Favorites');

 String get sortByDeadline => _t({
 'ko': '마감일순',
 'en': 'By deadline',
 'zh': '截止日期',
 'hi': 'अंतिम तिथि अनुसार',
 'ja': '締切順',
 'th': 'วันหมดเขต',
 'vi': 'Hạn nộp',
 'bn': 'সময়সীমা অনুসারে',
 'ru': 'По сроку',
 'id': 'Berdasarkan batas waktu',
 'ne': 'अन्तिम मिति अनुसार',
 'km': 'តាមថ្ងៃផុតកំណត់',
 'my': 'နောက်ဆုံးရက်အလိုက်',
 'si': 'අවසන් දිනය අනුව',
 'uz': 'Muddati bo\'yicha',
 'mn': 'Хугацаагаар',
 }, 'By deadline');

 String get sortByAdded => _t({
 'ko': '등록순',
 'en': 'By added',
 'zh': '添加时间',
 'hi': 'जोड़े गए अनुसार',
 'ja': '登録順',
 'th': 'วันที่เพิ่ม',
 'vi': 'Ngày thêm',
 'bn': 'যোগ করার ক্রমে',
 'ru': 'По добавлению',
 'id': 'Berdasarkan penambahan',
 'ne': 'थपिएको अनुसार',
 'km': 'តាមការបន្ថែម',
 'my': 'ထည့်သွင်းသည့်အလိုက်',
 'si': 'එකතු කළ අනුව',
 'uz': 'Qo\'shilgan vaqti bo\'yicha',
 'mn': 'Нэмсэн дарааллаар',
 }, 'By added');

 String get edit => _t({
 'ko': '편집',
 'en': 'Edit',
 'zh': '编辑',
 'hi': 'संपादित करें',
 'ja': '編集',
 'th': 'แก้ไข',
 'vi': 'Chỉnh sửa',
 'bn': 'সম্পাদনা',
 'ru': 'Редактировать',
 'id': 'Edit',
 'ne': 'सम्पादन',
 'km': 'កែសម្រួល',
 'my': 'တည်းဖြတ်ပါ',
 'si': 'සංස්කරණය',
 'uz': 'Tahrirlash',
 'mn': 'Засварлах',
 }, 'Edit');

 String get delete => _t({
 'ko': '삭제',
 'en': 'Delete',
 'zh': '删除',
 'hi': 'हटाएं',
 'ja': '削除',
 'th': 'ลบ',
 'vi': 'Xóa',
 'bn': 'মুছুন',
 'ru': 'Удалить',
 'id': 'Hapus',
 'ne': 'हटाउनुहोस्',
 'km': 'លុប',
 'my': 'ဖျက်ပါ',
 'si': 'මකන්න',
 'uz': 'O\'chirish',
 'mn': 'Устгах',
 }, 'Delete');

 String get done => _t({
 'ko': '완료',
 'en': 'Done',
 'zh': '完成',
 'hi': 'हो गया',
 'ja': '完了',
 'th': 'เสร็จ',
 'vi': 'Xong',
 'bn': 'সম্পন্ন',
 'ru': 'Готово',
 'id': 'Selesai',
 'ne': 'सम्पन्न',
 'km': 'រួចរាល់',
 'my': 'ပြီးပါပြီ',
 'si': 'සම්පූර්ණයි',
 'uz': 'Tayyor',
 'mn': 'Дууссан',
 }, 'Done');

 String get noFavorites => _t({
 'ko': '즐겨찾기가 없습니다',
 'en': 'No favorites yet',
 'zh': '没有收藏',
 'hi': 'अभी कोई पसंदीदा नहीं',
 'ja': 'お気に入りはありません',
 'th': 'ไม่มีรายการโปรด',
 'vi': 'Không có yêu thích',
 'bn': 'এখনও কোনো পছন্দ নেই',
 'ru': 'Пока нет избранного',
 'id': 'Belum ada favorit',
 'ne': 'अहिलेसम्म मनपर्ने छैन',
 'km': 'មិនទាន់មានចំណូលចិត្តទេ',
 'my': 'အကြိုက်ဆုံးများ မရှိသေးပါ',
 'si': 'තවම ප්‍රියතම නැත',
 'uz': 'Hali sevimlilar yo\'q',
 'mn': 'Дуртай зар алга',
 }, 'No favorites yet');

 String get noFavoritesHint => _t({
       'ko': '공고에서 하트를 눌러 추가하세요',
       'en': 'Tap the heart on a job to add',
       'zh': '点击职位上的心形图标添加',
       'hi': 'जोड़ने के लिए हार्ट दबाएं',
       'ja': '求人のハートをタップして追加',
       'th': 'แตะหัวใจบนงานเพื่อเพิ่ม',
       'vi': 'Nhấn trái tim trên việc làm để thêm',
       'bn': 'যোগ করতে হার্ট চাপুন',
       'ru': 'Нажмите сердечко на вакансии',
       'id': 'Ketuk hati pada lowongan untuk menambahkan',
       'ne': 'थप्न हार्ट थिच्नुहोस्',
       'km': 'ចុចបេះដូងលើការងារដើម្បីបន្ថែម',
       'my': 'ထည့်ရန် နှလုံးသား ကိုနှိပ်ပါ',
       'si': 'එකතු කිරීමට හදවත ඔබන්න',
       'uz': 'Qo\'shish uchun yurakni bosing',
       'mn': 'Нэмэхийн тулд зүрхийг дарна уу',
     }, 'Tap the heart on a job to add');


 String get sortBy => _t({
 'ko': '정렬',
 'en': 'Sort by',
 'zh': '排序',
 'hi': 'क्रमबद्ध करें',
 'ja': '並び替え',
 'th': 'เรียงตาม',
 'vi': 'Sắp xếp',
 'bn': 'সাজানো',
 'ru': 'Сортировка',
 'id': 'Urutkan',
 'ne': 'क्रमबद्ध गर्नुहोस्',
 'km': 'តម្រៀបតាម',
 'my': 'စီရန်',
 'si': 'අනුව තෝරන්න',
 'uz': 'Saralash',
 'mn': 'Эрэмбэлэх',
 }, 'Sort by');

 // ── New Language Notification ──
 String get newLanguageTitle => _t({
       'ko': '새로운 언어가 추가되었어요!',
       'en': 'New language available!',
       'zh': '新增语言支持！',
       'hi': 'नई भाषा उपलब्ध!',
       'ja': '新しい言語が追加されました！',
       'th': 'มีภาษาใหม่เพิ่มแล้ว!',
       'vi': 'Có ngôn ngữ mới!',
       'bn': 'নতুন ভাষা যোগ হয়েছে!',
       'ru': 'Добавлен новый язык!',
       'id': 'Bahasa baru tersedia!',
       'ne': 'नयाँ भाषा उपलब्ध!',
       'km': 'មានភាសាថ្មី!',
       'my': 'ဘာသာစကားအသစ်ရရှိနိုင်ပါပြီ!',
       'si': 'නව භාෂාවක් ලැබේ!',
       'uz': 'Yangi til qo\'shildi!',
       'mn': 'Шинэ хэл нэмэгдлээ!',
     }, 'New language available!');

 String newLanguageBody(String langName) => _t({
       'ko': '$langName 이(가) 추가되었습니다.\n지금 변경하시겠습니까?',
       'en': '$langName has been added.\nWould you like to switch?',
       'zh': '已添加$langName。\n是否切换？',
       'hi': '$langName जोड़ा गया।\nक्या आप बदलना चाहेंगे?',
       'ja': '$langNameが追加されました。\n切り替えますか？',
       'th': 'เพิ่ม$langNameแล้ว\nต้องการเปลี่ยนไหม?',
       'vi': 'Đã thêm $langName.\nBạn muốn chuyển không?',
       'bn': '$langName যোগ হয়েছে।\nপরিবর্তন করবেন?',
       'ru': 'Добавлен $langName.\nХотите переключиться?',
       'id': '$langName telah ditambahkan.\nIngin beralih?',
       'ne': '$langName थपिएको छ।\nपरिवर्तन गर्नुहुन्छ?',
       'km': '$langName ត្រូវបានបន្ថែម។\nចង់ប្ដូរទេ?',
       'my': '$langName ထည့်ပြီးပါပြီ။\nပြောင်းလဲလိုပါသလား?',
       'si': '$langName එක් කරන ලදී.\nමාරු කරන්නද?',
       'uz': '$langName qo\'shildi.\nO\'zgartirmoqchimisiz?',
       'mn': '$langName нэмэгдлээ.\nСолих уу?',
     }, '$langName has been added.\nWould you like to switch?');

 String get switchLanguage => _t({
       'ko': '변경하기',
       'en': 'Switch',
       'zh': '切换',
       'hi': 'बदलें',
       'ja': '切り替え',
       'th': 'เปลี่ยน',
       'vi': 'Chuyển',
       'bn': 'পরিবর্তন',
       'ru': 'Переключить',
       'id': 'Beralih',
       'ne': 'परिवर्तन',
       'km': 'ប្ដូរ',
       'my': 'ပြောင်းမည်',
       'si': 'මාරු කරන්න',
       'uz': 'O\'zgartirish',
       'mn': 'Солих',
     }, 'Switch');

 String get maybeLater => _t({
       'ko': '나중에',
       'en': 'Maybe later',
       'zh': '以后再说',
       'hi': 'बाद में',
       'ja': 'あとで',
       'th': 'ไว้ทีหลัง',
       'vi': 'Để sau',
       'bn': 'পরে',
       'ru': 'Позже',
       'id': 'Nanti saja',
       'ne': 'पछि',
       'km': 'ពេលក្រោយ',
       'my': 'နောက်မှ',
       'si': 'පසුව',
       'uz': 'Keyinroq',
       'mn': 'Дараа',
     }, 'Maybe later');

 // ── Network / Error ──
 String get noInternet => _t({
       'ko': '인터넷 연결을 확인해주세요',
       'en': 'Please check your internet connection',
       'zh': '请检查网络连接',
       'hi': 'कृपया अपना इंटरनेट कनेक्शन जांचें',
       'ja': 'インターネット接続を確認してください',
       'th': 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
       'vi': 'Vui lòng kiểm tra kết nối internet',
       'bn': 'আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন',
       'ru': 'Проверьте подключение к интернету',
       'id': 'Periksa koneksi internet Anda',
       'ne': 'इन्टरनेट जडान जाँच गर्नुहोस्',
       'km': 'សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត',
       'my': 'အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပါ',
       'si': 'කරුණාකර අන්තර්ජාල සම්බන්ධතාවය පරීක්ෂා කරන්න',
       'uz': 'Internet ulanishini tekshiring',
       'mn': 'Интернет холболтоо шалгана уу',
     }, 'Please check your internet connection');

 String get retry => _t({
       'ko': '다시 시도',
       'en': 'Retry',
       'zh': '重试',
       'hi': 'पुनः प्रयास',
       'ja': '再試行',
       'th': 'ลองอีกครั้ง',
       'vi': 'Thử lại',
       'bn': 'পুনরায় চেষ্টা',
       'ru': 'Повторить',
       'id': 'Coba lagi',
       'ne': 'पुन: प्रयास',
       'km': 'ព្យាយាមម្តងទៀត',
       'my': 'ထပ်စမ်းပါ',
       'si': 'නැවත උත්සාහ කරන්න',
       'uz': 'Qayta urinish',
       'mn': 'Дахин оролдох',
     }, 'Retry');

 String get somethingWentWrong => _t({
       'ko': '문제가 발생했습니다',
       'en': 'Something went wrong',
       'zh': '出了点问题',
       'hi': 'कुछ गलत हो गया',
       'ja': 'エラーが発生しました',
       'th': 'เกิดข้อผิดพลาด',
       'vi': 'Đã xảy ra lỗi',
       'bn': 'কিছু ভুল হয়েছে',
       'ru': 'Что-то пошло не так',
       'id': 'Terjadi kesalahan',
       'ne': 'केही गलत भयो',
       'km': 'មានបញ្ហាកើតឡើង',
       'my': 'တစ်ခုခုမှားယွင်းနေသည်',
       'si': 'යමක් වැරදී ඇත',
       'uz': 'Xatolik yuz berdi',
       'mn': 'Алдаа гарлаа',
     }, 'Something went wrong');

 // ── Description Translation ──
 String get translateDescription => _t({
       'ko': '번역하기',
       'en': 'Translate',
       'zh': '翻译',
       'zh-yue': '翻譯',
       'hi': 'अनुवाद करें',
       'ja': '翻訳する',
       'th': 'แปล',
       'vi': 'Dịch',
       'bn': 'অনুবাদ করুন',
       'ru': 'Перевести',
       'id': 'Terjemahkan',
       'fr': 'Traduire',
       'de': 'Übersetzen',
       'it': 'Traduci',
       'es': 'Traducir',
       'pt': 'Traduzir',
       'pl': 'Przetłumacz',
       'ar': 'ترجمة',
       'tr': 'Çevir',
       'he': 'תרגם',
       'ms': 'Terjemah',
       'ne': 'अनुवाद गर्नुहोस्',
       'km': 'បកប្រែ',
       'my': 'ဘာသာပြန်ပါ',
       'uz': 'Tarjima qilish',
       'mn': 'Орчуулах',
       'kk': 'Аудару',
   'si': 'පරිවර්තනය',
 }, 'Translate');

 String get showOriginal => _t({
       'ko': '원문 보기',
       'en': 'Show original',
       'zh': '查看原文',
       'zh-yue': '睇原文',
       'hi': 'मूल देखें',
       'ja': '原文を見る',
       'th': 'ดูต้นฉบับ',
       'vi': 'Xem bản gốc',
       'bn': 'মূল দেখুন',
       'ru': 'Показать оригинал',
       'id': 'Lihat asli',
       'fr': 'Voir l\'original',
       'de': 'Original anzeigen',
       'it': 'Mostra originale',
       'es': 'Ver original',
       'pt': 'Ver original',
       'pl': 'Pokaż oryginał',
       'ar': 'عرض الأصل',
       'tr': 'Orijinali göster',
       'he': 'הצג מקור',
       'ms': 'Lihat asal',
       'ne': 'मूल हेर्नुहोस्',
       'km': 'មើលអត្ថបទដើម',
       'my': 'မူရင်းကြည့်ပါ',
       'uz': 'Asl nusxani ko\'rish',
       'mn': 'Эх бичвэрийг харах',
       'kk': 'Түпнұсқаны көру',
   'si': 'මුල් පිටපත පෙන්වන්න',
 }, 'Show original');

 String get translationFailed => _t({
       'ko': '번역 실패',
       'en': 'Translation failed',
       'zh': '翻译失败',
       'zh-yue': '翻譯失敗',
       'hi': 'अनुवाद विफल',
       'ja': '翻訳に失敗しました',
       'th': 'แปลไม่สำเร็จ',
       'vi': 'Dịch thất bại',
       'bn': 'অনুবাদ ব্যর্থ',
       'ru': 'Ошибка перевода',
       'id': 'Terjemahan gagal',
       'fr': 'Échec de la traduction',
       'de': 'Übersetzung fehlgeschlagen',
       'it': 'Traduzione fallita',
       'es': 'Error de traducción',
       'pt': 'Falha na tradução',
       'pl': 'Tłumaczenie nie powiodło się',
       'ar': 'فشل الترجمة',
       'tr': 'Çeviri başarısız',
       'he': 'התרגום נכשל',
       'ms': 'Terjemahan gagal',
       'ne': 'अनुवाद असफल',
       'km': 'ការបកប្រែបរាជ័យ',
       'my': 'ဘာသာပြန်မအောင်မြင်ပါ',
       'uz': 'Tarjima amalga oshmadi',
       'mn': 'Орчуулга амжилтгүй',
       'kk': 'Аударма сәтсіз',
   'si': 'පරිවර්තනය අසාර්ථකයි',
 }, 'Translation failed');

 // ── Location ──
 String get locationDeniedMessage => _t({
       'ko': '위치 권한 없이도 사용할 수 있어요\n필터에서 지역을 직접 선택할 수 있습니다',
       'en': 'You can use the app without location\nSelect a region in the filter instead',
       'zh': '不使用定位也可以使用\n可以在筛选中直接选择地区',
       'hi': 'स्थान के बिना भी उपयोग कर सकते हैं\nफ़िल्टर में क्षेत्र चुनें',
       'ja': '位置情報なしでも利用できます\nフィルターで地域を選択できます',
       'th': 'ใช้งานได้โดยไม่ต้องเปิดตำแหน่ง\nเลือกภูมิภาคในตัวกรองแทน',
       'vi': 'Có thể dùng mà không cần vị trí\nChọn khu vực trong bộ lọc',
       'bn': 'অবস্থান ছাড়াও ব্যবহার করতে পারবেন\nফিল্টারে এলাকা নির্বাচন করুন',
       'ru': 'Можно использовать без геолокации\nВыберите регион в фильтре',
       'id': 'Bisa digunakan tanpa lokasi\nPilih wilayah di filter',
       'ne': 'स्थान बिना पनि प्रयोग गर्न सकिन्छ\nफिल्टरमा क्षेत्र छान्नुहोस्',
       'km': 'អាចប្រើដោយមិនចាំបាច់ទីតាំង\nជ្រើសរើសតំបន់នៅក្នុងតម្រង',
       'my': 'တည်နေရာမလိုဘဲ သုံးနိုင်ပါသည်\nစစ်ထုတ်မှုတွင် ဒေသရွေးချယ်ပါ',
       'si': 'ස්ථානය නැතිවත් භාවිතා කළ හැක\nපෙරහනෙහි ප්‍රදේශය තෝරන්න',
       'uz': 'Joylashuvsiz ham foydalanish mumkin\nFilterda hududni tanlang',
       'mn': 'Байршилгүйгээр ашиглах боломжтой\nШүүлтүүрт бүсийг сонгоно уу',
     }, 'You can use the app without location\nSelect a region in the filter instead');

 String get confirm => _t({
       'ko': '확인',
       'en': 'OK',
       'zh': '确认',
       'hi': 'ठीक है',
       'ja': '確認',
       'th': 'ตกลง',
       'vi': 'Xác nhận',
       'bn': 'ঠিক আছে',
       'ru': 'ОК',
       'id': 'OK',
       'ne': 'ठीक छ',
       'km': 'យល់ព្រម',
       'my': 'အိုကေ',
       'si': 'හරි',
       'uz': 'OK',
       'mn': 'Тийм',
     }, 'OK');

 String get useCurrentLocation => _t({
       'ko': '현재 위치로 설정',
       'en': 'Use current location',
       'zh': '使用当前位置',
       'hi': 'वर्तमान स्थान उपयोग करें',
       'ja': '現在地を使用',
       'th': 'ใช้ตำแหน่งปัจจุบัน',
       'vi': 'Dùng vị trí hiện tại',
       'bn': 'বর্তমান অবস্থান ব্যবহার করুন',
       'ru': 'Использовать текущее местоположение',
       'id': 'Gunakan lokasi saat ini',
       'ne': 'हालको स्थान प्रयोग गर्नुहोस्',
       'km': 'ប្រើទីតាំងបច្ចុប្បន្ន',
       'my': 'လက်ရှိတည်နေရာ သုံးမည်',
       'si': 'වත්මන් ස්ථානය භාවිතා කරන්න',
       'uz': 'Joriy joylashuvdan foydalanish',
       'mn': 'Одоогийн байршлыг ашиглах',
     }, 'Use current location');

 // ── Fixed DB item translations ──

 String translateEmploymentType(String nameEn) => switch (nameEn) {
   'Full-time' => _t({
     'ko': '정규직', 'en': 'Full-time', 'zh': '全职', 'vi': 'Toàn thời gian',
     'th': 'เต็มเวลา', 'uz': 'To\'liq stavka', 'km': 'ពេញម៉ោង',
     'my': 'အချိန်ပြည့်', 'mn': 'Бүтэн цагийн', 'ja': '正社員',
     'si': 'සම්පූර්ණ කාලීන', 'bn': 'পূর্ণকালীন', 'ru': 'Полная занятость',
     'hi': 'पूर्णकालिक',
   'ne': 'पूर्णकालीन', 'id': 'Penuh waktu',
 }, 'Full-time'),
   'Part-time' => _t({
     'ko': '아르바이트', 'en': 'Part-time', 'zh': '兼职', 'vi': 'Bán thời gian',
     'th': 'พาร์ทไทม์', 'uz': 'Yarim stavka', 'km': 'ក្រៅម៉ោង',
     'my': 'အချိန်ပိုင်း', 'mn': 'Хагас цагийн', 'ja': 'アルバイト',
     'si': 'අර්ධ කාලීන', 'bn': 'খণ্ডকালীন', 'ru': 'Подработка',
     'hi': 'अंशकालिक',
   'ne': 'अंशकालीन', 'id': 'Paruh waktu',
 }, 'Part-time'),
   'Contract' => _t({
     'ko': '계약직', 'en': 'Contract', 'zh': '合同工', 'vi': 'Hợp đồng',
     'th': 'สัญญาจ้าง', 'uz': 'Shartnoma', 'km': 'កិច្ចសន្យា',
     'my': 'စာချုပ်', 'mn': 'Гэрээт', 'ja': '契約社員',
     'si': 'ගිවිසුම්', 'bn': 'চুক্তিভিত্তিক', 'ru': 'Контракт',
     'hi': 'अनुबंध',
   'ne': 'करार', 'id': 'Kontrak',
 }, 'Contract'),
   'Daily Worker' => _t({
     'ko': '일용직', 'en': 'Daily Worker', 'zh': '日工', 'vi': 'Công nhật',
     'th': 'รายวัน', 'uz': 'Kunlik ishchi', 'km': 'កម្មករប្រចាំថ្ងៃ',
     'my': 'နေ့စားအလုပ်သမား', 'mn': 'Өдрийн ажилтан', 'ja': '日雇い',
     'si': 'දෛනික සේවක', 'bn': 'দৈনিক শ্রমিক', 'ru': 'Подённый рабочий',
     'hi': 'दिहाड़ी मज़दूर',
   'ne': 'दैनिक ज्यालादारी', 'id': 'Pekerja harian',
 }, 'Daily Worker'),
   'Intern' => _t({
     'ko': '인턴', 'en': 'Intern', 'zh': '实习生', 'vi': 'Thực tập sinh',
     'th': 'ฝึกงาน', 'uz': 'Stajer', 'km': 'កម្មសិក្សា',
     'my': 'အလုပ်သင်', 'mn': 'Дадлагажигч', 'ja': 'インターン',
     'si': 'පුහුණුකරු', 'bn': 'ইন্টার্ন', 'ru': 'Стажёр',
     'hi': 'इंटर्न',
   'ne': 'इन्टर्न', 'id': 'Magang',
 }, 'Intern'),
   'Dispatch' => _t({
     'ko': '파견직', 'en': 'Dispatch', 'zh': '派遣工', 'vi': 'Phái cử',
     'th': 'จัดส่งแรงงาน', 'uz': 'Yuborilgan ishchi', 'km': 'បញ្ជូន',
     'my': 'စေလွှတ်အလုပ်သမား', 'mn': 'Түр томилгоот', 'ja': '派遣社員',
     'si': 'යවන ලද සේවක', 'bn': 'প্রেরিত কর্মী', 'ru': 'Аутсорсинг',
     'hi': 'प्रतिनियुक्त',
   'ne': 'एजेन्सी कामदार', 'id': 'Pekerja agensi',
 }, 'Dispatch'),
   'Freelancer' => _t({
     'ko': '프리랜서', 'en': 'Freelancer', 'zh': '自由职业者', 'vi': 'Freelancer',
     'th': 'ฟรีแลนซ์', 'uz': 'Frilanser', 'km': 'ឯករាជ្យ',
     'my': 'လွတ်လပ်အလုပ်သမား', 'mn': 'Чөлөөт ажилтан', 'ja': 'フリーランス',
     'si': 'නිදහස් සේවක', 'bn': 'ফ্রিল্যান্সার', 'ru': 'Фрилансер',
     'hi': 'फ्रीलांसर',
   'ne': 'फ्रिल्यान्सर', 'id': 'Pekerja lepas',
 }, 'Freelancer'),
   'Negotiable' => _t({
     'ko': '협의', 'en': 'Negotiable', 'zh': '面议', 'vi': 'Thương lượng',
     'th': 'ตามตกลง', 'uz': 'Kelishiladi', 'km': 'ចរចា',
     'my': 'ညှိနှိုင်း', 'mn': 'Тохиролцоно', 'ja': '応相談',
     'si': 'සාකච්ඡා කළ හැකි', 'bn': 'আলোচনাসাপেক্ষ', 'ru': 'По договорённости',
     'hi': 'बातचीत योग्य',
   'ne': 'सहमतिमा', 'id': 'Bisa dinegosiasikan',
 }, 'Negotiable'),
   _ => nameEn,
 };

 String translateJobCategory(String nameEn) => switch (nameEn) {
   'IT & Development' => _t({
     'ko': 'IT·개발', 'en': 'IT & Development', 'zh': 'IT·开发', 'vi': 'CNTT & Phát triển',
     'th': 'ไอที & พัฒนา', 'uz': 'IT & Dasturlash', 'km': 'ព័ត៌មានវិទ្យា និងអភិវឌ្ឍន៍',
     'my': 'IT နှင့် ဖွံ့ဖြိုးရေး', 'mn': 'IT & Хөгжүүлэлт', 'ja': 'IT・開発',
     'si': 'IT සහ සංවර්ධන', 'bn': 'আইটি ও উন্নয়ন', 'ru': 'IT и разработка',
     'hi': 'आईटी और विकास',
   'ne': 'आईटी तथा विकास', 'id': 'IT & Pengembangan',
 }, 'IT & Development'),
   'Construction' => _t({
     'ko': '건설·현장', 'en': 'Construction', 'zh': '建筑·工地', 'vi': 'Xây dựng',
     'th': 'ก่อสร้าง', 'uz': 'Qurilish', 'km': 'សំណង់',
     'my': 'ဆောက်လုပ်ရေး', 'mn': 'Барилга', 'ja': '建設・現場',
     'si': 'ඉදිකිරීම්', 'bn': 'নির্মাণ', 'ru': 'Строительство',
     'hi': 'निर्माण',
   'ne': 'निर्माण', 'id': 'Konstruksi',
 }, 'Construction'),
   'Education' => _t({
     'ko': '교육', 'en': 'Education', 'zh': '教育', 'vi': 'Giáo dục',
     'th': 'การศึกษา', 'uz': 'Ta\'lim', 'km': 'អប់រំ',
     'my': 'ပညာရေး', 'mn': 'Боловсрол', 'ja': '教育',
     'si': 'අධ්‍යාපනය', 'bn': 'শিক্ষা', 'ru': 'Образование',
     'hi': 'शिक्षा',
   'ne': 'शिक्षा', 'id': 'Pendidikan',
 }, 'Education'),
   'Agriculture, Forestry & Fishing' => _t({
     'ko': '농림수산', 'en': 'Agriculture, Forestry & Fishing', 'zh': '农林渔业', 'vi': 'Nông lâm ngư nghiệp',
     'th': 'เกษตร ป่าไม้ และประมง', 'uz': 'Qishloq, o\'rmon va baliqchilik', 'km': 'កសិកម្ម វនសាស្ត្រ និងនេសាទ',
     'ne': 'कृषि, वन र मत्स्य', 'id': 'Pertanian, Kehutanan & Perikanan',
     'my': 'စိုက်ပျိုးရေး သစ်တောနှင့် ငါးဖမ်း', 'mn': 'Хөдөө аж ахуй, ойн аж ахуй, загасчлал', 'ja': '農林水産',
     'si': 'කෘෂිකර්ම, වනවිද්‍යා සහ ධීවර', 'bn': 'কৃষি, বনায়ন ও মৎস্য', 'ru': 'Сельское, лесное и рыбное хозяйство',
     'hi': 'कृषि, वानिकी और मत्स्य',
   }, 'Agriculture, Forestry & Fishing'),
   'Logistics' => _t({
     'ko': '물류·운반', 'en': 'Logistics', 'zh': '物流·搬运', 'vi': 'Vận chuyển & Kho vận',
     'th': 'โลจิสติกส์', 'uz': 'Logistika', 'km': 'ដឹកជញ្ជូន',
     'my': 'ထောက်ပံ့ပို့ဆောင်ရေး', 'mn': 'Логистик', 'ja': '物流・運搬',
     'si': 'සැපයුම් දාම', 'bn': 'লজিস্টিক', 'ru': 'Логистика',
     'hi': 'रसद',
   'ne': 'लजिस्टिक्स', 'id': 'Logistik',
 }, 'Logistics'),
   'Office & Admin' => _t({
     'ko': '사무·행정', 'en': 'Office & Admin', 'zh': '办公·行政', 'vi': 'Văn phòng & Hành chính',
     'th': 'สำนักงาน & ธุรการ', 'uz': 'Ofis va ma\'muriyat', 'km': 'ការិយាល័យ និងរដ្ឋបាល',
     'my': 'ရုံးနှင့် စီမံရေး', 'mn': 'Оффис & Удирдлага', 'ja': '事務・管理',
     'si': 'කාර්යාලය සහ පරිපාලන', 'bn': 'অফিস ও প্রশাসন', 'ru': 'Офис и администрирование',
     'hi': 'कार्यालय और प्रशासन',
   'ne': 'कार्यालय तथा प्रशासन', 'id': 'Kantor & Administrasi',
 }, 'Office & Admin'),
   'Service & Sales' => _t({
     'ko': '서비스·판매', 'en': 'Service & Sales', 'zh': '服务·销售', 'vi': 'Dịch vụ & Bán hàng',
     'th': 'บริการ & การขาย', 'uz': 'Xizmat va savdo', 'km': 'សេវាកម្ម និងការលក់',
     'my': 'ဝန်ဆောင်မှုနှင့် အရောင်း', 'mn': 'Үйлчилгээ & Борлуулалт', 'ja': 'サービス・販売',
     'si': 'සේවා සහ විකුණුම්', 'bn': 'সেবা ও বিক্রয়', 'ru': 'Сервис и продажи',
     'hi': 'सेवा और बिक्री',
   'ne': 'सेवा तथा बिक्री', 'id': 'Layanan & Penjualan',
 }, 'Service & Sales'),
   'Food & Cooking' => _t({
     'ko': '음식·조리', 'en': 'Food & Cooking', 'zh': '餐饮·烹饪', 'vi': 'Ẩm thực & Nấu ăn',
     'th': 'อาหาร & ทำอาหาร', 'uz': 'Ovqat va pazandachilik', 'km': 'អាហារ និងការចម្អិន',
     'my': 'စားသောက်နှင့် ချက်ပြုတ်', 'mn': 'Хоол & Тогооч', 'ja': '飲食・調理',
     'si': 'ආහාර සහ පිසීම', 'bn': 'খাদ্য ও রান্না', 'ru': 'Еда и кулинария',
     'hi': 'भोजन और खाना पकाना',
   'ne': 'खाना तथा पकाउने', 'id': 'Makanan & Memasak',
 }, 'Food & Cooking'),
   'Medical' => _t({
     'ko': '의료·건강', 'en': 'Medical', 'zh': '医疗·健康', 'vi': 'Y tế',
     'th': 'การแพทย์', 'uz': 'Tibbiyot', 'km': 'វេជ្ជសាស្ត្រ',
     'my': 'ဆေးပညာ', 'mn': 'Эмнэлэг', 'ja': '医療・健康',
     'si': 'වෛද්‍ය', 'bn': 'চিকিৎসা', 'ru': 'Медицина',
     'hi': 'चिकित्सा',
   'ne': 'चिकित्सा', 'id': 'Medis',
 }, 'Medical'),
   'Manufacturing' => _t({
     'ko': '제조·생산', 'en': 'Manufacturing', 'zh': '制造·生产', 'vi': 'Sản xuất',
     'th': 'การผลิต', 'uz': 'Ishlab chiqarish', 'km': 'ផលិតកម្ម',
     'my': 'ကုန်ထုတ်လုပ်ရေး', 'mn': 'Үйлдвэрлэл', 'ja': '製造・生産',
     'si': 'නිෂ්පාදන', 'bn': 'উৎপাদন', 'ru': 'Производство',
     'hi': 'विनिर्माण',
   'ne': 'उत्पादन', 'id': 'Manufaktur',
 }, 'Manufacturing'),
   'Cleaning & Facility' => _t({
     'ko': '청소·시설', 'en': 'Cleaning & Facility', 'zh': '清洁·设施', 'vi': 'Vệ sinh & Cơ sở vật chất',
     'th': 'ทำความสะอาด & สิ่งอำนวยความสะดวก', 'uz': 'Tozalash va binolar', 'km': 'សម្អាត និងគ្រប់គ្រងអគារ',
     'my': 'သန့်ရှင်းရေးနှင့် အဆောက်အအုံ', 'mn': 'Цэвэрлэгээ & Байгууламж', 'ja': '清掃・施設',
     'si': 'පිරිසිදු කිරීම සහ පහසුකම්', 'bn': 'পরিচ্ছন্নতা ও সুবিধা', 'ru': 'Уборка и обслуживание',
     'hi': 'सफ़ाई और सुविधा',
   'ne': 'सरसफाइ तथा सुविधा', 'id': 'Kebersihan & Fasilitas',
 }, 'Cleaning & Facility'),
   'Marketing & Sales' => _t({
     'ko': '마케팅·영업', 'en': 'Marketing & Sales', 'zh': '营销·销售', 'vi': 'Marketing & Kinh doanh',
     'th': 'การตลาด & การขาย', 'uz': 'Marketing va savdo', 'km': 'ទីផ្សារ និងការលក់',
     'ne': 'मार्केटिङ र बिक्री', 'id': 'Pemasaran & Penjualan',
     'my': 'စျေးကွက်နှင့် အရောင်း', 'mn': 'Маркетинг & Борлуулалт', 'ja': 'マーケティング・営業',
     'si': 'අලෙවිකරණය සහ විකුණුම්', 'bn': 'মার্কেটিং ও বিক্রয়', 'ru': 'Маркетинг и продажи',
     'hi': 'मार्केटिंग और बिक्री',
   }, 'Marketing & Sales'),
   'Media, Culture & Sports' => _t({
     'ko': '미디어·문화·스포츠', 'en': 'Media, Culture & Sports', 'zh': '媒体·文化·体育', 'vi': 'Truyền thông, Văn hóa & Thể thao',
     'th': 'สื่อ วัฒนธรรม & กีฬา', 'uz': 'Media, madaniyat va sport', 'km': 'ប្រព័ន្ធផ្សព្វផ្សាយ វប្បធម៌ និងកីឡា',
     'ne': 'मिडिया, संस्कृति र खेलकुद', 'id': 'Media, Budaya & Olahraga',
     'my': 'မီဒီယာ ယဉ်ကျေးမှုနှင့် အားကစား', 'mn': 'Медиа, соёл & спорт', 'ja': 'メディア・文化・スポーツ',
     'si': 'මාධ්‍ය, සංස්කෘතික සහ ක්‍රීඩා', 'bn': 'মিডিয়া, সংস্কৃতি ও খেলাধুলা', 'ru': 'Медиа, культура и спорт',
     'hi': 'मीडिया, संस्कृति और खेल',
   }, 'Media, Culture & Sports'),
   'Translation·Interpretation' => _t({
     'ko': '번역·통역', 'en': 'Translation & Interpretation', 'zh': '翻译·口译', 'vi': 'Dịch thuật & Phiên dịch',
     'th': 'การแปล & ล่าม', 'uz': 'Tarjima va tarjimonlik', 'km': 'បកប្រែ និងអ្នកបកប្រែ',
     'ne': 'अनुवाद र दोभाषे', 'id': 'Penerjemahan & Interpretasi',
     'my': 'ဘာသာပြန်နှင့် စကားပြန်', 'mn': 'Орчуулга & Хэлмэрч', 'ja': '翻訳・通訳',
     'si': 'පරිවර්තන සහ භාෂණ', 'bn': 'অনুবাদ ও দোভাষী', 'ru': 'Перевод и устный перевод',
     'hi': 'अनुवाद और दुभाषिया',
   }, 'Translation & Interpretation'),
   'Transportation & Driving' => _t({
     'ko': '운수·운전', 'en': 'Transportation & Driving', 'zh': '运输·驾驶', 'vi': 'Vận tải & Lái xe',
     'th': 'ขนส่ง & ขับรถ', 'uz': 'Transport va haydovchilik', 'km': 'ដឹកជញ្ជូន និងបើកបរ',
     'ne': 'यातायात र ड्राइभिङ', 'id': 'Transportasi & Mengemudi',
     'my': 'သယ်ယူပို့ဆောင်ရေးနှင့် ယာဉ်မောင်း', 'mn': 'Тээвэр & Жолоодлого', 'ja': '運輸・運転',
     'si': 'ප්‍රවාහනය සහ රිය පැදවීම', 'bn': 'পরিবহন ও ড্রাইভিং', 'ru': 'Транспорт и вождение',
     'hi': 'परिवहन और ड्राइविंग',
   }, 'Transportation & Driving'),
   _ => nameEn,
 };

 /// job_category_id가 없는 공고의 raw 한국어 job_type 번역
 String? translateJobTypeRaw(String jobTypeKo) => switch (jobTypeKo) {
   '기타' => _t({
     'ko': '기타', 'en': 'Other', 'zh': '其他', 'vi': 'Khác',
     'th': 'อื่นๆ', 'uz': 'Boshqa', 'km': 'ផ្សេងៗ',
     'ne': 'अन्य', 'id': 'Lainnya',
     'my': 'အခြား', 'mn': 'Бусад', 'ja': 'その他',
     'si': 'වෙනත්', 'bn': 'অন্যান্য', 'ru': 'Другое',
     'hi': 'अन्य',
   }, 'Other'),
   '생산·공정 관리자' => _t({
     'ko': '생산·공정 관리자', 'en': 'Production Manager', 'zh': '生产·工艺管理', 'vi': 'Quản lý sản xuất',
     'th': 'ผู้จัดการการผลิต', 'uz': 'Ishlab chiqarish boshqaruvchisi', 'km': 'អ្នកគ្រប់គ្រងផលិតកម្ម',
     'ne': 'उत्पादन प्रबन्धक', 'id': 'Manajer Produksi',
     'my': 'ထုတ်လုပ်ရေးမန်နေဂျာ', 'mn': 'Үйлдвэрлэлийн менежер', 'ja': '生産・工程管理者',
     'si': 'නිෂ්පාදන කළමනාකරු', 'bn': 'উৎপাদন ব্যবস্থাপক', 'ru': 'Менеджер производства',
     'hi': 'उत्पादन प्रबंधक',
   }, 'Production Manager'),
   '의료상담·코디네이터' => _t({
     'ko': '의료상담·코디네이터', 'en': 'Medical Coordinator', 'zh': '医疗咨询·协调员', 'vi': 'Điều phối viên y tế',
     'th': 'ผู้ประสานงานแพทย์', 'uz': 'Tibbiy koordinator', 'km': 'អ្នកសម្របសម្រួលវេជ្ជសាស្ត្រ',
     'ne': 'चिकित्सा समन्वयक', 'id': 'Koordinator Medis',
     'my': 'ဆေးဘက်ညှိနှိုင်းရေးမှူး', 'mn': 'Эмнэлгийн зохицуулагч', 'ja': '医療相談・コーディネーター',
     'si': 'වෛද්‍ය සම්බන්ධීකාරක', 'bn': 'চিকিৎসা সমন্বয়কারী', 'ru': 'Медицинский координатор',
     'hi': 'चिकित्सा समन्वयक',
   }, 'Medical Coordinator'),
   '의료통번역' => _t({
     'ko': '의료통번역', 'en': 'Medical Interpreter', 'zh': '医疗翻译', 'vi': 'Phiên dịch y tế',
     'th': 'ล่ามแพทย์', 'uz': 'Tibbiy tarjimon', 'km': 'អ្នកបកប្រែវេជ្ជសាស្ត្រ',
     'ne': 'चिकित्सा अनुवादक', 'id': 'Penerjemah Medis',
     'my': 'ဆေးဘက်စကားပြန်', 'mn': 'Эмнэлгийн орчуулагч', 'ja': '医療通訳・翻訳',
     'si': 'වෛද්‍ය පරිවර්තක', 'bn': 'চিকিৎসা দোভাষী', 'ru': 'Медицинский переводчик',
     'hi': 'चिकित्सा दुभाषिया',
   }, 'Medical Interpreter'),
   '환경미화원·청소부' => _t({
     'ko': '환경미화원·청소부', 'en': 'Cleaner', 'zh': '清洁工', 'vi': 'Nhân viên vệ sinh',
     'th': 'พนักงานทำความสะอาด', 'uz': 'Tozalagich', 'km': 'អ្នកសម្អាត',
     'ne': 'सरसफाइ कर्मचारी', 'id': 'Petugas Kebersihan',
     'my': 'သန့်ရှင်းရေးဝန်ထမ်း', 'mn': 'Цэвэрлэгч', 'ja': '清掃員',
     'si': 'පිරිසිදු කරන්නා', 'bn': 'পরিচ্ছন্নকর্মী', 'ru': 'Уборщик',
     'hi': 'सफ़ाई कर्मचारी',
   }, 'Cleaner'),
   '일반영업' => _t({
     'ko': '일반영업', 'en': 'Sales', 'zh': '销售', 'vi': 'Kinh doanh',
     'th': 'ฝ่ายขาย', 'uz': 'Savdo', 'km': 'ការលក់',
     'ne': 'बिक्री', 'id': 'Penjualan',
     'my': 'အရောင်း', 'mn': 'Борлуулалт', 'ja': '一般営業',
     'si': 'විකුණුම්', 'bn': 'বিক্রয়', 'ru': 'Продажи',
     'hi': 'बिक्री',
   }, 'Sales'),
   '웹개발' || '웹 개발자' => _t({
     'ko': '웹개발', 'en': 'Web Developer', 'zh': 'Web开发', 'vi': 'Lập trình Web',
     'th': 'นักพัฒนาเว็บ', 'uz': 'Veb dasturchi', 'km': 'អ្នកអភិវឌ្ឍន៍វេប',
     'ne': 'वेब विकासकर्ता', 'id': 'Pengembang Web',
     'my': 'ဝဘ်ဆော့ဖ်ဝဲရေးသား', 'mn': 'Веб хөгжүүлэгч', 'ja': 'Web開発',
     'si': 'වෙබ් සංවර්ධක', 'bn': 'ওয়েব ডেভেলপার', 'ru': 'Веб-разработчик',
     'hi': 'वेब डेवलपर',
   }, 'Web Developer'),
   '피부관리사' => _t({
     'ko': '피부관리사', 'en': 'Skincare Specialist', 'zh': '皮肤管理师', 'vi': 'Chuyên viên chăm sóc da',
     'th': 'ผู้เชี่ยวชาญดูแลผิว', 'uz': 'Teri parvarish mutaxassisi', 'km': 'អ្នកថែរក្សាស្បែក',
     'ne': 'छाला विशेषज्ञ', 'id': 'Spesialis Perawatan Kulit',
     'my': 'အသားအရေထိန်းသိမ်းမှုပညာရှင်', 'mn': 'Арьс арчилгааны мэргэжилтэн', 'ja': 'スキンケア専門家',
     'si': 'සම සත්කාර විශේෂඥ', 'bn': 'ত্বকযত্ন বিশেষজ্ঞ', 'ru': 'Специалист по уходу за кожей',
     'hi': 'त्वचा विशेषज्ञ',
   }, 'Skincare Specialist'),
   '상품 기획' => _t({
     'ko': '상품 기획', 'en': 'Product Planning', 'zh': '产品策划', 'vi': 'Hoạch định sản phẩm',
     'th': 'วางแผนผลิตภัณฑ์', 'uz': 'Mahsulot rejalashtirish', 'km': 'ផែនការផលិតផល',
     'ne': 'उत्पाद योजना', 'id': 'Perencanaan Produk',
     'my': 'ကုန်ပစ္စည်းစီစဉ်ရေး', 'mn': 'Бүтээгдэхүүн төлөвлөлт', 'ja': '商品企画',
     'si': 'නිෂ්පාදන සැලසුම්', 'bn': 'পণ্য পরিকল্পনা', 'ru': 'Планирование продукции',
     'hi': 'उत्पाद योजना',
   }, 'Product Planning'),
   '물류·구매 관리자' => _t({
     'ko': '물류·구매 관리자', 'en': 'Logistics & Purchasing Manager', 'zh': '物流·采购经理', 'vi': 'Quản lý hậu cần & mua hàng',
     'th': 'ผู้จัดการโลจิสติกส์และจัดซื้อ', 'uz': 'Logistika va xarid boshqaruvchisi', 'km': 'អ្នកគ្រប់គ្រងដឹកជញ្ជូន និងទិញទំនិញ',
     'ne': 'रसद र खरिद प्रबन्धक', 'id': 'Manajer Logistik & Pembelian',
     'my': 'ထောက်ပံ့ပို့ဆောင်ရေးနှင့်ဝယ်ယူရေးမန်နေဂျာ', 'mn': 'Логистик & Худалдан авалтын менежер', 'ja': '物流・購買管理者',
     'si': 'සැපයුම් සහ මිලදී ගැනීම් කළමනාකරු', 'bn': 'সরবরাহ ও ক্রয় ব্যবস্থাপক', 'ru': 'Менеджер по логистике и закупкам',
     'hi': 'रसद और क्रय प्रबंधक',
   }, 'Logistics & Purchasing Manager'),
   '정보통신기술(ICT), 연구개발' || 'IT기술지원' => _t({
     'ko': 'IT·기술지원', 'en': 'IT Support', 'zh': 'IT技术支持', 'vi': 'Hỗ trợ CNTT',
     'th': 'สนับสนุน IT', 'uz': 'IT qo\'llab-quvvatlash', 'km': 'គាំទ្រព័ត៌មានវិទ្យា',
     'ne': 'IT सहायता', 'id': 'Dukungan IT',
     'my': 'IT ပံ့ပိုးမှု', 'mn': 'IT дэмжлэг', 'ja': 'ITサポート',
     'si': 'IT සහාය', 'bn': 'আইটি সাপোর্ট', 'ru': 'IT-поддержка',
     'hi': 'IT सहायता',
   }, 'IT Support'),
   '채널 관리자·크리에이티브 디렉터' => _t({
     'ko': '채널 관리자·크리에이티브 디렉터', 'en': 'Creative Director', 'zh': '创意总监', 'vi': 'Giám đốc sáng tạo',
     'th': 'ผู้อำนวยการครีเอทีฟ', 'uz': 'Kreativ direktor', 'km': 'នាយកច្នៃប្រឌិត',
     'ne': 'सिर्जनात्मक निर्देशक', 'id': 'Direktur Kreatif',
     'my': 'ဖန်တီးမှုဒါရိုက်တာ', 'mn': 'Бүтээлч захирал', 'ja': 'クリエイティブディレクター',
     'si': 'නිර්මාණ අධ්‍යක්ෂ', 'bn': 'ক্রিয়েটিভ ডিরেক্টর', 'ru': 'Креативный директор',
     'hi': 'क्रिएटिव डायरेक्टर',
   }, 'Creative Director'),
   '시설·설비 관리자' => _t({
     'ko': '시설·설비 관리자', 'en': 'Facility Manager', 'zh': '设施管理员', 'vi': 'Quản lý cơ sở vật chất',
     'th': 'ผู้จัดการอาคาร', 'uz': 'Obyekt boshqaruvchisi', 'km': 'អ្នកគ្រប់គ្រងអគារ',
     'ne': 'सुविधा प्रबन्धक', 'id': 'Manajer Fasilitas',
     'my': 'အဆောက်အအုံမန်နေဂျာ', 'mn': 'Байгууламжийн менежер', 'ja': '施設管理者',
     'si': 'පහසුකම් කළමනාකරු', 'bn': 'সুবিধা ব্যবস্থাপক', 'ru': 'Менеджер по объектам',
     'hi': 'सुविधा प्रबंधक',
   }, 'Facility Manager'),
   '공장관리·안전관리·소방설비' => _t({
     'ko': '공장관리·안전관리', 'en': 'Factory & Safety Manager', 'zh': '工厂·安全管理', 'vi': 'Quản lý nhà máy & an toàn',
     'th': 'ผู้จัดการโรงงานและความปลอดภัย', 'uz': 'Zavod va xavfsizlik boshqaruvchisi', 'km': 'អ្នកគ្រប់គ្រងរោងចក្រ និងសុវត្ថិភាព',
     'ne': 'कारखाना र सुरक्षा प्रबन्धक', 'id': 'Manajer Pabrik & Keselamatan',
     'my': 'စက်ရုံနှင့်ဘေးကင်းရေးမန်နေဂျာ', 'mn': 'Үйлдвэр & Аюулгүй байдлын менежер', 'ja': '工場・安全管理者',
     'si': 'කර්මාන්තශාලා සහ ආරක්ෂක කළමනාකරු', 'bn': 'কারখানা ও নিরাপত্তা ব্যবস্থাপক', 'ru': 'Менеджер завода и безопасности',
     'hi': 'फ़ैक्टरी और सुरक्षा प्रबंधक',
   }, 'Factory & Safety Manager'),
   '운전·운송·배송' => _t({
     'ko': '운전·운송·배송', 'en': 'Driver & Delivery', 'zh': '驾驶·运输·配送', 'vi': 'Lái xe & Giao hàng',
     'th': 'ขับรถ & จัดส่ง', 'uz': 'Haydovchi va yetkazish', 'km': 'បើកបរ និងដឹកជញ្ជូន',
     'ne': 'चालक र डेलिभरी', 'id': 'Pengemudi & Pengiriman',
     'my': 'ယာဉ်မောင်းနှင့်ပို့ဆောင်', 'mn': 'Жолооч & Хүргэлт', 'ja': '運転・配送',
     'si': 'රියදුරු සහ බෙදාහැරීම', 'bn': 'ড্রাইভার ও ডেলিভারি', 'ru': 'Водитель и доставка',
     'hi': 'ड्राइवर और डिलीवरी',
   }, 'Driver & Delivery'),
   '기술연구/연구개발' || '연구개발' || '제품·공정, 연구개발' || '제품개발, 재료·화학' => _t({
     'ko': '연구개발', 'en': 'R&D', 'zh': '研发', 'vi': 'Nghiên cứu & Phát triển',
     'th': 'วิจัยและพัฒนา', 'uz': 'Tadqiqot va ishlanma', 'km': 'ស្រាវជ្រាវ និងអភិវឌ្ឍន៍',
     'ne': 'अनुसन्धान र विकास', 'id': 'Riset & Pengembangan',
     'my': 'သုတေသနနှင့်ဖွံ့ဖြိုးရေး', 'mn': 'Судалгаа & Хөгжүүлэлт', 'ja': '研究開発',
     'si': 'පර්යේෂණ සහ සංවර්ධන', 'bn': 'গবেষণা ও উন্নয়ন', 'ru': 'НИОКР',
     'hi': 'अनुसंधान एवं विकास',
   }, 'R&D'),
   '데이터베이스개발자' || '서버·네트워크개발' => _t({
     'ko': 'IT·개발', 'en': 'IT & Development', 'zh': 'IT·开发', 'vi': 'CNTT & Phát triển',
     'th': 'ไอที & พัฒนา', 'uz': 'IT & Dasturlash', 'km': 'ព័ត៌មានវិទ្យា និងអភិវឌ្ឍន៍',
     'ne': 'IT र विकास', 'id': 'IT & Pengembangan',
     'my': 'IT နှင့် ဖွံ့ဖြိုးရေး', 'mn': 'IT & Хөгжүүлэлт', 'ja': 'IT・開発',
     'si': 'IT සහ සංවර්ධන', 'bn': 'আইটি ও উন্নয়ন', 'ru': 'IT и разработка',
     'hi': 'आईटी और विकास',
   }, 'IT & Development'),
   '재고관리' => _t({
     'ko': '재고관리', 'en': 'Inventory Management', 'zh': '库存管理', 'vi': 'Quản lý kho',
     'th': 'การจัดการสินค้าคงคลัง', 'uz': 'Ombor boshqaruvi', 'km': 'គ្រប់គ្រងស្តុក',
     'ne': 'सामग्री व्यवस्थापन', 'id': 'Manajemen Persediaan',
     'my': 'စတော့ထိန်းသိမ်းမှု', 'mn': 'Нөөцийн менежмент', 'ja': '在庫管理',
     'si': 'තොග කළමනාකරණය', 'bn': 'ইনভেন্টরি ম্যানেজমেন্ট', 'ru': 'Управление запасами',
     'hi': 'इन्वेंट्री प्रबंधन',
   }, 'Inventory Management'),
   '닥트·배관설치, 생산·건설·노무 기타' || '건축·시공·전기·토목기사' => _t({
     'ko': '건설·현장', 'en': 'Construction', 'zh': '建筑·工地', 'vi': 'Xây dựng',
     'th': 'ก่อสร้าง', 'uz': 'Qurilish', 'km': 'សំណង់',
     'ne': 'निर्माण', 'id': 'Konstruksi',
     'my': 'ဆောက်လုပ်ရေး', 'mn': 'Барилга', 'ja': '建設・現場',
     'si': 'ඉදිකිරීම්', 'bn': 'নির্মাণ', 'ru': 'Строительство',
     'hi': 'निर्माण',
   }, 'Construction'),
   '제약연구개발, 제약영업' || '의료장비' => _t({
     'ko': '의료·건강', 'en': 'Medical', 'zh': '医疗·健康', 'vi': 'Y tế',
     'th': 'การแพทย์', 'uz': 'Tibbiyot', 'km': 'វេជ្ជសាស្ត្រ',
     'ne': 'चिकित्सा', 'id': 'Medis',
     'my': 'ဆေးပညာ', 'mn': 'Эмнэлэг', 'ja': '医療・健康',
     'si': 'වෛද්‍ය', 'bn': 'চিকিৎসা', 'ru': 'Медицина',
     'hi': 'चिकित्सा',
   }, 'Medical'),
   '유통·판매 기타' || '렌탈영업' || '무역영업' || '영업지원' || '일반영업, 제품개발, 구매관리' => _t({
     'ko': '영업·판매', 'en': 'Sales', 'zh': '销售', 'vi': 'Kinh doanh',
     'th': 'ฝ่ายขาย', 'uz': 'Savdo', 'km': 'ការលក់',
     'ne': 'बिक्री', 'id': 'Penjualan',
     'my': 'အရောင်း', 'mn': 'Борлуулалт', 'ja': '営業・販売',
     'si': 'විකුණුම්', 'bn': 'বিক্রয়', 'ru': 'Продажи',
     'hi': 'बिक्री',
   }, 'Sales'),
   '금속공작' => _t({
     'ko': '금속공작', 'en': 'Metalworking', 'zh': '金属加工', 'vi': 'Gia công kim loại',
     'th': 'งานโลหะ', 'uz': 'Metall ishlash', 'km': 'កែច្នៃដែក',
     'ne': 'धातु कार्य', 'id': 'Pengerjaan Logam',
     'my': 'သတ္တုလုပ်ငန်း', 'mn': 'Металл боловсруулалт', 'ja': '金属加工',
     'si': 'ලෝහ වැඩ', 'bn': 'ধাতু কাজ', 'ru': 'Металлообработка',
     'hi': 'धातु कार्य',
   }, 'Metalworking'),
   '영양사' => _t({
     'ko': '영양사', 'en': 'Nutritionist', 'zh': '营养师', 'vi': 'Chuyên gia dinh dưỡng',
     'th': 'นักโภชนาการ', 'uz': 'Dietolog', 'km': 'អ្នកជំនាញអាហារូបត្ថម្ភ',
     'ne': 'पोषण विशेषज्ञ', 'id': 'Ahli Gizi',
     'my': 'အာဟာရပညာရှင်', 'mn': 'Хоол зүйч', 'ja': '栄養士',
     'si': 'පෝෂණ විද්‍යාඥ', 'bn': 'পুষ্টিবিদ', 'ru': 'Диетолог',
     'hi': 'पोषण विशेषज्ञ',
   }, 'Nutritionist'),
   '광고관리·대행' => _t({
     'ko': '광고관리·대행', 'en': 'Advertising', 'zh': '广告管理', 'vi': 'Quảng cáo',
     'th': 'โฆษณา', 'uz': 'Reklama', 'km': 'ផ្សាយពាណិជ្ជកម្ម',
     'ne': 'विज्ञापन', 'id': 'Periklanan',
     'my': 'ကြော်ငြာ', 'mn': 'Зар сурталчилгаа', 'ja': '広告管理',
     'si': 'දැන්වීම්', 'bn': 'বিজ্ঞাপন', 'ru': 'Реклама',
     'hi': 'विज्ञापन',
   }, 'Advertising'),
   '증강현실(AR)콘텐츠제작, VR · AR 콘텐츠 스토리텔러' || '무인 항공기 시스템개발자, 드론조종' => _t({
     'ko': 'IT·개발', 'en': 'IT & Development', 'zh': 'IT·开发', 'vi': 'CNTT & Phát triển',
     'th': 'ไอที & พัฒนา', 'uz': 'IT & Dasturlash', 'km': 'ព័ត៌មានវិទ្យា និងអភិវឌ្ឍន៍',
     'ne': 'IT र विकास', 'id': 'IT & Pengembangan',
     'my': 'IT နှင့် ဖွံ့ဖြိုးရေး', 'mn': 'IT & Хөгжүүлэлт', 'ja': 'IT・開発',
     'si': 'IT සහ සංවර්ධන', 'bn': 'আইটি ও উন্নয়ন', 'ru': 'IT и разработка',
     'hi': 'आईटी और विकास',
   }, 'IT & Development'),
   '생산관리, 헤어디자이너' => _t({
     'ko': '서비스·기타', 'en': 'Service', 'zh': '服务', 'vi': 'Dịch vụ',
     'th': 'บริการ', 'uz': 'Xizmat', 'km': 'សេវាកម្ម',
     'ne': 'सेवा', 'id': 'Layanan',
     'my': 'ဝန်ဆောင်မှု', 'mn': 'Үйлчилгээ', 'ja': 'サービス',
     'si': 'සේවා', 'bn': 'সেবা', 'ru': 'Сервис',
     'hi': 'सेवा',
   }, 'Service'),
   '간병·사회복지사, 병동·외래보조' => _t({
     'ko': '간병·복지', 'en': 'Care & Welfare', 'zh': '护理·福利', 'vi': 'Chăm sóc & Phúc lợi',
     'th': 'การดูแลและสวัสดิการ', 'uz': 'Parvarish va farovonlik', 'km': 'ការថែទាំ និងសុខុមាលភាព',
     'ne': 'हेरचाह र कल्याण', 'id': 'Perawatan & Kesejahteraan',
     'my': 'ပြုစုစောင့်ရှောက်ရေးနှင့်လူမှုဖူလုံရေး', 'mn': 'Асаргаа & Халамж', 'ja': '介護・福祉',
     'si': 'සත්කාර සහ සුබසාධන', 'bn': 'পরিচর্যা ও কল্যাণ', 'ru': 'Уход и соцзащита',
     'hi': 'देखभाल और कल्याण',
   }, 'Care & Welfare'),
   '기타 엔지니어' => _t({
     'ko': '기타 엔지니어', 'en': 'Engineer', 'zh': '工程师', 'vi': 'Kỹ sư',
     'th': 'วิศวกร', 'uz': 'Muhandis', 'km': 'វិស្វករ',
     'ne': 'इन्जिनियर', 'id': 'Insinyur',
     'my': 'အင်ဂျင်နီယာ', 'mn': 'Инженер', 'ja': 'エンジニア',
     'si': 'ඉංජිනේරු', 'bn': 'ইঞ্জিনিয়ার', 'ru': 'Инженер',
     'hi': 'इंजीनियर',
   }, 'Engineer'),
   _ => null,
 };

 String translateWorkSchedule(String nameEn) => switch (nameEn) {
   '1 day/week' => _t({
     'ko': '주1일', 'en': '1 day/week', 'zh': '每周1天', 'vi': '1 ngày/tuần',
     'th': '1 วัน/สัปดาห์', 'uz': 'Haftada 1 kun', 'km': '1 ថ្ងៃ/សប្ដាហ៍',
     'my': 'တစ်ပတ် ၁ ရက်', 'mn': '7 хоногт 1 өдөр', 'ja': '週1日',
     'si': 'සතියට දින 1', 'bn': 'সপ্তাহে ১ দিন', 'ru': '1 день/нед.',
     'hi': 'सप्ताह में 1 दिन',
   'ne': 'हप्तामा १ दिन', 'id': '1 hari/minggu',
 }, '1 day/week'),
   '2 days/week' => _t({
     'ko': '주2일', 'en': '2 days/week', 'zh': '每周2天', 'vi': '2 ngày/tuần',
     'th': '2 วัน/สัปดาห์', 'uz': 'Haftada 2 kun', 'km': '2 ថ្ងៃ/សប្ដាហ៍',
     'my': 'တစ်ပတ် ၂ ရက်', 'mn': '7 хоногт 2 өдөр', 'ja': '週2日',
     'si': 'සතියට දින 2', 'bn': 'সপ্তাহে ২ দিন', 'ru': '2 дня/нед.',
     'hi': 'सप्ताह में 2 दिन',
   'ne': 'हप्तामा २ दिन', 'id': '2 hari/minggu',
 }, '2 days/week'),
   '3 days/week' => _t({
     'ko': '주3일', 'en': '3 days/week', 'zh': '每周3天', 'vi': '3 ngày/tuần',
     'th': '3 วัน/สัปดาห์', 'uz': 'Haftada 3 kun', 'km': '3 ថ្ងៃ/សប្ដាហ៍',
     'my': 'တစ်ပတ် ၃ ရက်', 'mn': '7 хоногт 3 өдөр', 'ja': '週3日',
     'si': 'සතියට දින 3', 'bn': 'সপ্তাহে ৩ দিন', 'ru': '3 дня/нед.',
     'hi': 'सप्ताह में 3 दिन',
   'ne': 'हप्तामा ३ दिन', 'id': '3 hari/minggu',
 }, '3 days/week'),
   '4 days/week' => _t({
     'ko': '주4일', 'en': '4 days/week', 'zh': '每周4天', 'vi': '4 ngày/tuần',
     'th': '4 วัน/สัปดาห์', 'uz': 'Haftada 4 kun', 'km': '4 ថ្ងៃ/សប្ដាហ៍',
     'my': 'တစ်ပတ် ၄ ရက်', 'mn': '7 хоногт 4 өдөр', 'ja': '週4日',
     'si': 'සතියට දින 4', 'bn': 'সপ্তাহে ৪ দিন', 'ru': '4 дня/нед.',
     'hi': 'सप्ताह में 4 दिन',
   'ne': 'हप्तामा ४ दिन', 'id': '4 hari/minggu',
 }, '4 days/week'),
   '5 days/week' => _t({
     'ko': '주5일', 'en': '5 days/week', 'zh': '每周5天', 'vi': '5 ngày/tuần',
     'th': '5 วัน/สัปดาห์', 'uz': 'Haftada 5 kun', 'km': '5 ថ្ងៃ/សប្ដាហ៍',
     'my': 'တစ်ပတ် ၅ ရက်', 'mn': '7 хоногт 5 өдөр', 'ja': '週5日',
     'si': 'සතියට දින 5', 'bn': 'সপ্তাহে ৫ দিন', 'ru': '5 дней/нед.',
     'hi': 'सप्ताह में 5 दिन',
   'ne': 'हप्तामा ५ दिन', 'id': '5 hari/minggu',
 }, '5 days/week'),
   '6 days/week' => _t({
     'ko': '주6일', 'en': '6 days/week', 'zh': '每周6天', 'vi': '6 ngày/tuần',
     'th': '6 วัน/สัปดาห์', 'uz': 'Haftada 6 kun', 'km': '6 ថ្ងៃ/សប្ដាហ៍',
     'my': 'တစ်ပတ် ၆ ရက်', 'mn': '7 хоногт 6 өдөр', 'ja': '週6日',
     'si': 'සතියට දින 6', 'bn': 'সপ্তাহে ৬ দিন', 'ru': '6 дней/нед.',
     'hi': 'सप्ताह में 6 दिन',
   'ne': 'हप्तामा ६ दिन', 'id': '6 hari/minggu',
 }, '6 days/week'),
   'Mon–Sun' || 'Mon-Sun' || '7 days/week' => _t({
     'ko': '주7일', 'en': '7 days/week', 'zh': '每周7天', 'vi': '7 ngày/tuần',
     'th': '7 วัน/สัปดาห์', 'uz': 'Haftada 7 kun', 'km': '7 ថ្ងៃ/សប្តាហ៍',
     'my': 'တစ်ပတ် 7 ရက်', 'mn': '7 хоног/долоо хоног', 'ja': '週7日',
     'si': 'සතියට දින 7', 'bn': 'সপ্তাহে 7 দিন', 'ru': '7 дней/неделю',
     'hi': 'सप्ताह में 7 दिन',
   'ne': 'हप्तामा ७ दिन', 'id': '7 hari/minggu',
 }, '7 days/week'),
   'Weekend' => _t({
     'ko': '주말', 'en': 'Weekend', 'zh': '周末', 'vi': 'Cuối tuần',
     'th': 'สุดสัปดาห์', 'uz': 'Dam olish kunlari', 'km': 'ចុងសប្ដាហ៍',
     'my': 'စနေ-တနင်္ဂနွေ', 'mn': 'Амралтын өдөр', 'ja': '週末',
     'si': 'සති අන්තය', 'bn': 'সাপ্তাহিক ছুটি', 'ru': 'Выходные',
     'hi': 'सप्ताहांत',
   'ne': 'सप्ताहन्त', 'id': 'Akhir pekan',
 }, 'Weekend'),
   'Negotiable' => _t({
     'ko': '협의', 'en': 'Negotiable', 'zh': '面议', 'vi': 'Thương lượng',
     'th': 'ตามตกลง', 'uz': 'Kelishiladi', 'km': 'ចរចា',
     'my': 'ညှိနှိုင်း', 'mn': 'Тохиролцоно', 'ja': '応相談',
     'si': 'සාකච්ඡා කළ හැකි', 'bn': 'আলোচনাসাপেক্ষ', 'ru': 'По договорённости',
     'hi': 'बातचीत योग्य',
   'ne': 'सहमतिमा', 'id': 'Bisa dinegosiasikan',
 }, 'Negotiable'),
   _ => nameEn,
 };

 String translateKoreanLevel(String nameEn) => switch (nameEn) {
   'Not Required' => _t({
     'ko': '무관', 'en': 'Not Required', 'zh': '不要求', 'vi': 'Không yêu cầu',
     'th': 'ไม่จำเป็น', 'uz': 'Talab qilinmaydi', 'km': 'មិនតម្រូវ',
     'my': 'မလိုအပ်ပါ', 'mn': 'Шаардлагагүй', 'ja': '不問',
     'si': 'අවශ්‍ය නැත', 'bn': 'প্রয়োজন নেই', 'ru': 'Не требуется',
     'hi': 'आवश्यक नहीं',
   'ne': 'आवश्यक छैन', 'id': 'Tidak diperlukan',
 }, 'Not Required'),
   'Beginner' => _t({
     'ko': '초급', 'en': 'Beginner', 'zh': '初级', 'vi': 'Sơ cấp',
     'th': 'เริ่มต้น', 'uz': 'Boshlang\'ich', 'km': 'ចាប់ផ្តើម',
     'my': 'အခြေခံ', 'mn': 'Анхан шат', 'ja': '初級',
     'si': 'ආරම්භක', 'bn': 'প্রাথমিক', 'ru': 'Начальный',
     'hi': 'शुरुआती',
   'ne': 'प्रारम्भिक', 'id': 'Pemula',
 }, 'Beginner'),
   'Intermediate' => _t({
     'ko': '중급', 'en': 'Intermediate', 'zh': '中级', 'vi': 'Trung cấp',
     'th': 'ปานกลาง', 'uz': 'O\'rta', 'km': 'មធ្យម',
     'my': 'အလယ်အလတ်', 'mn': 'Дунд шат', 'ja': '中級',
     'si': 'මධ්‍යම', 'bn': 'মধ্যবর্তী', 'ru': 'Средний',
     'hi': 'मध्यम',
   'ne': 'मध्यम', 'id': 'Menengah',
 }, 'Intermediate'),
   'Advanced' => _t({
     'ko': '상급', 'en': 'Advanced', 'zh': '高级', 'vi': 'Cao cấp',
     'th': 'ขั้นสูง', 'uz': 'Yuqori', 'km': 'កម្រិតខ្ពស់',
     'my': 'အဆင့်မြင့်', 'mn': 'Ахисан шат', 'ja': '上級',
     'si': 'උසස්', 'bn': 'উন্নত', 'ru': 'Продвинутый',
     'hi': 'उन्नत',
   'ne': 'उच्च', 'id': 'Mahir',
 }, 'Advanced'),
   'Native' => _t({
     'ko': '원어민', 'en': 'Native', 'zh': '母语', 'vi': 'Bản ngữ',
     'th': 'เจ้าของภาษา', 'uz': 'Ona tili', 'km': 'ជនជាតិដើម',
     'my': 'မိခင်ဘာသာ', 'mn': 'Төрөлх', 'ja': 'ネイティブ',
     'si': 'මව් භාෂාව', 'bn': 'স্থানীয়', 'ru': 'Носитель языка',
     'hi': 'मूल भाषी',
   'ne': 'मातृभाषा स्तर', 'id': 'Penutur asli',
 }, 'Native'),
   _ => nameEn,
 };

 String translateBenefit(String nameEn) => switch (nameEn) {
   'Social Insurance' => _t({
     'ko': '4대보험', 'en': 'Social Insurance', 'zh': '社会保险', 'vi': 'Bảo hiểm xã hội',
     'th': 'ประกันสังคม', 'uz': 'Ijtimoiy sug\'urta', 'km': 'ធានារ៉ាប់រងសង្គម',
     'my': 'လူမှုအာမခံ', 'mn': 'Нийгмийн даатгал', 'ja': '社会保険',
     'si': 'සමාජ රක්ෂණ', 'bn': 'সামাজিক বীমা', 'ru': 'Социальное страхование',
     'hi': 'सामाजिक बीमा',
   'ne': 'सामाजिक बीमा', 'id': 'Asuransi sosial',
 }, 'Social Insurance'),
   'Transportation Support' => _t({
     'ko': '교통비 지원', 'en': 'Transportation Support', 'zh': '交通补贴', 'vi': 'Hỗ trợ đi lại',
     'th': 'สนับสนุนค่าเดินทาง', 'uz': 'Transport xarajatlari', 'km': 'ជំនួយដឹកជញ្ជូន',
     'my': 'သယ်ယူပို့ဆောင်ရေးထောက်ပံ့', 'mn': 'Тээврийн зардал', 'ja': '交通費支給',
     'si': 'ප්‍රවාහන දීමනා', 'bn': 'পরিবহন ভাতা', 'ru': 'Оплата проезда',
     'hi': 'परिवहन सहायता',
   'ne': 'यातायात खर्च सहयोग', 'id': 'Tunjangan transportasi',
 }, 'Transportation Support'),
   'Housing Provided' => _t({
     'ko': '숙소 제공', 'en': 'Housing Provided', 'zh': '提供住宿', 'vi': 'Cung cấp chỗ ở',
     'th': 'มีที่พักให้', 'uz': 'Turar joy taqdim etiladi', 'km': 'ផ្តល់កន្លែងស្នាក់នៅ',
     'my': 'အိမ်ရာပံ့ပိုး', 'mn': 'Байр олгоно', 'ja': '住居提供',
     'si': 'නිවාස සපයනු ලැබේ', 'bn': 'বাসস্থান প্রদান', 'ru': 'Предоставляется жильё',
     'hi': 'आवास उपलब्ध',
   'ne': 'आवास उपलब्ध', 'id': 'Disediakan tempat tinggal',
 }, 'Housing Provided'),
   'Meal Provided' => _t({
     'ko': '식사 제공', 'en': 'Meal Provided', 'zh': '提供餐食', 'vi': 'Cung cấp bữa ăn',
     'th': 'มีอาหารให้', 'uz': 'Ovqat taqdim etiladi', 'km': 'ផ្តល់អាហារ',
     'my': 'အစားအသောက်ပံ့ပိုး', 'mn': 'Хоол олгоно', 'ja': '食事提供',
     'si': 'ආහාර සපයනු ලැබේ', 'bn': 'খাবার প্রদান', 'ru': 'Предоставляется питание',
     'hi': 'भोजन उपलब्ध',
   'ne': 'खाना उपलब्ध', 'id': 'Disediakan makan',
 }, 'Meal Provided'),
   'Severance Pay' => _t({
     'ko': '퇴직금', 'en': 'Severance Pay', 'zh': '遣散费', 'vi': 'Trợ cấp thôi việc',
     'th': 'เงินชดเชย', 'uz': 'Ishdan bo\'shatish to\'lovi', 'km': 'ប្រាក់បំណាច់',
     'my': 'ထွက်ခွာကြေး', 'mn': 'Тэтгэмж', 'ja': '退職金',
     'si': 'විශ්‍රාම වැටුප', 'bn': 'বিচ্ছেদ ভাতা', 'ru': 'Выходное пособие',
     'hi': 'विच्छेद वेतन',
   'ne': 'सेवानिवृत्ति भत्ता', 'id': 'Pesangon',
 }, 'Severance Pay'),
   _ => nameEn,
 };

 // ── Country Names (ISO code → localized) ──
 String countryName(String code) => switch (code) {
   'BD' => _t({'ko':'방글라데시','en':'Bangladesh','zh':'孟加拉国','hi':'बांग्लादेश','ja':'バングラデシュ','th':'บังกลาเทศ','vi':'Bangladesh','bn':'বাংলাদেশ','ru':'Бангладеш','id':'Bangladesh','ne':'बंगलादेश','km':'បង់ក្លាដែស','my':'ဘင်္ဂလားဒေ့ရှ်','si':'බංග්ලාදේශය','uz':'Bangladesh','mn':'Бангладеш'}, 'Bangladesh'),
   'KH' => _t({'ko':'캄보디아','en':'Cambodia','zh':'柬埔寨','hi':'कंबोडिया','ja':'カンボジア','th':'กัมพูชา','vi':'Campuchia','bn':'কম্বোডিয়া','ru':'Камбоджа','id':'Kamboja','ne':'कम्बोडिया','km':'កម្ពុជា','my':'ကမ္ဘောဒီးယား','si':'කාම්බෝජය','uz':'Kambodja','mn':'Камбож'}, 'Cambodia'),
   'CN' => _t({'ko':'중국','en':'China','zh':'中国','hi':'चीन','ja':'中国','th':'จีน','vi':'Trung Quốc','bn':'চীন','ru':'Китай','id':'Tiongkok','ne':'चीन','km':'ចិន','my':'တရုတ်','si':'චීනය','uz':'Xitoy','mn':'Хятад'}, 'China'),
   'IN' => _t({'ko':'인도','en':'India','zh':'印度','hi':'भारत','ja':'インド','th':'อินเดีย','vi':'Ấn Độ','bn':'ভারত','ru':'Индия','id':'India','ne':'भारत','km':'ឥណ្ឌា','my':'အိန္ဒိယ','si':'ඉන්දියාව','uz':'Hindiston','mn':'Энэтхэг'}, 'India'),
   'ID' => _t({'ko':'인도네시아','en':'Indonesia','zh':'印度尼西亚','hi':'इंडोनेशिया','ja':'インドネシア','th':'อินโดนีเซีย','vi':'Indonesia','bn':'ইন্দোনেশিয়া','ru':'Индонезия','id':'Indonesia','ne':'इन्डोनेसिया','km':'ឥណ្ឌូនេស៊ី','my':'အင်ဒိုနီးရှား','si':'ඉන්දුනීසියාව','uz':'Indoneziya','mn':'Индонез'}, 'Indonesia'),
   'JP' => _t({'ko':'일본','en':'Japan','zh':'日本','hi':'जापान','ja':'日本','th':'ญี่ปุ่น','vi':'Nhật Bản','bn':'জাপান','ru':'Япония','id':'Jepang','ne':'जापान','km':'ជប៉ុន','my':'ဂျပန်','si':'ජපානය','uz':'Yaponiya','mn':'Япон'}, 'Japan'),
   'KZ' => _t({'ko':'카자흐스탄','en':'Kazakhstan','zh':'哈萨克斯坦','hi':'कज़ाख़स्तान','ja':'カザフスタン','th':'คาซัคสถาน','vi':'Kazakhstan','bn':'কাজাখস্তান','ru':'Казахстан','id':'Kazakhstan','ne':'कजाखस्तान','km':'កាហ្សាក់ស្ថាន','my':'ကာဇက်စတန်','si':'කසකස්තානය','uz':'Qozogʻiston','mn':'Казахстан'}, 'Kazakhstan'),
   'KG' => _t({'ko':'키르기스스탄','en':'Kyrgyzstan','zh':'吉尔吉斯斯坦','hi':'किर्गिज़स्तान','ja':'キルギス','th':'คีร์กีซสถาน','vi':'Kyrgyzstan','bn':'কিরগিজস্তান','ru':'Кыргызстан','id':'Kirgizstan','ne':'किर्गिस्तान','km':'កៀហ្ស៊ីស៊ីស្ថាន','my':'ကာဂစ်စတန်','si':'කිර්ගිස්තානය','uz':'Qirgʻiziston','mn':'Кыргызстан'}, 'Kyrgyzstan'),
   'MN' => _t({'ko':'몽골','en':'Mongolia','zh':'蒙古','hi':'मंगोलिया','ja':'モンゴル','th':'มองโกเลีย','vi':'Mông Cổ','bn':'মঙ্গোলিয়া','ru':'Монголия','id':'Mongolia','ne':'मंगोलिया','km':'ម៉ុងហ្គោលី','my':'မွန်ဂိုလီးယား','si':'මොංගෝලියාව','uz':'Moʻgʻuliston','mn':'Монгол'}, 'Mongolia'),
   'MM' => _t({'ko':'미얀마','en':'Myanmar','zh':'缅甸','hi':'म्यांमार','ja':'ミャンマー','th':'เมียนมา','vi':'Myanmar','bn':'মায়ানমার','ru':'Мьянма','id':'Myanmar','ne':'म्यानमार','km':'មីយ៉ាន់ម៉ា','my':'မြန်မာ','si':'මියන්මාරය','uz':'Myanma','mn':'Мьянмар'}, 'Myanmar'),
   'NP' => _t({'ko':'네팔','en':'Nepal','zh':'尼泊尔','hi':'नेपाल','ja':'ネパール','th':'เนปาล','vi':'Nepal','bn':'নেপাল','ru':'Непал','id':'Nepal','ne':'नेपाल','km':'នេប៉ាល់','my':'နီပေါ','si':'නේපාලය','uz':'Nepal','mn':'Балба'}, 'Nepal'),
   'PK' => _t({'ko':'파키스탄','en':'Pakistan','zh':'巴基斯坦','hi':'पाकिस्तान','ja':'パキスタン','th':'ปากีสถาน','vi':'Pakistan','bn':'পাকিস্তান','ru':'Пакистан','id':'Pakistan','ne':'पाकिस्तान','km':'ប៉ាគីស្ថាន','my':'ပါကစ္စတန်','si':'පාකිස්තානය','uz':'Pokiston','mn':'Пакистан'}, 'Pakistan'),
   'PH' => _t({'ko':'필리핀','en':'Philippines','zh':'菲律宾','hi':'फिलीपींस','ja':'フィリピン','th':'ฟิลิปปินส์','vi':'Philippines','bn':'ফিলিপাইন','ru':'Филиппины','id':'Filipina','ne':'फिलिपिन्स','km':'ហ្វីលីពីន','my':'ဖိလစ်ပိုင်','si':'පිලිපීනය','uz':'Filippin','mn':'Филиппин'}, 'Philippines'),
   'RU' => _t({'ko':'러시아','en':'Russia','zh':'俄罗斯','hi':'रूस','ja':'ロシア','th':'รัสเซีย','vi':'Nga','bn':'রাশিয়া','ru':'Россия','id':'Rusia','ne':'रुस','km':'រុស្ស៊ី','my':'ရုရှား','si':'රුසියාව','uz':'Rossiya','mn':'Орос'}, 'Russia'),
   'LK' => _t({'ko':'스리랑카','en':'Sri Lanka','zh':'斯里兰卡','hi':'श्रीलंका','ja':'スリランカ','th':'ศรีลังกา','vi':'Sri Lanka','bn':'শ্রীলঙ্কা','ru':'Шри-Ланка','id':'Sri Lanka','ne':'श्रीलंका','km':'ស្រីលង្កា','my':'သီရိလင်္ကာ','si':'ශ්‍රී ලංකාව','uz':'Shri-Lanka','mn':'Шри Ланка'}, 'Sri Lanka'),
   'TJ' => _t({'ko':'타지키스탄','en':'Tajikistan','zh':'塔吉克斯坦','hi':'ताजिकिस्तान','ja':'タジキスタン','th':'ทาจิกิสถาน','vi':'Tajikistan','bn':'তাজিকিস্তান','ru':'Таджикистан','id':'Tajikistan','ne':'ताजिकिस्तान','km':'តាជីគីស្ថាន','my':'တာဂျစ်ကစ္စတန်','si':'ටජිකිස්තානය','uz':'Tojikiston','mn':'Тажикистан'}, 'Tajikistan'),
   'TH' => _t({'ko':'태국','en':'Thailand','zh':'泰国','hi':'थाईलैंड','ja':'タイ','th':'ไทย','vi':'Thái Lan','bn':'থাইল্যান্ড','ru':'Таиланд','id':'Thailand','ne':'थाइल्यान्ड','km':'ថៃ','my':'ထိုင်း','si':'තායිලන්තය','uz':'Tailand','mn':'Тайланд'}, 'Thailand'),
   'TM' => _t({'ko':'투르크메니스탄','en':'Turkmenistan','zh':'土库曼斯坦','hi':'तुर्कमेनिस्तान','ja':'トルクメニスタン','th':'เติร์กเมนิสถาน','vi':'Turkmenistan','bn':'তুর্কমেনিস্তান','ru':'Туркменистан','id':'Turkmenistan','ne':'तुर्कमेनिस्तान','km':'តួកម៉េនីស្ថាន','my':'တာ့ခ်မင်နစ္စတန်','si':'ටර්ක්මෙනිස්තානය','uz':'Turkmaniston','mn':'Туркменистан'}, 'Turkmenistan'),
   'UZ' => _t({'ko':'우즈베키스탄','en':'Uzbekistan','zh':'乌兹别克斯坦','hi':'उज़्बेकिस्तान','ja':'ウズベキスタン','th':'อุซเบกิสถาน','vi':'Uzbekistan','bn':'উজবেকিস্তান','ru':'Узбекистан','id':'Uzbekistan','ne':'उज्बेकिस्तान','km':'អ៊ូសបេគីស្ថាន','my':'ဥဇဘက်ကစ္စတန်','si':'උස්බෙකිස්තානය','uz':'Oʻzbekiston','mn':'Узбекистан'}, 'Uzbekistan'),
   'VN' => _t({'ko':'베트남','en':'Vietnam','zh':'越南','hi':'वियतनाम','ja':'ベトナム','th':'เวียดนาม','vi':'Việt Nam','bn':'ভিয়েতনাম','ru':'Вьетнам','id':'Vietnam','ne':'भियतनाम','km':'វៀតណាម','my':'ဗီယက်နမ်','si':'වියට්නාමය','uz':'Vyetnam','mn':'Вьетнам'}, 'Vietnam'),
   _ => code,
 };

 // ── 필터 개편 (탭+칩 그리드) ──
 String get filterTitle => _t({
 'ko': '필터', 'en': 'Filter', 'zh': '筛选', 'hi': 'फ़िल्टर', 'ja': 'フィルター',
 'th': 'ตัวกรอง', 'vi': 'Bộ lọc', 'bn': 'ফিল্টার', 'ru': 'Фильтр', 'id': 'Filter',
 'ne': 'फिल्टर', 'km': 'តម្រង', 'my': 'စစ်ထုတ်ရန်', 'si': 'පෙරහන',
 'uz': 'Filtr', 'mn': 'Шүүлтүүр',
 }, 'Filter');

 String get filterRegionHint => _t({
 'ko': '시·도를 누르면 시·군·구까지 고를 수 있어요',
 'en': 'Tap a region to pick districts',
 'zh': '点击地区可选择区/郡', 'hi': 'ज़िला चुनने के लिए क्षेत्र दबाएँ',
 'ja': '地域をタップすると市·郡·区まで選べます', 'th': 'แตะภูมิภาคเพื่อเลือกเขต',
 'vi': 'Chạm vào khu vực để chọn quận/huyện', 'bn': 'জেলা বাছতে অঞ্চলে চাপুন',
 'ru': 'Нажмите регион, чтобы выбрать районы', 'id': 'Ketuk wilayah untuk pilih distrik',
 'ne': 'जिल्ला छान्न क्षेत्र थिच्नुहोस्', 'km': 'ចុចតំបន់ដើម្បីជ្រើសស្រុក',
 'my': 'ခရိုင်ရွေးရန် ဒေသကိုနှိပ်ပါ', 'si': 'දිස්ත්‍රික්ක තෝරන්න ප්‍රදේශය ඔබන්න',
 'uz': 'Tuman tanlash uchun hududni bosing', 'mn': 'Дүүрэг сонгохоор бүс дээр дарна уу',
 }, 'Tap a region to pick districts');

 String filterMoreN(int n) => _t({
 'ko': '+{n} 더보기', 'en': '+{n} more', 'zh': '+{n} 更多', 'hi': '+{n} और',
 'ja': '+{n} もっと見る', 'th': '+{n} เพิ่มเติม', 'vi': '+{n} xem thêm',
 'bn': '+{n} আরও', 'ru': 'ещё +{n}', 'id': '+{n} lainnya', 'ne': '+{n} थप',
 'km': '+{n} បន្ថែម', 'my': '+{n} ထပ်ကြည့်ရန်', 'si': '+{n} තව',
 'uz': "+{n} ko'proq", 'mn': '+{n} дэлгэрэнгүй',
 }, '+{n} more').replaceAll('{n}', '$n');

 String get filterCollapse => _t({
 'ko': '접기', 'en': 'Collapse', 'zh': '收起', 'hi': 'समेटें', 'ja': '閉じる',
 'th': 'ย่อ', 'vi': 'Thu gọn', 'bn': 'গুটান', 'ru': 'Свернуть', 'id': 'Tutup',
 'ne': 'बन्द गर्नुहोस्', 'km': 'បង្រួម', 'my': 'ခေါက်ရန်', 'si': 'හකුළන්න',
 'uz': "Yig'ish", 'mn': 'Хураах',
 }, 'Collapse');

 /// '{si} 전지역' — si는 시·도명
 String filterAllRegion(String si) => _t({
 'ko': '{si} 전지역', 'en': 'All of {si}', 'zh': '{si}全部地区', 'hi': 'पूरा {si}',
 'ja': '{si}全域', 'th': 'ทั้งหมดของ {si}', 'vi': 'Toàn bộ {si}', 'bn': 'সমগ্র {si}',
 'ru': 'Весь {si}', 'id': 'Seluruh {si}', 'ne': 'सम्पूर्ण {si}', 'km': 'ទាំងអស់ {si}',
 'my': '{si} တစ်ခုလုံး', 'si': '{si} සම්පූර්ණ', 'uz': 'Butun {si}', 'mn': 'Бүх {si}',
 }, 'All of {si}').replaceAll('{si}', si);

 /// 지역 시트 적용 버튼 — 'N곳 적용'
 String filterApplyPlaces(int n) => _t({
 'ko': '{n}곳 적용', 'en': 'Apply {n}', 'zh': '应用 {n} 处', 'hi': '{n} लागू करें',
 'ja': '{n}か所適用', 'th': 'ใช้ {n} แห่ง', 'vi': 'Áp dụng {n}', 'bn': '{n}টি প্রয়োগ',
 'ru': 'Применить {n}', 'id': 'Terapkan {n}', 'ne': '{n} लागू', 'km': 'អនុវត្ត {n}',
 'my': '{n} ခုသုံးရန်', 'si': '{n}ක් යොදන්න', 'uz': "{n} ta qo'llash", 'mn': '{n} хэрэглэх',
 }, 'Apply {n}').replaceAll('{n}', '$n');

 String get filterSigungu => _t({
 'ko': '시·군·구', 'en': 'Districts', 'zh': '市/郡/区', 'hi': 'ज़िले', 'ja': '市·郡·区',
 'th': 'เขต/อำเภอ', 'vi': 'Quận/Huyện', 'bn': 'জেলা', 'ru': 'Районы', 'id': 'Distrik',
 'ne': 'जिल्ला', 'km': 'ស្រុក/ខណ្ឌ', 'my': 'မြို့နယ်', 'si': 'දිස්ත්‍රික්ක',
 'uz': 'Tumanlar', 'mn': 'Дүүргүүд',
 }, 'Districts');

 // ── Filter Exit Confirm ──
 String get filterExitConfirm => _t({
 'ko': '변경사항을 적용할까요?',
 'en': 'Apply changes?',
 'zh': '应用更改？',
 'hi': 'बदलाव लागू करें?',
 'ja': '変更を適用しますか？',
 'th': 'ใช้การเปลี่ยนแปลงหรือไม่?',
 'vi': 'Áp dụng thay đổi?',
 'bn': 'পরিবর্তন প্রয়োগ করবেন?',
 'ru': 'Применить изменения?',
 'id': 'Terapkan perubahan?',
 'ne': 'परिवर्तन लागू गर्ने?',
 'km': 'អនុវត្តការផ្លាស់ប្ដូរ?',
 'my': 'ပြောင်းလဲမှုများကို အသုံးချမလား?',
 'si': 'වෙනස්කම් යොදන්නද?',
 'uz': "O'zgarishlarni qo'llaysizmi?",
 'mn': 'Өөрчлөлтийг хэрэглэх үү?',
 }, 'Apply changes?');

 String get filterExitApply => _t({
 'ko': '적용하기',
 'en': 'Apply',
 'zh': '应用',
 'hi': 'लागू करें',
 'ja': '適用する',
 'th': 'ใช้',
 'vi': 'Áp dụng',
 'bn': 'প্রয়োগ',
 'ru': 'Применить',
 'id': 'Terapkan',
 'ne': 'लागू गर्नुहोस्',
 'km': 'អនុវត្ត',
 'my': 'အသုံးချမည်',
 'si': 'යොදන්න',
 'uz': "Qo'llash",
 'mn': 'Хэрэглэх',
 }, 'Apply');

 String get filterExitLeave => _t({
 'ko': '나가기',
 'en': 'Leave',
 'zh': '离开',
 'hi': 'बाहर जाएं',
 'ja': '戻る',
 'th': 'ออก',
 'vi': 'Thoát',
 'bn': 'বের হন',
 'ru': 'Выйти',
 'id': 'Keluar',
 'ne': 'बाहिर जानुहोस्',
 'km': 'ចាកចេញ',
 'my': 'ထွက်မည်',
 'si': 'පිටවන්න',
 'uz': 'Chiqish',
 'mn': 'Гарах',
 }, 'Leave');

 // ── 검색 필터 추천 탭 ──
 String get searchResultsTab => _t({
 'ko': '검색결과',
 'en': 'Results',
 'zh': '搜索结果',
 'hi': 'परिणाम',
 'ja': '検索結果',
 'th': 'ผลลัพธ์',
 'vi': 'Kết quả',
 'bn': 'ফলাফল',
 'ru': 'Результаты',
 'id': 'Hasil',
 'ne': 'नतिजा',
 'km': 'លទ្ធផល',
 'my': 'ရလဒ်များ',
 'uz': 'Natijalar',
 'mn': 'Үр дүн',
   'si': 'ප්‍රතිඵල',
 }, 'Results');

 String get filterMatchTab => _t({
 'ko': '필터',
 'en': 'Filter',
 'zh': '筛选',
 'hi': 'फ़िल्टर',
 'ja': 'フィルター',
 'th': 'ตัวกรอง',
 'vi': 'Bộ lọc',
 'bn': 'ফিল্টার',
 'ru': 'Фильтр',
 'id': 'Filter',
 'ne': 'फिल्टर',
 'km': 'តម្រង',
 'my': 'စစ်ထုတ်',
 'uz': 'Filtr',
 'mn': 'Шүүлтүүр',
   'si': 'පෙරහන',
 }, 'Filter');

 String get applySelectedFilters => _t({
 'ko': '적용하기',
 'en': 'Apply',
 'zh': '应用',
 'hi': 'लागू करें',
 'ja': '適用する',
 'th': 'ใช้งาน',
 'vi': 'Áp dụng',
 'bn': 'প্রয়োগ করুন',
 'ru': 'Применить',
 'id': 'Terapkan',
 'ne': 'लागू गर्नुहोस्',
 'km': 'អនុវត្ត',
 'my': 'အသုံးပြုပါ',
 'uz': 'Qo\'llash',
 'mn': 'Хэрэглэх',
   'si': 'යොදන්න',
 }, 'Apply');

 // ── Helper ──
 String _t(Map<String, String> map, String fallback) {
 return map[_l] ?? map['en'] ?? fallback;
 }
}
