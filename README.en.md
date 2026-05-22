# Legacy System Modernization with GitHub Copilot

**Multi-technology template** for modernizing legacy applications with GitHub Copilot assistance. Covers the full cycle: business case, assessment, planning, scope refinement, modernization strategy, execution, testing, and cloud architecture. Built from real-world migrations in banking, government, and telco in LATAM.

> Today with complete coverage for **Visual Basic 6 / VB.NET** and **.NET Framework 2.0–4.8**. Placeholders for **COBOL, Java legacy, and Python**, extensible to other technologies without breaking the methodology.
>
> **Spanish version (primary):** [README.md](README.md)

---

## Complete modernization flow (7 phases)

```
[Phase 0]         [Phase 1]         [Phase 2]         [Phase 2.5]       [Phase 3]         [Phase 4]         [Phase 5]         [Phase 6]
Business      →   Technical     →   Architecture  →   Plan          →   Modernization →   Execution     →   Testing &     →   Cloud
Case              Assessment        Planning          Refinement        Strategy          (build)           QA                Deployment
                                                      (scope)           (6R + path)                         (parity)
```

| Phase | Agent | Main deliverable |
| --- | --- | --- |
| **0. Business Case** | `business-case-analyst`, `security-assessor` | `assessment/{Project}/` (TCO, ROI, risk, security) |
| **1. Technical Assessment** | `vb-assessment` or `dotnet-assessment` | `docs/features/` (rules, dependencies, blockers) |
| **2. Planning** | `vb-planning` or `dotnet-planning` | `docs/ARQUITECTURA-TARGET.md` + ADRs |
| **2.5. Plan Refinement** | `plan-refiner` | `docs/MIGRATION-SCOPE.md` (scope agreed with client) |
| **3. Modernization Strategy** | `modernization-strategy` | `docs/MODERNIZATION-PATH.md` (6R + path) |
| **4. Execution** | `vb-migration` or `dotnet-migration` | Code in `src/` with functional parity |
| **5. Testing & QA** | `migration-tester` | `testing/parity-report.md`, coverage, gaps |
| **6. Cloud Deployment** | `cloud-architect` or `azure-architect` | `cloud-architectures/<provider>/` + IaC |

Methodology details in [`docs/methodology/00-overview.md`](docs/methodology/00-overview.md).

---

## Supported legacy technologies

| Technology | Status | Technical agents |
| --- | --- | --- |
| Visual Basic 6 / VB.NET legacy | Complete and validated | `vb-assessment` · `vb-planning` · `vb-migration` |
| .NET Framework 2.0–4.8 | Complete | `dotnet-assessment` · `dotnet-planning` · `dotnet-migration` |
| COBOL (z/OS, distributed) | Placeholder | Create from `.github/agents/_templates/` |
| Java legacy (J2EE, Java 6/7/8) | Placeholder | Create from `.github/agents/_templates/` |
| Python 2 / legacy 3 | Placeholder | Create from `.github/agents/_templates/` |

To add a technology, see [`docs/technologies/README.md`](docs/technologies/README.md).

---

## How to use the template

### 1. Clone

```bash
git clone https://github.com/armandoblanco/legacy-modernization-playbook.git my-project
cd my-project
rm -rf .git && git init
```

### 2. Interactive bootstrap

```bash
./bootstrap.sh       # Linux/macOS/WSL
.\bootstrap.ps1      # Windows
```

The bootstrap asks for project, client, legacy technology, target stack, and cloud, then:

- Replaces placeholders (`{{ProjectName}}`, etc.) in all `.md` files.
- **Copies the chosen technology's agents + shared agents to `.github/agents/` flat** (see technical note below).
- Generates `.copilot-project.yml` with your configuration.
- Creates working folders: `legacy/`, `src/`, `assessment/{ProjectName}/`, `testing/`.
- Generates `NEXT-STEPS.md` with a flow personalized for your tech/stack.

**The bootstrap does NOT self-delete.** You can re-run it to change tech/stack/cloud without losing work. Previous choices are overwritten.

