# Design System Layout AI Context

## Owned paths

- `app/components/ui/layout/**`
- `app/javascript/controllers/navigation_drawer_controller.js`
- shell styles in `app/assets/stylesheets/application.css`
- layout translations and tests

## Invariants

1. The caller filters navigation by authorization before rendering.
2. The shell owns semantic landmarks and the `#main-content` target.
3. Active navigation uses `aria-current="page"`.
4. JavaScript progressively enhances mobile navigation; core links remain available without it.
5. Escape closes the drawer and focus returns to the toggle.
6. Components consume semantic design tokens.
7. Visible strings originate from Rails I18n or caller-supplied translated content.
8. Nested navigation remains valid list markup.

## Review checklist

- Verify unique landmark labels and IDs.
- Test active, nested, empty, and anonymous account states.
- Confirm arbitrary HTML attributes are merged safely.
- Confirm desktop and mobile behavior in both themes.
- Keep search, notifications, tenant switching, and persisted collapse state outside this module until separately designed.
