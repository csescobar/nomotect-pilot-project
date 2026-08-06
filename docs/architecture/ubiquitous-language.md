# Ubiquitous Language

## Purpose

Establish consistent architectural terminology for human and AI contributors.

## Terms

- **Platform:** The reusable foundation delivered by this repository.
- **Capability:** A user or engineering outcome provided by one or more modules.
- **Module:** A cohesive architectural boundary with owned behavior, data and contracts.
- **Contract:** A documented public interface, invariant or exchange format relied upon outside its owner.
- **Operation:** An application-level command that coordinates a state-changing use case.
- **Query:** A side-effect-free read model or retrieval operation.
- **Policy:** A decision object that determines whether an action is allowed or applicable.
- **Aggregate:** A consistency boundary whose root protects domain invariants.
- **Domain event:** A durable statement that a meaningful business fact occurred.
- **Adapter:** Technology-specific implementation of a platform or domain port.
- **Grid:** The platform subsystem for declarative columns, validated queries, presentation adapters and exports.
- **Grid type:** A semantic data definition that provides operators, parser, formatter and filter editor defaults.
- **Operator:** A validated filter behavior compiled by a trusted server adapter.
- **Design token:** A named visual decision compiled into runtime styling variables.
- **AI context:** Repository-native module guidance describing purpose, invariants, boundaries and workflows.
- **Architecture manifest:** Machine-readable representation of modules and permitted dependencies.
- **Playbook:** A vendor-neutral sequence for completing a recurring engineering task.
- **Community core:** Apache-licensed capabilities in this repository.
- **Enterprise extension:** Commercial capabilities maintained separately without weakening the community core.