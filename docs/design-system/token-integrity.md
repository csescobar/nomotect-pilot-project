# Design-token integrity

NomoTect treats token substitution as an architecture contract, not only as a
theme feature. Application surfaces must inherit presentation decisions from
`config/design_tokens/tokens.yml` through generated CSS custom properties.

## Public theme contract

The runtime supports two explicit themes: Light and Dark. Light is the default
when no valid stored choice exists. Operating-system preference does not create
a third public mode.

## Token layers

- Base tokens define typography, spacing, radius, shadow, control size and
  motion primitives shared by both themes.
- Theme tokens define semantic colors for Light and Dark.
- Fixed-canvas tokens describe deliberately dark illustrations, terminal
  previews and window controls. They are still tokens so an application can
  replace the complete visual language without editing component CSS.

The canonical YAML remains a flat map for installer and customization-file
compatibility. Commented sections group related roles for authors. Token names
describe purpose (`accent.primary`, `feedback`, `fixed-canvas`) and never a
specific palette color such as blue or teal.

## Enforcement

Run:

```bash
bin/rails design_tokens:check
ruby bin/design-token-audit
```

The first command proves that committed generated artifacts match the canonical
YAML. The second rejects hexadecimal, RGB and HSL color literals in all
non-generated stylesheets.

If a component needs a visual value that does not have a suitable token, extend
the semantic vocabulary in `tokens.yml`, generate the artifacts and document
the new role. Do not add a local literal or a fallback palette value.

## Certification substitution

Visual certification uses a temporary, deliberately different token set. It
must alter at least primary and semantic colors, typography, radius, spacing,
shadow and control height. The substituted build is evidence-only and does not
add a third selectable theme.

Review the following representative surfaces in both public themes:

- authenticated application shell;
- installation workflow;
- Component Showcase;
- public marketing pages;
- default Grid Engine composition.

Any element that retains the default presentation requires either a missing
semantic token or a documented fixed-canvas decision. Certification fails if
application-specific CSS is required to repair the substituted build.
