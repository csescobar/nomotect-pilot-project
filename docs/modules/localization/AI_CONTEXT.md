# Localization AI Context

## Owned paths

- `app/lib/localization/**`
- `app/helpers/localization_helper.rb`
- `app/controllers/locale_preferences_controller.rb`
- `app/components/ui/locale_switcher_component.rb`
- localization locale files and tests
- user locale and time-zone preference fields

## Invariants

1. Supported locales are declared only in `Localization::SupportedLocales`.
2. Request locale parameters are accepted only when registered.
3. Resolution order is supported request parameter, stored user preference, then registry default.
4. User time zone takes precedence over the locale default time zone.
5. Timestamps remain stored in UTC and are converted only for presentation.
6. Display formatting goes through `LocalizationHelper` or Rails I18n formats.
7. English uses USD by default; Brazilian Portuguese uses BRL by default.
8. Explicit currency values must not be converted implicitly.
9. Locale controls remain accessible and usable without JavaScript.
10. New locales require registry metadata, translations, formatting tests, and showcase coverage in the same change.

## Change workflow

When adding a locale, add its registry entry, locale files, currency and date/time formats, tests for request fallback and helper output, selector coverage, and a showcase verification. Do not infer locale from untrusted free-form input or pass unsupported values into `I18n.with_locale`.
