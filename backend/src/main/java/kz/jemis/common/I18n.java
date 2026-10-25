package kz.jemis.common;

import java.util.Locale;
import org.springframework.context.i18n.LocaleContextHolder;

public final class I18n {
    private I18n() {}

    /** Current request language: ru, kk or en (ru by default). */
    public static String lang() {
        String l = LocaleContextHolder.getLocale().getLanguage();
        return switch (l) { case "kk", "en" -> l; default -> "ru"; };
    }

    public static String pick(String lang, String ru, String kk, String en) {
        String v = switch (lang) { case "kk" -> kk; case "en" -> en; default -> ru; };
        return v != null && !v.isBlank() ? v : ru;
    }

    public static String lang(Locale locale) {
        String l = locale.getLanguage();
        return switch (l) { case "kk", "en" -> l; default -> "ru"; };
    }
}
