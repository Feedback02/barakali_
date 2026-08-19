// Marketing-site copy in the three Barakali languages. Russian is the template /
// default; uz and en mirror its keys. Keep every value free of the em dash (use
// commas, periods, colons), matching the app's house style. Copy is written for
// the Tashkent launch and references local food (non, somsa, pastries) and so'm.

export const languages = ['ru', 'uz', 'en'] as const;
export type Lang = (typeof languages)[number];
export const defaultLang: Lang = 'ru';

export const langNames: Record<Lang, string> = {
  ru: 'Русский',
  uz: "O'zbekcha",
  en: 'English',
};

export const ui = {
  ru: {
    'meta.title': 'Barakali - Спасайте вкусную еду в Ташкенте и экономьте',
    'meta.description':
      'Barakali спасает непроданные лепёшки, самсу, выпечку и готовые блюда из пекарен, кафе, чайхан и супермаркетов Ташкента по цене намного ниже обычной. Бронируйте сюрприз-набор, оплачивайте через Payme или Click и забирайте. Скоро запуск.',

    'nav.how': 'Как это работает',
    'nav.business': 'Для бизнеса',
    'nav.waitlist': 'В список ожидания',
    'nav.partner': 'Стать партнёром',

    'hero.badge': 'Скоро в Ташкенте',
    'hero.title': 'Отличная еда, слишком хорошая, чтобы пропадать',
    'hero.subtitle':
      'Barakali соединяет вас с сюрприз-наборами из свежих лепёшек, самсы, выпечки и домашних блюд из пекарен, кафе и супермаркетов Ташкента, за несколько тысяч сумов вместо полной цены. Хорошо для кошелька и против пищевых отходов.',
    'hero.ctaEat': 'Хочу поесть',
    'hero.ctaBusiness': 'У меня бизнес',
    'hero.note': 'Скоро запуск. Запишитесь, чтобы быть первыми.',

    'value.title': 'Почему Barakali',
    'value.save.title': 'Экономьте',
    'value.save.text':
      'Сюрприз-набор стоит несколько тысяч сумов, намного дешевле обычной цены. Ешьте вкусно за меньшие деньги.',
    'value.planet.title': 'Против пищевых отходов',
    'value.planet.text':
      'Треть всей еды выбрасывается. Каждый спасённый набор не даёт хорошим лепёшкам и блюдам попасть в мусор.',
    'value.local.title': 'Открывайте местное',
    'value.local.text':
      'Находите места в своей махалле, от пекарни на углу до чайханы, где вы ещё не были.',

    'how.title': 'Как это работает',
    'how.step1.title': 'Забронируйте набор',
    'how.step1.text':
      'Смотрите предложения пекарен, кафе и магазинов Ташкента и бронируйте набор, пока он не закончился.',
    'how.step2.title': 'Оплатите в приложении',
    'how.step2.text':
      'Безопасная оплата через Payme или Click. Без наличных и очередей.',
    'how.step3.title': 'Заберите и наслаждайтесь',
    'how.step3.text':
      'Покажите код получения на кассе в указанное время. Готово.',

    'impact.title': 'Еда, которой нельзя пропадать',
    'impact.stat1.value': '1/3',
    'impact.stat1.label': 'всей произведённой еды пропадает',
    'impact.stat2.value': 'Свежий нон',
    'impact.stat2.label': 'и блюда, спасённые каждый день',
    'impact.stat3.value': 'Честные цены',
    'impact.stat3.label': 'для вас и для бизнеса Ташкента',

    'business.badge': 'Для бизнеса',
    'business.title': 'Превратите излишки в доход',
    'business.subtitle':
      'Присоединяйтесь к Barakali, привлекайте новых клиентов в Ташкенте и сокращайте отходы. Выставляйте лепёшки, выпечку и блюда, которые остались к концу дня, а мы приведём к вам соседей.',
    'business.b1.title': 'Возвращайте упущенный доход',
    'business.b1.text':
      'Продавайте излишки, которые иначе пришлось бы выбросить.',
    'business.b2.title': 'Новые клиенты',
    'business.b2.text':
      'Вас находят люди из вашей махалли и становятся постоянными гостями.',
    'business.b3.title': 'Меньше отходов',
    'business.b3.text': 'Доброе дело для города и планеты.',
    'business.b4.title': '0% на старте',
    'business.b4.text':
      'Первые партнёры подключаются с комиссией 0% и плавным ростом в течение шести месяцев.',
    'business.cta': 'Стать партнёром',

    'waitlist.title': 'Будьте первыми',
    'waitlist.subtitle':
      'Запишитесь, и мы сообщим, как только Barakali заработает в Ташкенте.',
    'waitlist.contactLabel': 'Эл. почта или телефон',
    'waitlist.placeholder': 'you@example.com или +998 90 123 45 67',
    'waitlist.submit': 'Записаться',
    'waitlist.sending': 'Отправляем...',
    'waitlist.success': 'Вы в списке. Скоро свяжемся с вами.',
    'waitlist.error': 'Что-то пошло не так. Попробуйте ещё раз.',
    'waitlist.missing': 'Введите эл. почту или номер телефона.',

    'merchant.title': 'Сотрудничество с Barakali',
    'merchant.subtitle':
      'Расскажите о своём бизнесе, и мы свяжемся с вами для подключения.',
    'merchant.business': 'Название бизнеса',
    'merchant.contact': 'Контактное лицо',
    'merchant.phone': 'Телефон',
    'merchant.email': 'Эл. почта (необязательно)',
    'merchant.city': 'Город',
    'merchant.message': 'Что-то ещё? (необязательно)',
    'merchant.submit': 'Оставить заявку',
    'merchant.sending': 'Отправляем...',
    'merchant.success': 'Спасибо. Наша команда скоро свяжется с вами.',
    'merchant.error': 'Что-то пошло не так. Попробуйте ещё раз.',
    'merchant.required': 'Укажите название бизнеса и телефон.',

    'footer.tagline': 'Спасайте хорошую еду. Экономьте. Сокращайте отходы.',
    'footer.madeIn': 'Сделано для Узбекистана',
    'footer.rights': 'Все права защищены.',
    'footer.eaters': 'Для тех, кто ест',
    'footer.business': 'Для бизнеса',
    'footer.benefits': 'Преимущества',
    'footer.privacy': 'Конфиденциальность',
    'form.consent': 'Отправляя форму, вы соглашаетесь с нашей {link}.',
    'form.consentLink': 'Политикой конфиденциальности',
    'form.captchaError': 'Не удалось пройти проверку. Попробуйте ещё раз.',
  },

  uz: {
    'meta.title': "Barakali - Toshkentda mazali ovqatni saqlang va tejang",
    'meta.description':
      "Barakali Toshkentdagi nonvoyxona, kafe, choyxona va supermarketlardan sotilmagan non, somsa, shirinlik va tayyor taomlarni odatdagidan ancha arzon narxda saqlaydi. Sirli to'plam band qiling, Payme yoki Click orqali to'lang va olib keting. Tez orada.",

    'nav.how': 'Qanday ishlaydi',
    'nav.business': 'Biznes uchun',
    'nav.waitlist': "Ro'yxatga yozilish",
    'nav.partner': "Hamkor bo'lish",

    'hero.badge': "Tez orada Toshkentda",
    'hero.title': "Ajoyib ovqat, isrof bo'lishi achinarli",
    'hero.subtitle':
      "Barakali sizni Toshkentdagi nonvoyxona, kafe va supermarketlarning yangi non, somsa, shirinlik va uy taomlaridan iborat sirli to'plamlari bilan bog'laydi, to'liq narx o'rniga bir necha ming so'mga. Hamyonbop va ovqat isrofiga qarshi.",
    'hero.ctaEat': 'Ovqatlanmoqchiman',
    'hero.ctaBusiness': 'Men biznesman',
    'hero.note': "Tez orada ishga tushadi. Birinchi bo'lish uchun yoziling.",

    'value.title': 'Nega Barakali',
    'value.save.title': 'Tejang',
    'value.save.text':
      "Sirli to'plam bir necha ming so'm turadi, odatdagi narxdan ancha arzon. Kamroq pulga mazali ovqatlaning.",
    'value.planet.title': 'Ovqat isrofiga qarshi',
    'value.planet.text':
      "Barcha ovqatning uchdan biri tashlab yuboriladi. Har bir saqlangan to'plam yaxshi non va taomlarni axlatdan asraydi.",
    'value.local.title': 'Mahalliyni kashf eting',
    'value.local.text':
      "Mahallangizdagi joylarni kashf eting, burchakdagi nonvoyxonadan hali bormagan choyxonangizgacha.",

    'how.title': 'Qanday ishlaydi',
    'how.step1.title': "To'plam band qiling",
    'how.step1.text':
      "Toshkentdagi nonvoyxona, kafe va do'konlar takliflarini ko'ring va to'plam tugamasdan band qiling.",
    'how.step2.title': "Ilovada to'lang",
    'how.step2.text':
      "Payme yoki Click orqali xavfsiz to'lov. Naqd pulsiz, navbatsiz.",
    'how.step3.title': 'Olib keting va rohatlaning',
    'how.step3.text':
      "Belgilangan vaqtda kassada olish kodini ko'rsating. Tamom.",

    'impact.title': "Isrof bo'lmasligi kerak bo'lgan ovqat",
    'impact.stat1.value': '1/3',
    'impact.stat1.label': "ishlab chiqarilgan ovqatning isrof bo'ladi",
    'impact.stat2.value': 'Yangi non',
    'impact.stat2.label': 'va taomlar, har kuni saqlanadi',
    'impact.stat3.value': 'Adolatli narx',
    'impact.stat3.label': 'siz va Toshkent biznesi uchun',

    'business.badge': 'Biznes uchun',
    'business.title': 'Ortiqchani daromadga aylantiring',
    'business.subtitle':
      "Barakaliga qo'shiling, Toshkentda yangi mijozlarni jalb qiling va isrofni kamaytiring. Kun oxirida qolgan non, shirinlik va taomlarni joylang, biz ularni yaqin atrofdagilarga yetkazamiz.",
    'business.b1.title': "Yo'qotilgan daromadni qaytaring",
    'business.b1.text': 'Aks holda tashlanadigan ortiqcha mahsulotni soting.',
    'business.b2.title': 'Yangi mijozlar',
    'business.b2.text':
      'Mahallangizdagi odamlar sizni topadi va doimiy mijozga aylanadi.',
    'business.b3.title': 'Kamroq isrof',
    'business.b3.text': 'Shahringiz va tabiat uchun xayrli ish.',
    'business.b4.title': "Boshida 0%",
    'business.b4.text':
      "Birinchi hamkorlar 0% komissiya bilan boshlaydi, olti oy davomida bosqichma-bosqich oshadi.",
    'business.cta': "Hamkor bo'lish",

    'waitlist.title': "Birinchi bo'ling",
    'waitlist.subtitle':
      'Yoziling, Barakali Toshkentda ishga tushishi bilan xabar beramiz.',
    'waitlist.contactLabel': 'Email yoki telefon',
    'waitlist.placeholder': 'you@example.com yoki +998 90 123 45 67',
    'waitlist.submit': 'Yozilish',
    'waitlist.sending': 'Yuborilmoqda...',
    'waitlist.success': "Siz ro'yxatdasiz. Tez orada bog'lanamiz.",
    'waitlist.error': "Nimadir xato ketdi. Qayta urinib ko'ring.",
    'waitlist.missing': 'Email yoki telefon raqamini kiriting.',

    'merchant.title': 'Barakali bilan hamkorlik',
    'merchant.subtitle':
      "Biznesingiz haqida ayting, ulanish uchun siz bilan bog'lanamiz.",
    'merchant.business': 'Biznes nomi',
    'merchant.contact': 'Aloqa shaxsi',
    'merchant.phone': 'Telefon',
    'merchant.email': 'Email (ixtiyoriy)',
    'merchant.city': 'Shahar',
    'merchant.message': 'Yana nimadir? (ixtiyoriy)',
    'merchant.submit': 'Ariza qoldirish',
    'merchant.sending': 'Yuborilmoqda...',
    'merchant.success': "Rahmat. Jamoamiz tez orada bog'lanadi.",
    'merchant.error': "Nimadir xato ketdi. Qayta urinib ko'ring.",
    'merchant.required': 'Biznes nomi va telefonni kiriting.',

    'footer.tagline': "Yaxshi ovqatni saqlang. Tejang. Isrofni kamaytiring.",
    'footer.madeIn': "O'zbekiston uchun yaratilgan",
    'footer.rights': 'Barcha huquqlar himoyalangan.',
    'footer.eaters': 'Ovqatlanuvchilar uchun',
    'footer.business': 'Biznes uchun',
    'footer.benefits': 'Afzalliklar',
    'footer.privacy': 'Maxfiylik',
    'form.consent': "Yuborish orqali siz bizning {link} rozilik bildirasiz.",
    'form.consentLink': 'Maxfiylik siyosatimizga',
    'form.captchaError': "Tekshiruvdan o'tib bo'lmadi. Qayta urinib ko'ring.",
  },

  en: {
    'meta.title': 'Barakali - Save good food in Tashkent, save money',
    'meta.description':
      "Barakali rescues unsold non, somsa, pastries and meals from bakeries, cafes, choyxonas and supermarkets across Tashkent, at a fraction of the price. Reserve a surprise bag, pay with Payme or Click, pick it up. Coming soon.",

    'nav.how': 'How it works',
    'nav.business': 'For business',
    'nav.waitlist': 'Join waitlist',
    'nav.partner': 'Become a partner',

    'hero.badge': 'Coming soon to Tashkent',
    'hero.title': 'Great food, too good to waste',
    'hero.subtitle':
      "Barakali connects you with surprise bags of fresh non, somsa, pastries and home-style meals from bakeries, cafes and supermarkets across Tashkent, for a few thousand so'm instead of full price. Good for your wallet, great against food waste.",
    'hero.ctaEat': 'I want to eat',
    'hero.ctaBusiness': "I'm a business",
    'hero.note': 'Launching soon. Join the waitlist to be first.',

    'value.title': 'Why Barakali',
    'value.save.title': 'Save money',
    'value.save.text':
      "A surprise bag costs a few thousand so'm, a fraction of the original price. Eat well for less.",
    'value.planet.title': 'Fight food waste',
    'value.planet.text':
      'A third of all food is thrown away. Every bag you rescue keeps good non and meals out of the bin.',
    'value.local.title': 'Discover local',
    'value.local.text':
      'Find gems around your mahalla, from the bakery on the corner to a choyxona you have not tried yet.',

    'how.title': 'How it works',
    'how.step1.title': 'Reserve a surprise bag',
    'how.step1.text':
      'Browse offers from bakeries, cafes and shops across Tashkent and reserve a bag before it sells out.',
    'how.step2.title': 'Pay in the app',
    'how.step2.text':
      'Secure payment with Payme or Click. No cash, no queue.',
    'how.step3.title': 'Pick up and enjoy',
    'how.step3.text':
      'Show your pickup code at the counter during the pickup window. That is it.',

    'impact.title': 'Food too good to waste',
    'impact.stat1.value': '1/3',
    'impact.stat1.label': 'of all food produced is wasted',
    'impact.stat2.value': 'Fresh non',
    'impact.stat2.label': 'and meals, saved every day',
    'impact.stat3.value': 'Fair prices',
    'impact.stat3.label': 'for you and for Tashkent businesses',

    'business.badge': 'For business',
    'business.title': 'Turn surplus into revenue',
    'business.subtitle':
      'Join Barakali, reach new customers across Tashkent and cut waste. List the non, pastries and meals left at the end of the day and we send them to locals nearby.',
    'business.b1.title': 'Recover lost revenue',
    'business.b1.text':
      'Sell surplus that would otherwise be thrown away.',
    'business.b2.title': 'Reach new customers',
    'business.b2.text':
      'Get discovered by people in your mahalla who become regulars.',
    'business.b3.title': 'Cut food waste',
    'business.b3.text': 'Do right by your community and the planet.',
    'business.b4.title': '0% to start',
    'business.b4.text':
      'First partners onboard at 0% commission, with a gentle ramp over six months.',
    'business.cta': 'Become a partner',

    'waitlist.title': 'Be first to taste it',
    'waitlist.subtitle':
      'Join the waitlist and we will tell you the moment Barakali goes live in Tashkent.',
    'waitlist.contactLabel': 'Email or phone',
    'waitlist.placeholder': 'you@example.com or +998 90 123 45 67',
    'waitlist.submit': 'Join the waitlist',
    'waitlist.sending': 'Sending...',
    'waitlist.success': "You are on the list. We will be in touch soon.",
    'waitlist.error': 'Something went wrong. Please try again.',
    'waitlist.missing': 'Enter an email or phone number.',

    'merchant.title': 'Partner with Barakali',
    'merchant.subtitle':
      'Tell us about your business and we will reach out to get you set up.',
    'merchant.business': 'Business name',
    'merchant.contact': 'Contact name',
    'merchant.phone': 'Phone',
    'merchant.email': 'Email (optional)',
    'merchant.city': 'City',
    'merchant.message': 'Anything else? (optional)',
    'merchant.submit': 'Request to join',
    'merchant.sending': 'Sending...',
    'merchant.success': 'Thanks. Our team will contact you shortly.',
    'merchant.error': 'Something went wrong. Please try again.',
    'merchant.required': 'Please fill in your business name and phone.',

    'footer.tagline': 'Save good food. Save money. Fight waste.',
    'footer.madeIn': 'Made for Uzbekistan',
    'footer.rights': 'All rights reserved.',
    'footer.eaters': 'For eaters',
    'footer.business': 'For business',
    'footer.benefits': 'Benefits',
    'footer.privacy': 'Privacy',
    'form.consent': 'By submitting, you agree to our {link}.',
    'form.consentLink': 'Privacy Policy',
    'form.captchaError': 'Verification failed. Please try again.',
  },
} as const;

export type UiKey = keyof (typeof ui)[typeof defaultLang];
