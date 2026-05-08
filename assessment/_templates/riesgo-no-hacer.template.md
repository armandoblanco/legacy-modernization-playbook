# Riesgo de NO modernizar (do-nothing scenario) — {{ProjectName}}

> **Sistema:** {{LegacySystemName}} ({{LegacyTech}})
> **Cliente:** {{ClientName}}
> **Fecha:** YYYY-MM-DD

A menudo este es el argumento más fuerte del business case: el costo de **no hacer nada** rara vez es cero.

---

## 1. Riesgo de obsolescencia de plataforma

| Componente | Versión actual | Estado de soporte | Fecha EOL | Impacto |
| --- | --- | --- | --- | --- |
| {{LegacyTech}} | {{Versión}} | {{Estado}} | {{Fecha}} | {{Impacto}} |
| Sistema operativo | {{OS}} | {{Estado}} | {{Fecha}} | {{Impacto}} |
| Base de datos | {{DB}} | {{Estado}} | {{Fecha}} | {{Impacto}} |
| Runtime / framework | {{RT}} | {{Estado}} | {{Fecha}} | {{Impacto}} |
| Componentes / OCX | {{Lista}} | {{Estado}} | {{Fecha}} | {{Impacto}} |

**Costo estimado de extender soporte (extended support fees):** {{$}}/año

---

## 2. Riesgo regulatorio y de cumplimiento

| Normativa | Aplica | Cumple sistema actual | Brecha | Costo de incumplimiento |
| --- | --- | --- | --- | --- |
| GDPR / LGPD / Ley Protección Datos local | {{Sí/No}} | {{Sí/No}} | {{Brecha}} | hasta {{$}} multa |
| PCI-DSS | {{Sí/No}} | {{Sí/No}} | {{Brecha}} | {{$}} + pérdida certificación |
| SOX / ISO 27001 | {{Sí/No}} | {{Sí/No}} | {{Brecha}} | {{$}} |
| Normativa sectorial ({{ej. SBS, Banxico, CNBV}}) | {{Sí/No}} | {{Sí/No}} | {{Brecha}} | {{$}} |

---

## 3. Riesgo de seguridad

| Concepto | Situación actual | Probabilidad | Impacto monetario | Riesgo esperado anual |
| --- | --- | --- | --- | --- |
| CVEs sin parche en dependencias EOL | {{N}} CVEs altos/críticos | {{P%}} | {{$}} por incidente | {{$}} |
| Superficie de ataque (componentes obsoletos) | {{Detalle}} | {{P%}} | {{$}} | {{$}} |
| Auth/AuthZ legacy (sin MFA, hashing débil) | {{Sí/No}} | {{P%}} | {{$}} | {{$}} |
| Logging/auditoría deficiente (no se detectan brechas) | {{Sí/No}} | {{P%}} | {{$}} | {{$}} |

**Costo esperado anual por riesgo de seguridad:** {{$}}

---

## 4. Riesgo de talento

- **Desarrolladores activos en {{LegacyTech}} en mercado local:** ~{{N}}, con tendencia decreciente
- **Tarifa promedio actual:** {{$}}/h
- **Tarifa proyectada en 3 años:** {{$}}/h ({{X}}% incremento)
- **Edad promedio del equipo actual:** {{N}} años; {{M}} jubilaciones esperadas en {{N}} años
- **Costo de reemplazo por jubilación (capacitación + ramp-up + contractor puente):** {{$}}/persona

**Riesgo de operación insostenible en {{N}} años si no se actúa.**

---

## 5. Riesgo de pérdida de conocimiento

- Documentación del sistema: {{Estado}}
- Personal con conocimiento profundo: {{N}} personas
- Buses factor: **{{N}}** (cuántas personas pueden faltar antes de perder capacidad de operar)
- Tiempo estimado para reconstituir conocimiento si se pierden: {{meses}} meses
- Costo de no poder responder a un incidente complejo: {{$}}

---

## 6. Costo de oportunidad

Features y capacidades que el negocio necesita y el sistema legacy **no puede entregar** o entrega a costo prohibitivo:

| Capacidad bloqueada | Valor de negocio perdido al año |
| --- | --- |
| {{ej. canal móvil}} | {{$}} |
| {{ej. integración con BI moderno}} | {{$}} |
| {{ej. APIs públicas para partners}} | {{$}} |
| {{ej. IA / analítica avanzada sobre datos del sistema}} | {{$}} |
| **Total costo de oportunidad anual** | **{{$}}** |

---

## 7. Escenarios

### Escenario A — No hacer nada (status quo)

- Año 1: {{$}} costos adicionales (extended support + workarounds)
- Año 2: {{$}}
- Año 3: probable incidente mayor; pérdida estimada {{$}}
- Año 5: sistema operacionalmente insostenible; migración forzada en condiciones peores

### Escenario B — Modernización planificada (este business case)

Ver [`02-roi-modernizacion.md`](02-roi-modernizacion.md)

### Escenario C — Migración forzada por incidente (peor caso)

- Disparada por: incidente de seguridad / EOL no planificado / pérdida de personal clave
- Sobrecosto vs Escenario B: estimado {{X}}% por urgencia, falta de assessment, decisiones bajo presión
- Probabilidad estimada en próximos 3 años si no se actúa: **{{P%}}**

---

## 8. Conclusión

| Escenario | Costo esperado a 5 años |
| --- | --- |
| A — No hacer nada | {{$}} |
| B — Modernización planificada | {{$}} (incluye inversión y ahorros) |
| C — Migración forzada | {{$}} |

**Diferencial A vs B:** {{$}} — esta es la **justificación principal** de la modernización.

---

## Aprobaciones

- [ ] Validado por: ______________ (CISO / Riesgos)
- [ ] Validado por: ______________ (Compliance)
- [ ] Aprobado por sponsor: ______________
