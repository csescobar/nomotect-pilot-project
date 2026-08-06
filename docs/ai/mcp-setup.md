# Antigravity CLI MCP Setup

## Support status

| Client | Status | Configuration |
| --- | --- | --- |
| Antigravity CLI (`agy`) | Verified target | `.agents/mcp_config.json` |
| Antigravity IDE | Unverified | No certification claim |
| Codex | Unverified | No certification claim |
| Claude Code | Unverified | No certification claim |
| Cursor | Unverified | No certification claim |
| OpenCode | Unverified | No certification claim |

`Verified target` means that this is the only client in scope for the Phase 0
operator certification. It becomes `Verified` only after the controlled
two-session journey is completed and its evidence is approved.

## Security model

The workspace configuration starts the repository-relative stdio server through
`ruby bin/nomotect-mcp`. The wrapper identifies the application by the
Repository Intelligence capability that the Application Starter preserves; it
does not inspect the repository name, owner, remote or NomoTect development
documentation. It fails closed unless `MCP_ALLOW_WRITES=false`.

The bootstrap uses the deterministic `null` code-graph provider. External graph
providers are optional and are not required to establish Repository Intelligence
access. The configuration contains no credentials and must not contain a personal
absolute path.

Do not change `MCP_ALLOW_WRITES` during an adoption journey. Generated-artifact
writes are performed explicitly before the client starts, using
`ruby bin/repository-intelligence generate`.

## Two-session protocol

### Session A — local bootstrap

Session A is limited to MCP setup. Follow `MCP_BOOTSTRAP.md` and run:

```bash
ruby bin/repository-intelligence generate
ruby bin/repository-intelligence validate
ruby bin/mcp-setup-certify
```

The certification writes machine-readable evidence to
`tmp/ci/mcp-bootstrap-certification.json`. A passing local handshake demonstrates
that the stdio server lists resources and tools, answers the required Repository
Intelligence queries and rejects generated-file writes.

After the command passes, report `RESTART_REQUIRED`, ask the operator to restart
Antigravity CLI and stop the session. A local shell invocation is not evidence
that Antigravity used MCP.

### Operator restart gate

The operator must completely exit the running Antigravity CLI process and start
a new `agy` process in the repository workspace. Reloading prompt context without
restarting the client does not satisfy the gate.

### Session B — client-use verification

Before reading the wider repository, open `/mcp` in the restarted client and
confirm that `nomotect-repository-intelligence` is connected. The agent must then
use the client-exposed MCP interface to:

1. list resources;
2. list tools;
3. read `platform://statistics`;
4. call `graph_statistics`;
5. call `describe_module` for a real module ID;
6. call `describe_contract` or `describe_playbook` for a registered ID;
7. call `impact_analysis` with depth from one through five.

The agent must record the exact server name, resource URIs, tool names, outcomes
and failures. Copying the local certification report is not client-use evidence.

## Evidence states

| State | Meaning | Discovery allowed |
| --- | --- | --- |
| `RESTART_REQUIRED` | Session A passed and the client must restart | No |
| `PASSED` | The restarted client demonstrably invoked MCP | Yes |
| `BLOCKED` | The server, resources or tools are unavailable | No |
| `FAILED` | A security or protocol requirement failed | No |
| `PROTOCOL_DEVIATION` | Discovery continued without the required proof | No MCP-assisted claim |
| `DEGRADED` | The operator explicitly authorized conventional discovery | Only with recorded authorization |

An agent must not silently select `DEGRADED`.

## Client-use evidence shape

Session B evidence must use this minimum structure:

```json
{
  "schema_version": 1,
  "client": "antigravity-cli",
  "server": "nomotect-repository-intelligence",
  "status": "PASSED",
  "writes_enabled": false,
  "resources": [],
  "tools": [],
  "invocations": [],
  "failures": [],
  "discovery_authorized": true
}
```

Each invocation records the exact operation, a non-sensitive argument summary,
the outcome and any error. Evidence must not contain credentials, personal paths
or unbounded tool output.

## Troubleshooting

- If `/mcp` does not show the server, confirm that the new `agy` process started
  in the repository workspace and loaded `.agents/mcp_config.json`.
- If the server fails to start, run `ruby bin/nomotect-mcp` from the repository root
  and resolve the reported Ruby or dependency error.
- If Repository Intelligence validation reports drift, run generation and
  validation again before restarting the client.
- If resources or tools cannot be listed, record `BLOCKED` and stop.
- If write access is enabled, record `FAILED`; do not continue.

The workspace-local configuration is authoritative for the Phase 0 Antigravity
CLI journey. Global MCP configuration must not be required.
