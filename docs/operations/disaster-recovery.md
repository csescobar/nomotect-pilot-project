# Disaster Recovery

NomoTect requires each installation to declare its own recovery objectives.
The example policy is guidance, not a platform SLA. Recovery remains
operator-controlled: preserve evidence, enable maintenance, verify backup
identity and checksums, execute the approved restore plan, inspect operational
health, obtain human approval, and only then return to service.

Required scenarios cover restart, node replacement, database and persistent
storage loss, configuration loss, degraded jobs and integrations, partial
restore failure, and complete environment loss. Raw credentials never belong in
the policy or evidence. A failed required health signal keeps maintenance active.

After recovery, record actual RTO/RPO, generate a redacted support bundle,
preserve certification evidence, and update the runbook before the next drill.
