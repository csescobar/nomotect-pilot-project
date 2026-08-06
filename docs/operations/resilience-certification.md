# Operational Resilience Certification

The Phase 7 certification runs eight production-like scenarios inside a
temporary fixture: application restart, node replacement, backup and restore
certification, degraded jobs and integrations, storage degradation, and partial
restore failure. Fault injection is rejected outside the fixture and never runs
against a production environment.

Each scenario records stable, redacted initial, fault and final health evidence.
The disaster-recovery policy must be ready before execution. A failed or blocked
scenario prevents certification.

Run the focused matrix with:

```bash
ruby bin/operational-resilience-certify
```
