# Localization and Formatting Foundation

## Supported locales

`Localization::SupportedLocales` is the canonical registry. Each entry defines a locale code, human label, default currency, and default time zone. The initial supported locales are English (`en`) and Brazilian Portuguese (`pt-BR`).

## Request resolution

Requests resolve localization in this order:

1. a supported `locale` request parameter;
2. the authenticated user's stored locale;
3. the registry default.

Unsupported parameters never reach `I18n.with_locale`. Time rendering uses the user's stored time zone, falling back to the resolved locale's default zone.

## User preference

Authenticated users update their locale through `PATCH /locale_preference`. The preferences page renders `Ui::LocaleSwitcherComponent`, which submits automatically when JavaScript is available and includes a submit button inside `noscript` as a progressive-enhancement fallback.

## Formatting helpers

Use `LocalizationHelper` instead of hand-built format strings:

- `format_local_date`
- `format_local_time`
- `format_local_number`
- `format_local_percentage`
- `format_local_currency`

English currency defaults to USD and Brazilian Portuguese currency defaults to BRL. Explicit currencies remain supported through the `currency:` argument.

Formatting follows the presentation context:

- grids and dense data lists use compact localized date and datetime formats;
- details and narrative content use long localized formats;
- CSV exports and APIs use stable machine-readable values, including ISO 8601 dates and timestamps.

Grid columns derive formatting from their declared type. Do not infer a formatter from a column name or duplicate locale-specific format strings in a renderer.

## Boundaries

Store timestamps in UTC. Localize only at presentation boundaries. Domain objects and persistence code must not embed locale-specific number, date, currency, or time-zone formatting.
