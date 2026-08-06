# Design System Component Contract

## Purpose

Define the stable public API and implementation rules for reusable UI components.

## Public API

Components live under `Ui`, inherit from `Ui::BaseComponent`, and expose explicit keyword arguments. Visible strings are supplied by callers through Rails I18n. Components that render block content use the standard ViewComponent block API.

## Variants and sizes

Supported variants and sizes are declared as frozen constants. Unsupported values raise `ArgumentError`; components must not silently fall back to another visual or behavioral state.

## HTML attributes

Public components accept `html_options:`. The base component merges:

- CSS classes without duplicates;
- `data-*` attributes;
- `aria-*` attributes;
- standard HTML attributes such as `id`, `title`, and `tabindex`.

Component-owned accessibility attributes provide defaults, while explicit caller attributes may refine them.

## Styling

Components consume semantic CSS custom properties generated from `config/design_tokens`. Hard-coded brand colors, tenant-specific branding, and direct edits to generated token CSS are prohibited.

CSS class names follow a stable `ui-<component>` convention with `--<variant>` and `--<size>` modifiers.

## Accessibility

- Interactive components preserve visible focus indicators.
- Disabled links are removed from keyboard navigation and expose `aria-disabled`.
- Danger alerts use `role="alert"`; non-urgent alerts use `role="status"`.
- Dividers expose separator role and orientation.
- Empty states connect their heading through `aria-labelledby`.

## Testing

Tests cover public variants, rejected invalid values, merged HTML attributes, block content, and accessibility semantics. Components must render correctly in light and dark themes without component-specific theme overrides.

## Extension points

New components may extend the base helpers for validation, class composition, and HTML option merging. Changes to existing initializer keywords or rendered accessibility semantics require an ADR or RFC when they are breaking.
