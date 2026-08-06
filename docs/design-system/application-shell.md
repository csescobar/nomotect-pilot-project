# Application Shell

The authenticated shell provides the product header, responsive sidebar, primary navigation, breadcrumbs, page heading, account context, theme selection, and main-content landmark.

## Navigation input

Callers pass authorization-filtered hashes with `label`, `href`, optional `active`, `icon`, `badge`, `children`, and `data`. The shell never performs authorization decisions.

## Accessibility

- A skip link targets `#main-content`.
- Active links expose `aria-current="page"`.
- Navigation and breadcrumbs have unique labels.
- The mobile toggle exposes `aria-expanded` and `aria-controls`.
- Escape closes the enhanced drawer and focus returns to the toggle.
- Without JavaScript, navigation remains visible and usable.

## Responsive behavior

At desktop widths the sidebar participates in a two-column layout. At mobile widths it becomes an overlay drawer when Stimulus connects. Theme and account actions remain available in the header.

## Extension rules

Global search, notifications, tenant switching, persisted collapsed state, and customizable navigation are separate features. New shell capabilities must preserve semantic landmarks and remain token-driven.
