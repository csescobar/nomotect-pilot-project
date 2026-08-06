# Executable playbooks

Epic 8 playbooks are declarative, versioned orchestration contracts executed only through the public `RepositoryIntelligence` façade.

## Security boundary

A playbook cannot run arbitrary Ruby, shell commands, SQL, network requests, or unrestricted file operations. Every step must reference an allowlisted operation such as `repository.search`, `repository.validate`, or `repository.readiness`.

## Step contract

```yaml
- id: validation
  tool: repository.validate
  args: {}
  timeout_seconds: 30
  retry: 1
  on_failure: stop
```

Inputs can be referenced with placeholders such as `{{inputs.target}}`. Step outputs are retained in the execution context and structured evidence report.

## Completion gates

Supported gates are:

- `all_steps_pass`
- `validation_passes`
- `repository_ready`

## CLI

```bash
ruby bin/repository-intelligence playbook list
ruby bin/repository-intelligence playbook validate repository-readiness
ruby bin/repository-intelligence playbook execute repository-readiness '{}'
ruby bin/repository-intelligence playbook status EXECUTION_ID
```

## MCP

The MCP adapter exposes `validate_playbook`, `execute_playbook`, and `playbook_status`. Executions publish lifecycle events for start, step start, step completion, step failure, final failure, and final completion.
