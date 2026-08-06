# Component Showcase AI Context

## Owned paths

- `app/controllers/component_showcase_controller.rb`
- `app/views/component_showcase/**`
- showcase styles in `app/assets/stylesheets/application.css`
- `lib/accessibility/html_audit.rb`
- showcase and audit tests
- showcase locale files

## Invariants

1. The showcase renders production components, not duplicated mock markup.
2. Every public component family has a representative state.
3. New variants are added to the showcase in the same change that introduces them.
4. Showcase copy is localized in English and Brazilian Portuguese.
5. The rendered page must pass `Accessibility::HtmlAudit`.
6. Audit failures must be fixed in component markup unless the audit rule is demonstrably incorrect.
7. The audit does not replace manual keyboard, screen-reader, responsive, or contrast review.
8. Showcase styling consumes semantic tokens and remains valid in light and dark themes.

## Accessibility audit boundary

The audit checks structural HTML guarantees that can be evaluated deterministically without a browser. Do not add speculative visual checks to this class. Browser-dependent checks belong in system tests or manual review.

## Extension workflow

When adding a component or state:

1. render a representative localized example;
2. preserve a logical heading hierarchy;
3. ensure IDs remain unique across the complete page;
4. run lint, tests, and the showcase integration audit;
5. review keyboard behavior and both themes manually.
