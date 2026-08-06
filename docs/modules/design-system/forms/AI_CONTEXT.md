# Design System Forms AI Context

## Purpose

This module provides the stable Rails form integration contract for platform and domain features.

## Boundaries

- `Ui::FormBuilder` may inspect Rails model naming, attributes, and validation errors.
- Components under `Ui::Forms` own HTML structure and accessibility semantics.
- Domain-specific validation and business rules remain outside the design system.

## Invariants

1. Help text and validation errors are programmatically associated with their controls.
2. Invalid controls expose `aria-invalid`.
3. Labels, legends, and error summaries remain available without JavaScript.
4. Visible application text is localizable.
5. Components consume semantic design tokens.
6. Custom classes, data attributes, ARIA attributes, and standard Rails input options remain supported.
7. New field types reuse the shared presentation contract.

## Review boundaries

Changes require focused review when they alter generated IDs, label associations, error semantics, required-field behavior, checkbox/radio markup, or the public builder method signatures.

## Prohibited changes

- Hard-coded consumer branding or colors.
- Removing native form semantics in favor of JavaScript-only behavior.
- Rendering model errors without an accessible association.
- Silently swallowing unsupported options.
- Coupling form components to a business-domain model.

## Known limitations

This foundation does not yet provide autocomplete, multiselect, file upload, rich text, date-range selection, nested dynamic forms, or client-side validation orchestration.
