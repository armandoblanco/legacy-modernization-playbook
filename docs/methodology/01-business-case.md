# Fase 0 — Business Case (análisis económico previo)

> **Objetivo:** decidir si modernizar **conviene económicamente** y bajo qué supuestos, ANTES de tocar código o asignar equipo.

Esta fase no es opcional. Saltarla es la causa #1 de proyectos de modernización cancelados a mitad de camino: sin caso de negocio claro, el primer recorte presupuestal del cliente termina con el proyecto.

---

## Filosofía

La modernización no es un fin en sí mismo. Es una **inversión** que debe pagarse con:

1. **Reducción de costos operativos** (TCO actual vs TCO modernizado)
2. **Reducción de riesgo** (de incidentes, fraude, downtime, no-cumplimiento)
3. **Habilitación de nuevas capacidades** (integración, móvil, IA, datos)
4. **Reducción de deuda técnica** (costo de cambio futuro)

Si ninguna de las cuatro justifica el esfuerzo, la respuesta correcta es **no modernizar** y mantener el legacy hasta sunset planificado.

---

## Entradas

- Inventario de aplicaciones legacy del cliente
- Costos actuales: licencias, infraestructura, soporte, equipo
- Incidencias históricas: tickets, downtime, fraude, fixes urgentes
- Estrategia de negocio del cliente (a 3-5 años)
- Apetito de riesgo y restricciones (presupuesto, plazos, regulación)

---

## Entregables

```
assessment/{ProjectName}/
├── tco-actual-DDMMYYYY.md / .html              Costo total actual del sistema legacy
├── roi-modernizacion-DDMMYYYY.md / .html       Retorno esperado de la modernización
├── riesgo-no-hacer-DDMMYYYY.md / .html         Costo de NO modernizar (do-nothing scenario)
├── business-case-ejecutivo-DDMMYYYY.md / .html Resumen para sponsor (1-2 páginas)
└── seguridad-DDMMYYYY.md / .html               Assessment de seguridad whitehat
```

Templates en [`assessment/_templates/`](../../assessment/_templates/). Cada `.html` es autocontenido (CSS embebido) y se abre offline en cualquier navegador — útil para sponsors sin Git.

---

## Componentes del análisis

### 1. TCO actual (Total Cost of Ownership)

Costo anualizado del sistema legacy hoy:

- **Licencias:** sistema operativo, base de datos, runtime, herramientas
- **Infraestructura:** servidores físicos, datacenter, red, backup
- **Personal:** desarrollo, soporte L1/L2/L3, DBA, operaciones
- **Mantenimiento correctivo:** parches, hotfixes, workarounds
- **Mantenimiento evolutivo:** features nuevos, integraciones
- **Costos ocultos:** capacitación, contractors especializados (cada vez más caros), tiempo perdido por lentitud o caídas

### 2. ROI de modernización

- **Inversión:** assessment + planning + execution + cloud deployment + capacitación + migración de datos + paralelos + contingencia
- **Ahorro recurrente esperado:** post-modernización (cloud elasticidad, menos personal especializado, menos licencias caras)
- **Beneficios no monetarios cuantificables:** time-to-market, agilidad, integración con ecosistema moderno
- **Payback period:** meses hasta recuperar inversión
- **NPV / IRR:** valor presente neto, tasa interna de retorno

### 3. Riesgo de no hacer (do-nothing cost)

A menudo es el argumento más fuerte:

- **Obsolescencia de plataforma:** vendor end-of-life (ej. .NET Framework 4.x, VB6, Windows Server 2012, COBOL en mainframes z/OS antiguos)
- **Riesgo regulatorio:** GDPR, PCI-DSS, SOX, normativas locales que el sistema legacy no cumple
- **Riesgo de talento:** cada vez menos desarrolladores dispuestos a mantener el stack antiguo, y los que quedan cobran más
- **Riesgo de seguridad:** CVEs sin parche, dependencias sin soporte, superficie de ataque
- **Riesgo de pérdida de conocimiento:** documentación inexistente + jubilación del equipo original
- **Costo de oportunidad:** features que no se pueden hacer porque el legacy no soporta

### 4. Caso de negocio ejecutivo

Síntesis para el sponsor (CIO, CFO, CEO):
- Una página con problema, solución, inversión, retorno
- Un slide con el cuadro de decisión
- Sin jerga técnica innecesaria

---

## Criterios de salida (Definition of Done)

La fase está completa cuando:

1. Existe un TCO actual cuantificado y validado con finanzas del cliente
2. Existe un ROI proyectado con supuestos explícitos
3. Existe una sección de riesgo de no hacer con escenarios y probabilidades
4. El sponsor ha aprobado formalmente el caso de negocio
5. Existe un mandato escrito para iniciar Fase 1 con presupuesto asignado

---

## Anti-patrón clásico

> "Saltémonos el business case, total ya nos contrataron para migrar."

Cuando el sponsor cambie, el proyecto cambie de prioridad, o llegue un recorte, el primer proyecto cancelado es el que **no puede defender su valor en lenguaje financiero**. El business case es el seguro contra cancelación arbitraria.

---

## Agente de Copilot recomendado

[`@business-case-analyst`](../../.github/agents/shared/00-business-case.agent.md) — entrevista al cliente, estima TCO/ROI con rangos, genera los 4 entregables a partir de templates.

---

## Cuándo NO hacer business case formal

- Migraciones internas pequeñas (<3 meses-persona) donde el costo del análisis supera el costo de hacerla
- POCs y pilotos donde el objetivo es aprender, no decidir
- Casos donde el regulador **obliga** a migrar (ahí el business case es solo de "cómo", no de "si")
