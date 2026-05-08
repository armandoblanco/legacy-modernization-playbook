# Lab 0 — Construir Business Case

> Lab introductorio que recorre la **Fase 0** de la metodología sobre un caso ficticio.

## Objetivo

Practicar la construcción del caso de negocio para una modernización legacy usando el agente `@business-case-analyst` y los templates de `assessment/_templates/`. Outputs van a `assessment/SISCobranzas/<categoria>-DDMMYYYY.{md,html}`.

## Caso ficticio

- **Cliente:** Aseguradora MidCo (LATAM)
- **Sistema:** SISCobranzas, app interna de cobranza
- **Tecnología legacy:** {{LegacyTech}} ({{LegacyLang}})
- **Tamaño:** ~250 KLOC, ~8 módulos
- **Equipo actual:** 2 desarrolladores legacy + 1 DBA + 1 soporte L2
- **Infraestructura:** 2 VMs on-prem, 1 SQL Server 2014 dedicado
- **Tráfico:** 80 usuarios concurrentes pico, ventana 8am-7pm
- **Sponsor:** Director de Tecnología
- **Restricción regulatoria:** auditoría externa exige MFA y cifrado en reposo (no se cumplen hoy)

## Pasos

1. Abre el chat de Copilot e invoca `@business-case-analyst`:
   ```
   @business-case-analyst Construye el caso de negocio para SISCobranzas
   ```
2. Responde a las preguntas del agente con datos plausibles del caso ficticio.
3. Revisa los 4 documentos generados en `assessment/SISCobranzas/` (MD + HTML).
4. Compara tu output con la rúbrica abajo.

## Rúbrica de evaluación

- [ ] TCO actual cubre las 6 categorías (licencias, infra, personal, correctivo, evolutivo, ocultos)
- [ ] ROI tiene supuestos explícitos y al menos 3 escenarios de sensibilidad
- [ ] Riesgo de no hacer cuantifica obsolescencia, regulatorio, talento, oportunidad
- [ ] Ejecutivo es ≤ 2 páginas y tiene la decisión solicitada clara
- [ ] Lista de "Insumos pendientes" consolidada
- [ ] Recomendación final: proceder / ajustar / no modernizar

## Variantes

- Cambia el sponsor a CFO y reescribe el ejecutivo en lenguaje financiero estricto
- Asume que existe un SaaS competidor — añade "Repurchase" como alternativa al ROI
