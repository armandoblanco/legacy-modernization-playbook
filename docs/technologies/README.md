# Tecnologías legacy soportadas

Esta carpeta agrupa el contenido **específico por tecnología legacy**. La metodología (5 fases) es la misma para todas; cambia la capa táctica: trampas semánticas, stacks target candidatos, agentes especializados, custom instructions.

---

## Estado por tecnología

| Tecnología | Estado | Carpeta | Stack target sugerido |
| --- | --- | --- | --- |
| **Visual Basic** (VB6 + VB.NET legacy) | Completo | [`vb/`](vb/) | .NET 8 (WinForms / WPF / Blazor) |
| **.NET Framework 2.0–4.8** | Placeholder | [`dotnet-framework/`](dotnet-framework/) | .NET 8 / 9 |
| **COBOL** | Placeholder | [`cobol/`](cobol/) | Java 21 / .NET 8 |
| **Java legacy** (J2EE, Java 6/7/8) | Placeholder | [`java/`](java/) | Java 21 + Spring Boot 3 |
| **Python 2** | Placeholder | [`python/`](python/) | Python 3.12+ |

Para más tecnologías candidatas (Delphi, PowerBuilder, ASP clásico, FoxPro, RPG/AS400, PL/SQL Forms), abrir issue.

---

## Estructura mínima esperada por tecnología

Cada subcarpeta de tecnología sigue esta convención:

```
docs/technologies/<tech>/
├── README.md                       Resumen, estado, cobertura
├── trampas-<tech>.md               Anti-patrones y semántica peligrosa
├── decision-stack-<tech>.md        Criterios de elección de stack target
└── ejemplos/                       (opcional) Snippets antes/después
```

Y opcionalmente:

```
.github/agents/<tech>/
├── 01-<tech>-assessment.agent.md
├── 02-<tech>-planning.agent.md
└── 03-<tech>-migration.agent.md

.github/instructions/<target>/      (uno por target, no por legacy)
└── *.instructions.md

.github/prompts/<tech>/
└── *.prompt.md
```

---

## Cómo añadir una nueva tecnología

1. Crear `docs/technologies/<tech>/README.md` describiendo:
   - Versiones cubiertas
   - Stacks target candidatos
   - Particularidades (runtime, build, dependencias típicas, OCX/COM equivalente)
2. Documentar `trampas-<tech>.md` con anti-patrones de lenguaje y semántica
3. Documentar `decision-stack-<tech>.md` con criterios de elección
4. Crear los 3 agentes en `.github/agents/<tech>/` (ver templates en `.github/agents/_templates/`)
5. Crear custom instructions en `.github/instructions/<target>/` por cada stack target
6. Actualizar `bootstrap.sh` / `bootstrap.ps1` para soportar la nueva opción
7. Actualizar este README y el [overview de metodología](../methodology/00-overview.md)

---

## Agentes shared (no dependen de tecnología)

- [`@business-case-analyst`](../../.github/agents/shared/00-business-case.agent.md) — Fase 0
- [`@cloud-architect`](../../.github/agents/shared/04-cloud-architect.agent.md) — Fase 4

Estos se usan para **cualquier** tecnología legacy.
