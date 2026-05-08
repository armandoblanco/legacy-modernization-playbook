# Legacy modernization with GitHub Copilot

**Multi-technology** repository template for modernizing legacy applications with GitHub Copilot, covering the full lifecycle: business case, assessment, planning, migration execution, and target cloud architecture. Built from real banking, government, and telco migrations in Latin America.

> Currently with **full coverage for Visual Basic 6 / VB.NET** and **.NET Framework 2.0–4.8**, plus placeholders for **COBOL, legacy Java, and Python**. Designed to be extended to other stacks without breaking the methodology.
>
> **Spanish version (primary):** [README.md](README.md)

---

## Five-phase methodology

```
[Phase 0]            [Phase 1]            [Phase 2]            [Phase 3]            [Phase 4]
Business Case   →    Assessment       →   Planning         →   Execution        →   Cloud Deployment
   (worth it?)         (what's there?)     (where to?)         (build it)           (where does it run?)
```

| Phase | Question | Deliverable | Copilot agent |
| --- | --- | --- | --- |
| **0. Business Case** | Is modernizing worth it? | `assessment/{ProjectName}/` (TCO, ROI, risk, exec, security) | `@business-case-analyst`, `@security-assessor` |
| **1. Assessment** | What does the legacy have? | `docs/features/` | `@<tech>-assessment` |
| **2. Planning** | Which target stack and why? | `docs/ARQUITECTURA-TARGET.md` + ADRs | `@<tech>-planning` |
| **3. Execution** | How to build it? | `migrated/` with parity | `@<tech>-migration` |
| **4. Cloud Deployment** | Where and under which architecture? | `cloud-architectures/<provider>/` + IaC | `@cloud-architect` |

Methodology details in [`docs/methodology/00-overview.md`](docs/methodology/00-overview.md).

---

## Supported legacy technologies

| Technology | Status | Reference folder |
| --- | --- | --- |
| **Visual Basic** (VB6 + VB.NET legacy) | Complete and validated | [`docs/technologies/vb/`](docs/technologies/vb/) |
| **.NET Framework 2.0–4.8** | ✅ Complete (`@dotnet-assessment` / `@dotnet-planning` / `@dotnet-migration`) | [`docs/technologies/dotnet-framework/`](docs/technologies/dotnet-framework/) |
| **COBOL** (z/OS, distributed) | Placeholder | [`docs/technologies/cobol/`](docs/technologies/cobol/) |
| **Legacy Java** (J2EE, Java 6/7/8) | Placeholder | [`docs/technologies/java/`](docs/technologies/java/) |
| **Python 2 / old Python 3** | Placeholder | [`docs/technologies/python/`](docs/technologies/python/) |

To add a new technology see [`docs/technologies/README.md`](docs/technologies/README.md).

---

## How to use this template

### Step 1 — Clone

```bash
git clone https://github.com/<org>/modernizacion-legacy-copilot.git my-project
cd my-project
rm -rf .git && git init
```

### Step 2 — Interactive bootstrap

```bash
./bootstrap.sh        # Linux/macOS/WSL
.\bootstrap.ps1       # Windows
```

It will ask:

- Project and client name
- Legacy technology (`vb`, `dotnet-framework`, `cobol`, `java`, `python`, `other`)
- If you picked VB: sub-language (`vb6`/`vbnet`) and target stack (`winforms`/`wpf`/`blazor`)
- Target cloud provider (`azure`/`aws`/`gcp`/`on-premise`/`undecided`)

It will:

- Replace placeholders (`{{ProjectName}}`, `{{ClientName}}`, `{{LegacyTech}}`, `{{TargetStack}}`, `{{CloudProvider}}`)
- (Optional) Delete folders for the technologies and cloud providers you didn't pick
- Generate `.copilot-project.yml`

### Step 3 — (Recommended) Build the Business Case first

```text
@business-case-analyst Build the business case for my project
```

The agent interviews, estimates with justified ranges, and fills the 4 deliverables in [`assessment/{ProjectName}/`](assessment/) (MD + self-contained HTML).

Then the whitehat security assessment:

```text
@security-assessor Review security of code in legacy/
```

Generates `seguridad-DDMMYYYY.md` and `.html` in the same project folder.

### Step 4 — Load legacy code

```bash
mkdir -p legacy/
cp -r /path/to/legacy-code/* legacy/
```

### Step 5 — Start Phase 1 (Assessment)

For VB:

```text
@vb-assessment Analyze the system in legacy/
```

For other technologies the agents are still placeholders — use the templates in [`.github/agents/_templates/`](.github/agents/_templates/) to create them.

### Step 6 — Continue with Planning, Execution and Cloud

```text
@vb-planning            (Phase 2)
@vb-migration           (Phase 3)
@cloud-architect        (Phase 4)
```

---

## Repo structure

```
modernizacion-legacy-copilot/
├── README.md / README.en.md
├── bootstrap.sh / bootstrap.ps1
├── docs/
│   ├── methodology/                    Tech-agnostic methodology (5 phases)
│   ├── shared/                         Lessons, anti-patterns (cross-cutting)
│   └── technologies/
│       ├── vb/                         Full coverage
│       ├── dotnet-framework/ cobol/ java/ python/   Placeholders
├── assessment/                          Phase 0 outputs (per project + templates)
│   ├── _templates/                      tco-actual, roi, risk, exec, security
│   └── {ProjectName}/                   {category}-DDMMYYYY.{md,html}
├── scripts/                             md2html.{sh,py} (offline HTML)
├── cloud-architectures/                Phase 4
│   ├── azure/                          5 documented patterns
│   ├── aws/ gcp/ on-premise/           Placeholders
│   └── _templates/                     Cloud ADR template
├── .github/
│   ├── agents/{shared, vb, _templates}
│   ├── instructions/{vb-target, _templates}
│   └── prompts/{shared, vb}
├── workshop/{shared, vb}
└── legacy/                             (empty) client code goes here
```

---

## Philosophy

- **5 phases in strict order.** Each phase produces the input for the next. Skipping phases generates predictable rework.
- **Tech-agnostic at the core.** What, when and why are the same for VB, COBOL, Java or Python; only the tactical how changes.
- **Every decision is an ADR.** Without an ADR the decision doesn't exist 6 months later.
- **Legacy code is the source of truth.** Documentation and team memory are approximations.
- **Copilot accelerates, it doesn't replace.** The agent proposes; the human decides.

---

## What this template is NOT

- **Not a promise of automatic migration.** Systems with proprietary OCX or mainframe dependencies need human decisions in ADRs.
- **Not a syntax converter.** For 1:1 line-by-line conversion there are cheaper, more specific commercial tools.
- **No legacy sample code included.** You bring the client's code into `legacy/`.
- **No project duration estimates.** Estimation belongs in the commercial proposal, outside the methodology scope.

---

## License

MIT — use freely, attribute if you want.
