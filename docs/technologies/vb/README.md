# Visual Basic Legacy (VB6 + VB.NET)

Estado: **Completo y validado en proyectos reales** (banca, gobierno y telco LATAM).

## Versiones cubiertas

| Lenguaje | Versiones | Notas |
| --- | --- | --- |
| Visual Basic 6 | SP6 (1998-2008) | OCX, COM tardío, `On Error Resume Next`, `Variant` |
| VB.NET legacy | .NET Framework 1.1 a 4.8 | `Option Strict Off`, `Microsoft.VisualBasic.dll`, WebForms, `Handles`, `WithEvents` |

## Stacks target soportados

- **WinForms .NET 8** — migración conservadora desktop
- **WPF .NET 8 + MVVM** — desktop con UI rica y testabilidad
- **Blazor Server / ASP.NET Core** — si la app debe ser web

Ver [`decision-stack-vb.md`](decision-stack-vb.md) para criterios completos.

## Documentos

- [`decision-stack-vb.md`](decision-stack-vb.md) — Criterios de elección de stack target
- [`trampas-vb6.md`](trampas-vb6.md) — Trampas semánticas específicas de VB6
- [`trampas-vbnet.md`](trampas-vbnet.md) — Trampas específicas de VB.NET legacy

## Agentes Copilot

- [`@vb-assessment`](../../../.github/agents/vb/01-vb-assessment.agent.md) — Fase 1
- [`@vb-planning`](../../../.github/agents/vb/02-vb-planning.agent.md) — Fase 2
- [`@vb-migration`](../../../.github/agents/vb/03-vb-migration.agent.md) — Fase 3

## Custom instructions por stack target

Ubicación: `.github/instructions/vb-target/`

- `csharp-style.instructions.md` (siempre activa)
- `winforms.instructions.md` (si target = WinForms)
- `wpf-mvvm.instructions.md` (si target = WPF)
- `blazor.instructions.md` (si target = Blazor)

## Workshop

[`../../workshop/vb/lab-01-assessment.md`](../../../workshop/vb/lab-01-assessment.md)
