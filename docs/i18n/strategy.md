# Internationalization Strategy

## Initial locales

- `pt-BR`
- `en`

## Principles

- No user-facing hard-coded text in reusable components.
- Locale is represented in URLs where practical.
- User preference overrides tenant preference, which overrides the platform default.
- Dates, times, numbers, currencies, validation messages and grid operators are localized.
- Date-only fields must not be converted through time zones.
- Missing translations fail tests.

## Structure

```text
config/locales/
├── pt-BR/
│   ├── application.yml
│   ├── activerecord.yml
│   ├── components.yml
│   ├── grid.yml
│   └── errors.yml
└── en/
    ├── application.yml
    ├── activerecord.yml
    ├── components.yml
    ├── grid.yml
    └── errors.yml
```

## Locale resolution

1. Explicit URL locale
2. Authenticated user preference
3. Tenant preference
4. Application default

## Testing

The CI pipeline will detect missing translations, invalid interpolation placeholders and locale-specific rendering regressions.
