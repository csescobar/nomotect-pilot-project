# Repository Intelligence MCP Server

## Transport

The Epic 8 baseline uses newline-delimited JSON-RPC over standard input and output:

```bash
ruby bin/repository-intelligence mcp
```

Remote HTTP transport is intentionally deferred until authentication, authorization, deployment and rate-limiting contracts are approved.

## Resources

- `platform://manifest`
- `platform://graph`
- `platform://contracts`
- `platform://readiness`

## Tools

- `describe_node`: returns one allowlisted graph node by stable ID.
- `impact_analysis`: returns nodes reachable through a bounded traversal depth of at most five.
- `readiness_report`: returns current generation, contract, graph and freshness findings.

## Prompts

Every valid YAML playbook under `config/ai/playbooks` is exposed as an MCP prompt. Playbooks are descriptive and deterministic; the MCP baseline does not provide arbitrary command execution.

## Providers

The CLI supports:

```bash
CODE_GRAPH_PROVIDER=null ruby bin/repository-intelligence generate
CODE_GRAPH_PROVIDER=codebase_memory ruby bin/repository-intelligence generate
CODE_GRAPH_PROVIDER=gitnexus ruby bin/repository-intelligence generate
```

The external providers remain optional. CI uses the deterministic null provider so repository governance artifacts do not depend on third-party availability.

## Generated evidence

`ruby bin/repository-intelligence generate` writes:

- architecture manifest JSON and checksum;
- normalized repository graph JSON and checksum;
- JSON-LD graph and checksum;
- Mermaid graph;
- Graphviz DOT graph;
- normalized contracts and checksum;
- readiness report and checksum.

GitHub Actions uploads the generated directory as the `repository-intelligence` artifact.

## Safety

The server is read-only, has no arbitrary shell or evaluation tool, limits graph traversal depth, and only serves pre-registered repository knowledge. The manifest generator restricts discovery to configured roots and rejects symlink escapes.
