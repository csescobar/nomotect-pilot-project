# NomoTect MCP-first Bootstrap

Stop broad repository discovery until this bootstrap has completed.

This entrypoint is for an unfamiliar AI agent beginning an Application Starter
adoption journey with Antigravity CLI (`agy`). During Session A, inspect only this file,
`.agents/mcp_config.json`, `docs/ai/mcp-setup.md`, and the commands they name.

## Session A — configure and stop

1. Confirm that Git, Ruby and Bundler are available. Bash is not required by the
   MCP bootstrap on Windows.
2. Run `bundle install` if the repository dependencies are not installed.
3. Run `ruby bin/repository-intelligence generate`.
4. Run `ruby bin/repository-intelligence validate`.
5. Confirm that `.agents/mcp_config.json` exists and sets
   `MCP_ALLOW_WRITES=false`.
6. Run `ruby bin/mcp-setup-certify`.
7. Report the result and ask the operator to exit and restart Antigravity CLI.
8. Stop. Do not continue repository discovery in the current process.

The local handshake proves that the server works. It does not prove that the
active AI client discovered or used the server.

## Operator gate

Completely exit the active `agy` process and start a new Antigravity CLI process
in this workspace. Configuration changes do not dynamically enable MCP tools in
an already-running process.

## Session B — prove client use before discovery

In the restarted Antigravity CLI process:

1. Open `/mcp` and confirm that `nomotect-repository-intelligence` is connected.
2. List the NomoTect resources and tools visible to the client.
3. Read repository statistics.
4. Invoke `graph_statistics`.
5. Invoke `describe_module` for one returned module.
6. Invoke `describe_contract` or `describe_playbook` for one registered item.
7. Invoke `impact_analysis` with a bounded depth.
8. Record the exact tool names, outcomes and failures as described in
   `docs/ai/mcp-setup.md`.

Only after these steps pass may broad repository discovery begin. If the server,
resources or tools are absent, mark the bootstrap `BLOCKED` and stop. Continuing
without MCP is a protocol deviation and must not be described as MCP-assisted
adoption.
