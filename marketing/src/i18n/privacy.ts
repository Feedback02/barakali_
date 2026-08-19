// Concise privacy content for the marketing site's lead forms. DRAFT, mirrors the
// app's not-yet-finalized legal posture. Keep in sync with the app's Privacy
// Policy at launch. No em dash (house style).
import type { Lang } from './ui';

interface PrivacySection {
  h: string;
  p: string;
}
interface PrivacyDoc {
  title: string;
  intro: string;
  sections: PrivacySection[];
  back: string;
}

export const privacy: Record<Lang, PrivacyDoc> = {
  ru: {
    title: 'Политика конфиденциальности',
    intro:
      'Эта страница объясняет, как Barakali обрабатывает данные, которые вы оставляете на этом сайте. Сейчас это сайт предзапуска со списком ожидания.',
    sections: [
      {
        h: 'Какие данные мы собираем',
        p: 'Для списка ожидания: вашу эл. почту или телефон. Для заявок бизнеса: название бизнеса, контактное лицо, телефон и данные, которые вы указываете. Ничего другого на этом сайте мы не собираем.',
      },
      {
        h: 'Зачем мы их собираем',
        p: 'Чтобы сообщить вам о запуске Barakali в вашем городе и связаться с бизнесами, заинтересованными в партнёрстве.',
      },
      {
        h: 'Правовое основание',
        p: 'Ваше согласие, которое вы даёте при отправке формы. Вы можете отозвать его в любой момент, связавшись с нами.',
      },
      {
        h: 'Сколько мы храним данные',
        p: 'До запуска и нашего первого контакта с вами, после чего мы удаляем данные, которые больше не нужны.',
      },
      {
        h: 'Передача данных',
        p: 'Мы не продаём ваши данные. Они хранятся в нашей инфраструктуре (Supabase, регион ЕС) и не передаются третьим лицам для маркетинга.',
      },
      {
        h: 'Ваши права',
        p: 'Вы можете попросить нас предоставить, исправить или удалить ваши данные. Напишите нам, и мы выполним ваш запрос.',
      },
      {
        h: 'Контакты',
        p: 'По вопросам конфиденциальности напишите на barakali.malumot@gmail.com.',
      },
    ],
    back: 'Вернуться на главную',
  },
  uz: {
    title: 'Maxfiylik siyosati',
    intro:
      "Bu sahifada Barakali ushbu saytda qoldirgan ma'lumotlaringizni qanday qayta ishlashi tushuntiriladi. Hozircha bu ro'yxatga yozilish sahifasi.",
    sections: [
      {
        h: "Qanday ma'lumot yig'amiz",
        p: "Ro'yxat uchun: emailingiz yoki telefoningiz. Biznes so'rovlari uchun: biznes nomi, aloqa shaxsi, telefon va siz ko'rsatgan ma'lumotlar. Bu saytda boshqa hech narsa yig'ilmaydi.",
      },
      {
        h: "Nega yig'amiz",
        p: "Barakali shahringizda ishga tushishi haqida xabar berish va hamkorlikdan manfaatdor bizneslar bilan bog'lanish uchun.",
      },
      {
        h: 'Huquqiy asos',
        p: "Formani yuborishda bergan roziligingiz. Uni istalgan vaqtda biz bilan bog'lanib bekor qilishingiz mumkin.",
      },
      {
        h: 'Qancha vaqt saqlaymiz',
        p: "Ishga tushirish va siz bilan birinchi aloqagacha, so'ngra keraksiz ma'lumotlarni o'chiramiz.",
      },
      {
        h: 'Ma’lumotlarni ulashish',
        p: "Biz ma'lumotlaringizni sotmaymiz. Ular bizning infratuzilmamizda (Supabase, EI mintaqasi) saqlanadi va marketing uchun uchinchi shaxslarga berilmaydi.",
      },
      {
        h: 'Huquqlaringiz',
        p: "Ma'lumotlaringizni ko'rish, tuzatish yoki o'chirishni so'rashingiz mumkin. Bizga yozing, so'rovingizni bajaramiz.",
      },
      {
        h: 'Aloqa',
        p: "Maxfiylik bo'yicha savollar uchun barakali.malumot@gmail.com ga yozing.",
      },
    ],
    back: 'Bosh sahifaga qaytish',
  },
  en: {
    title: 'Privacy Policy',
    intro:
      'This page explains how Barakali handles the information you share on this website. For now this is a pre-launch waitlist site.',
    sections: [
      {
        h: 'What we collect',
        p: 'For the waitlist: your email or phone. For business enquiries: your business name, contact name, phone, and any details you provide. We do not collect anything else on this site.',
      },
      {
        h: 'Why we collect it',
        p: 'To let you know when Barakali launches in your city, and to contact businesses interested in partnering with us.',
      },
      {
        h: 'Legal basis',
        p: 'Your consent, given when you submit a form. You can withdraw it at any time by contacting us.',
      },
      {
        h: 'How long we keep it',
        p: 'Until launch and our first contact with you, after which we remove details we no longer need.',
      },
      {
        h: 'Sharing',
        p: 'We do not sell your data. It is stored on our infrastructure (Supabase, EU region) and not shared with third parties for marketing.',
      },
      {
        h: 'Your rights',
        p: 'You can ask us to access, correct, or delete your information. Contact us and we will act on your request.',
      },
      {
        h: 'Contact',
        p: 'For privacy questions, email barakali.malumot@gmail.com.',
      },
    ],
    back: 'Back to home',
  },
};
