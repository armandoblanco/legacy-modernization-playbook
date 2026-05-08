# Business Case Ejecutivo — {{ProjectName}}

> **Para:** {{Sponsor}} ({{RoleSponsor}})
> **De:** {{AnalystName}}
> **Fecha:** YYYY-MM-DD
> **Versión:** 1.0

---

## Problema

{{Sistema}} es {{descripción breve}} y soporta {{procesos críticos}} de {{ClientName}}. Hoy presenta:

- {{Problema1}}
- {{Problema2}}
- {{Problema3}}

Si no se actúa, los costos y riesgos se incrementan {{X}}% anual.

## Recomendación

Modernizar {{Sistema}} de {{LegacyTech}} a {{TargetStack}}, hospedado en {{CloudArchitecture}}, en {{N}} fases siguiendo metodología validada con asistencia de GitHub Copilot.

## Inversión

- **CAPEX total:** {{$}}
- **OPEX adicional inicial:** {{$}}/año primeros 2 años
- **Duración:** {{N}} meses

## Retorno

- **Ahorro anual a régimen:** {{$}}
- **Payback:** {{N}} meses
- **NPV (5 años):** {{$}}
- **IRR:** {{%}}

## Riesgo de no hacer

| Escenario | Costo 5 años |
| --- | --- |
| No hacer nada | {{$}} |
| Modernización planificada | {{$}} |
| Migración forzada (peor caso) | {{$}} |

## Riesgos del proyecto y mitigación

| Riesgo | Probabilidad | Impacto | Mitigación |
| --- | --- | --- | --- |
| {{Riesgo1}} | {{}} | {{}} | {{}} |
| {{Riesgo2}} | {{}} | {{}} | {{}} |
| {{Riesgo3}} | {{}} | {{}} | {{}} |

## Alternativas evaluadas

| Alternativa | Costo | Riesgo | Recomendación |
| --- | --- | --- | --- |
| Mantener status quo | {{$}} (5 años) | Alto | No recomendada |
| Reemplazar por SaaS | {{$}} | Medio | Evaluada — no aplica porque {{razón}} |
| Modernizar (esta propuesta) | {{$}} | Bajo-medio | **Recomendada** |
| Reescribir desde cero | {{$}} | Alto | No recomendada por {{razón}} |

## Decisión solicitada

- [ ] Aprobar inicio de Fase 1 (Assessment) con presupuesto de {{$}}
- [ ] Asignar sponsor ejecutivo: ______________
- [ ] Asignar product owner: ______________
- [ ] Confirmar comité de seguimiento mensual

---

## Anexos

- [`01-tco-actual.md`](01-tco-actual.md) — Detalle TCO actual
- [`02-roi-modernizacion.md`](02-roi-modernizacion.md) — Detalle ROI
- [`03-riesgo-no-hacer.md`](03-riesgo-no-hacer.md) — Detalle riesgos do-nothing
- Diagrama de arquitectura propuesta: `cloud-architectures/{{provider}}/`
