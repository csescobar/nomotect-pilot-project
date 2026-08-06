# Design System AI Context

## Purpose

Provide machine-readable guidance for humans and AI agents changing reusable UI components.

## Module boundary

Owned paths:

- `app/components/ui/**`
- design-system styles in `app/assets/stylesheets/application.css`
- component tests under `test/components/ui/**`
- `docs/design-system/**`

The canonical design token source remains under `config/design_tokens/**` and is governed by ADR-0012.

## Invariants

1. Public components inherit from `Ui::BaseComponent`.
2. Variants and sizes are explicit, documented, and validated.
3. Invalid public values raise clear errors.
4. Visible copy is supplied by callers and should normally originate from Rails I18n.
5. Styles consume semantic design tokens rather than hard-coded brand colors.
6. Components accept and safely merge standard, `data-*`, and `aria-*` attributes.
7. Accessibility semantics are part of the public contract and require tests.
8. Core server-rendered behavior must remain useful without JavaScript.
9. Public theme selection is limited to explicit Light and Dark choices.
10. Non-generated stylesheets must pass `bin/design-token-audit` and must not
    contain color literals.

## Current components

- `Ui::ButtonComponent`
- `Ui::CardComponent`
- `Ui::BadgeComponent`
- `Ui::AlertComponent`
- `Ui::DividerComponent`
- `Ui::EmptyStateComponent`
- `Ui::ThemeSwitcherComponent`

## Review checklist

- Does the initializer remain backward compatible?
- Are all variants and sizes covered by tests?
- Are classes based on semantic tokens?
- Are keyboard, focus, role, and ARIA behaviors correct?
- Do custom HTML attributes merge without removing component defaults?
- Does the component render in both light and dark themes?
- Is visible text localizable?

## Prohibited changes

- Silent variant fallbacks.
- Consumer-specific branding in core components.
- Inline style attributes for normal component presentation.
- JavaScript-only rendering for core content.
- Editing generated design token CSS without updating the canonical JSON source.
- Adding color literals to component or page stylesheets instead of extending
  the canonical semantic-token vocabulary.

## Known limitations

This slice does not yet provide component previews, visual regression testing, icons, form controls, complex overlays, or a public showcase. Those belong to subsequent Epic 2 pull requests.