> **Important technical note: agent discovery in `.github/agents/`**
>
> GitHub Copilot **does not discover agents in subfolders** of `.github/agents/`. It only reads `.agent.md` files directly in `.github/agents/`. Known behavior (open issues in `github/copilot-cli` #2245, #1859, #1506).
>
> This template keeps agents organized by category in subfolders (`shared/`, `vb/`, `dotnet-framework/`) as **source of truth**. The `bootstrap` copies the ones applying to your project to the flat level. Don't edit the copies in `.github/agents/*.agent.md` directly — edit the sources in subfolders and re-run the bootstrap.

### 3. Load legacy code

```bash
mkdir -p legacy/
cp -r /path/to/legacy-code/* legacy/
```

### 4. Open VS Code

```bash
code .
```

In Copilot Chat, verify the agents appear. **How to invoke them depends on the environment:**

| Environment | How to invoke |
| --- | --- |
| VS Code (Copilot Chat) | Click the **agent picker dropdown** and select the agent. `@name` only works for built-in agents like `@workspace`. |
| Visual Studio 2026 (18.4+) | `@name` directly in the chat input |
| GitHub Copilot CLI | `/agent <name>` or `--agent` argument |
| GitHub.com (Copilot cloud agent) | Dropdown in the Agents page |

If agents don't appear: `Cmd/Ctrl+Shift+P` → "Developer: Reload Window".

### 5. Run the flow

Follow `NEXT-STEPS.md` generated by the bootstrap, or check `docs/methodology/00-overview.md`.

---

## Included agents

### Shared (any technology) — `.github/agents/shared/`

- `business-case-analyst` — Phase 0. TCO, ROI, risk, executive.
- `security-assessor` — Phase 0. Whitehat security analysis over `legacy/`.
- `modernization-strategy` — Phase 3. **New.** Gartner's 6 R's + Windows desktop sub-flow (desktop/web, containers, Kubernetes).
- `plan-refiner` — Phase 2.5. **New.** Refines scope with the user: discarded features, gaps, modified rules.
- `migration-tester` — Phase 5. **New.** Systematic parity tests + coverage + report.
- `cloud-architect` — Phase 6. Multi-provider cloud architecture with ADRs.
- `azure-architect` — Phase 6. Azure-specific: Mermaid + prices validated with Retail Prices API.

### Technology-specific

- **VB** (`.github/agents/vb/`): `vb-assessment` · `vb-planning` · `vb-migration`
- **.NET Framework** (`.github/agents/dotnet-framework/`): `dotnet-assessment` · `dotnet-planning` · `dotnet-migration`
- Other technologies: use templates in `.github/agents/_templates/`.

### Suggested models

| Task type | Model | Why |
| --- | --- | --- |
| Assessment, business case, planning, strategy, refinement | Claude Opus 4.6 | Deep reasoning + trade-offs |
| Migration (code refactor) | Claude Sonnet 4.6 | Speed + iterative precision |
| Testing | Claude Sonnet 4.6 | Mass test generation |
| Security assessment, cloud architecture | Claude Opus 4.6 | Adversarial analysis |

Override in `.copilot-project.yml` or in the agent's frontmatter.

---

## Philosophy

- **7 phases in strict order.** Each phase produces input for the next. Skipping generates predictable rework.
- **Plan Refinement (2.5) is mandatory.** The plan generated by `vb-planning` / `dotnet-planning` almost always has gaps that only the user working with the client can resolve. Skipping it means migrating dead code.
- **Modernization Strategy is conscious decision, not default.** Each system requires its 6R recommendation. Not everything gets Refactored. Not everything goes to Kubernetes.
- **Testing is explicit phase, not appendix of Execution.** Has its agent, coverage targets, and parity report.
- **Technology-agnostic at core.** The what, when, and why are the same for VB, COBOL, Java, or Python; the tactical how changes.
- **Every architectural decision is an ADR.** Without ADR, the decision doesn't exist later.
- **Legacy code is the source of truth.** Documentation and team memory are approximations.
- **Copilot accelerates, doesn't replace.** The agent proposes; the human decides.

---

## What this template is NOT

- **Not a promise of automatic migration.** Systems with proprietary OCX, mainframe dependencies, or hidden logic in DB require human decisions documented in ADR.
- **Not a syntax converter.** For 1:1 line-by-line conversion there are cheaper, more specific commercial tools.
- **Doesn't include legacy code samples.** Client code goes in `legacy/`.
- **Doesn't estimate project duration.** Estimation happens in commercial proposal, outside methodology's scope.
- **Doesn't sell cloud or Kubernetes.** The `modernization-strategy` agent decides if and where containerization makes sense, based on objective criteria.

---

## Local validation before client use

Before using the template with a real client, run the checklist:

```bash
cat VALIDATION-CHECKLIST.md
```

Covers: functional bootstrap on Linux/Mac/Windows, agents discoverable by Copilot, sanity check of each new agent, execution of an end-to-end cycle with sample code.

---

## License

MIT — use freely, attribute if you want.
