import { defaultLang, ui, type Lang, type UiKey } from './ui';

/// Returns a translator bound to `lang`, falling back to the default language for
/// any key missing in that locale.
export function useTranslations(lang: Lang) {
  return function t(key: UiKey): string {
    return ui[lang][key] ?? ui[defaultLang][key];
  };
}

/// Narrows Astro.currentLocale (string | undefined) to a known Lang.
export function asLang(value: string | undefined): Lang {
  return value === 'uz' || value === 'en' ? value : defaultLang;
}

/// Root path for each locale's single landing page (ru serves from /).
export const localeHome: Record<Lang, string> = {
  ru: '/',
  uz: '/uz/',
  en: '/en/',
};
