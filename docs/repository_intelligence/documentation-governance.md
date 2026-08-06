# Documentation Governance

Repository Intelligence treats essential operational documentation as governed
platform evidence. The machine-readable catalog at
`config/ai/documentation.yml` connects each guide to:

- one or more accountable GitHub owners;
- a review deadline;
- the module contracts it explains;
- source files that can make the guide obsolete.

The documentation-governance validator fails closed when a guide or source is
missing, a contract identifier is unknown, ownership is absent, paths escape the
repository or the review deadline has passed. The validator participates in the
Repository Intelligence readiness report and health dashboard, so CI blocks
stale operational documentation.

Reviewing a guide means comparing it with every listed source, updating the text
where required and moving `review_by` to an explicitly approved date. Extending
the deadline without review does not satisfy the governance intent.

GitHub review routing is enforced independently by `.github/CODEOWNERS`.
The catalog records semantic responsibility; CODEOWNERS requests the responsible
reviewer when governed files change.
