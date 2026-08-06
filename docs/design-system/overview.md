# Design System Overview

## Goals

- Provide reusable, accessible and themeable UI components.
- Keep visual styling independent from domain behavior.
- Support explicit light and dark themes.
- Allow applications to replace branding through design tokens.
- Document every component in a built-in showcase.

## Component families

### Foundations

Color, typography, spacing, radius, shadow, density, motion and icons.

### Inputs

Text, email, password, number, currency, percentage, textarea, select, multiselect, checkbox, radio, date, datetime, file, search and autocomplete.

### Data display

Cards, badges, metrics, tables, grids, lists, timelines and empty states.

### Feedback

Alerts, toasts, loading states, progress, validation messages and error boundaries.

### Navigation

Application shell, sidebar, breadcrumbs, tabs, pagination and command/search interface.

## Component contract

Every component must define:

- Public parameters
- Variants and states
- Accessibility behavior
- Theme behavior
- Responsive behavior
- i18n keys
- Test coverage
- Showcase examples

## Theming

The design token source is `config/design_system/theme.json`. Runtime components consume generated CSS variables only.
