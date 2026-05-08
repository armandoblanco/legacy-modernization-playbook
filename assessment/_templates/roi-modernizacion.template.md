# ROI de Modernización — {{ProjectName}}

> **Cliente:** {{ClientName}}
> **Sistema:** {{LegacySystemName}} → {{TargetStack}}
> **Horizonte de análisis:** 5 años
> **Moneda:** {{Currency}}

## Resumen ejecutivo

| Métrica | Valor |
| --- | --- |
| Inversión total | {{$}} |
| Ahorro anual a régimen | {{$}} |
| Payback period | {{N}} meses |
| NPV (tasa de descuento {{r}}%) | {{$}} |
| IRR | {{%}} |
| Ahorro acumulado 5 años | {{$}} |

---

## 1. Inversión

### 1.1 CAPEX de modernización (one-shot)

| Fase | Esfuerzo (semanas-persona) | Costo blended | Total |
| --- | --- | --- | --- |
| Fase 0 — Business Case | {{N}} | {{$}} | {{$}} |
| Fase 1 — Assessment | {{N}} | {{$}} | {{$}} |
| Fase 2 — Planning | {{N}} | {{$}} | {{$}} |
| Fase 3 — Execution | {{N}} | {{$}} | {{$}} |
| Fase 4 — Cloud Deployment | {{N}} | {{$}} | {{$}} |
| Capacitación al equipo cliente | {{N}} | {{$}} | {{$}} |
| Migración de datos | {{N}} | {{$}} | {{$}} |
| Operación paralela (legacy + nuevo) | {{N}} meses | {{$}} | {{$}} |
| Contingencia ({{X}}%) | | | {{$}} |
| **TOTAL CAPEX** | | | **{{$}}** |

### 1.2 OPEX adicional inicial

- Licencias nuevas (cloud, herramientas, observabilidad): {{$}}/año los primeros 2 años
- Soporte vendor del nuevo stack: {{$}}/año

---

## 2. Ahorro recurrente esperado

| Concepto | TCO actual | TCO post-modernización | Ahorro anual |
| --- | --- | --- | --- |
| Licencias | {{$}} | {{$}} | {{$}} |
| Infraestructura (on-prem → cloud elástico) | {{$}} | {{$}} | {{$}} |
| Personal especializado en legacy | {{$}} | {{$}} | {{$}} |
| Mantenimiento correctivo (menos hotfixes) | {{$}} | {{$}} | {{$}} |
| Tiempo de entrega de features (productividad) | {{$}} | {{$}} | {{$}} |
| **Total ahorro anual** | | | **{{$}}** |

---

## 3. Beneficios cuantificables no monetarios

| Beneficio | Métrica actual | Métrica esperada | Valor estimado |
| --- | --- | --- | --- |
| Time-to-market features | {{N}} semanas | {{N}} semanas | {{$}} |
| Disponibilidad (SLA) | {{%}} | {{%}} | {{$}} (pérdida evitada) |
| Tiempo medio de recuperación (MTTR) | {{N}} h | {{N}} h | {{$}} |
| Cumplimiento normativo (multas evitadas) | — | — | {{$}} |
| Habilitación de canales digitales nuevos | — | {{N}} canales | {{$}} ingresos potenciales |

---

## 4. Flujo de caja proyectado (5 años)

| Año | Inversión | Ahorro anual | Flujo neto | Acumulado |
| --- | --- | --- | --- | --- |
| 0 | -{{$}} | 0 | -{{$}} | -{{$}} |
| 1 | -{{$}} | {{$}} | {{$}} | {{$}} |
| 2 | 0 | {{$}} | {{$}} | {{$}} |
| 3 | 0 | {{$}} | {{$}} | {{$}} |
| 4 | 0 | {{$}} | {{$}} | {{$}} |
| 5 | 0 | {{$}} | {{$}} | {{$}} |

**Tasa de descuento usada:** {{r}}% (justificación: {{coste-capital-cliente}})

---

## 5. Análisis de sensibilidad

¿Qué pasa si los supuestos varían?

| Variable | Pesimista | Base | Optimista | Impacto en payback |
| --- | --- | --- | --- | --- |
| Esfuerzo de Fase 3 | +{{X}}% | base | -{{Y}}% | {{N}} meses |
| Ahorro de personal | -{{X}}% | base | +{{Y}}% | {{N}} meses |
| Costo de cloud | +{{X}}% | base | -{{Y}}% | {{N}} meses |
| Adopción de usuarios | retrasada {{N}}m | base | inmediata | {{N}} meses |

---

## 6. Supuestos clave

- {{Supuesto1}}
- {{Supuesto2}}
- {{SupuestoN}}

## 7. Riesgos al ROI

- {{Riesgo1}} — mitigación: {{Mitigación1}}
- {{Riesgo2}} — mitigación: {{Mitigación2}}

## Aprobaciones

- [ ] Validado por finanzas: ______________
- [ ] Aprobado por sponsor: ______________ ({{Sponsor}})
- [ ] Fecha: ______________
