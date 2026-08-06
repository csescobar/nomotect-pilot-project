# Backup Evidence and Maintenance Controls

PR #52 verifies operator-provided evidence; it does not create database or file backups.

Backup evidence is a versioned, credential-free record for either `database` or
`persistent_files`. Each record identifies when it was captured and the exact
platform version, database schema and installation contract it protects. The
baseline rejects missing evidence, evidence older than 24 hours and evidence
captured from a different source state.

Maintenance mode is explicit:

```bash
bin/upgrade-maintenance enable
bin/upgrade-maintenance status
bin/upgrade-maintenance disable
```

The execution safety gate cannot authorize a future upgrade unless preflight has
no blockers, both backup kinds are valid, maintenance mode is active, and active
request and job counts are zero. Queue and request counters are adapter inputs;
provider-specific draining integrations remain optional follow-up work.

Evidence contains references and optional checksums, never provider credentials,
database URLs, passwords, tokens or private keys.
