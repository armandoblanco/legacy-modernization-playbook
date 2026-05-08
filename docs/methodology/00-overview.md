# Metodología de modernización (visión general)

Este documento describe la metodología **agnóstica de tecnología** para modernizar sistemas legacy. La metodología se aplica igual para VB6, VB.NET, .NET Framework, COBOL, Java legacy, Python 2, Delphi, etc. Cada tecnología agrega una **capa específica** sobre esta base.

---

## Las cinco fases

```
[Fase 0]            [Fase 1]            [Fase 2]            [Fase 3]            [Fase 4]
Business Case  →    Assessment      →   Planning        →   Execution       →   Cloud Deployment
   (¿conviene?)       (¿qué hay?)        (¿hacia dónde?)    (construir)         (¿dónde corre?)
```

| Fase | Pregunta que responde | Entregable principal | Sin esto, qué pasa |
| --- | --- | --- | --- |
| **0. Business Case** | ¿Vale la pena modernizar? ¿Con qué ROI? | `assessment/{ProjectName}/` con TCO, ROI, riesgo de no hacer y assessment de seguridad | Proyecto sin sponsor, primer recorte presupuestal lo mata |
| **1. Assessment** | ¿Qué tiene el sistema legacy realmente? | `docs/features/` por módulo | Re-arquitectura accidental, reglas de negocio inventadas |
| **2. Planning** | ¿A qué stack/arquitectura migramos y por qué? | `docs/ARQUITECTURA-TARGET.md` + ADRs | Frankenstein arquitectónico, refactors permanentes |
| **3. Execution** | ¿Cómo construimos la nueva versión? | `migrated/` solución funcional con paridad | Código que compila pero no hace lo correcto |
| **4. Cloud Deployment** | ¿Dónde corre y bajo qué arquitectura cloud? | `cloud-architectures/<provider>/` + IaC | App moderna pero hosting legacy, costos no controlados |

---

## Por qué este orden es estricto

Cada fase depende de la anterior:

- **Sin Fase 0**, el proyecto no tiene mandato económico claro y será cancelado en cualquier ajuste de presupuesto.
- **Sin Fase 1**, el modelo (humano o IA) inventa reglas de negocio.
- **Sin Fase 2**, el equipo improvisa arquitectura por feature → inconsistencia.
- **Sin Fase 3 disciplinada** (compile-and-test entre capas), errores se acumulan hasta el final.
- **Sin Fase 4**, la app moderna se hostea como la vieja y se pierde gran parte del valor.

---

## Qué cambia y qué no por tecnología

**Lo que NO cambia (núcleo metodológico):**
- Las cinco fases y su orden
- Concepto de paridad semántica
- Uso de ADRs para decisiones arquitectónicas
- Compile-and-test entre capas en Fase 3
- Bitácora de migración (`migration-log.md`)

**Lo que SÍ cambia por tecnología:**
- Heurísticas de detección de "trampas" (`docs/technologies/<tech>/trampas.md`)
- Stack target candidato (`docs/technologies/<tech>/decision-stack.md`)
- Agentes de Copilot especializados (`.github/agents/<tech>/`)
- Custom instructions de estilo (`.github/instructions/<target>/`)

---

## Tecnologías cubiertas

| Tecnología legacy | Estado | Carpeta |
| --- | --- | --- |
| Visual Basic (VB6 + VB.NET legacy) | Completo | [`docs/technologies/vb/`](../technologies/vb/) |
| .NET Framework 2.0–4.8 → .NET 8/9 | Placeholder | [`docs/technologies/dotnet-framework/`](../technologies/dotnet-framework/) |
| COBOL → Java/.NET | Placeholder | [`docs/technologies/cobol/`](../technologies/cobol/) |
| Java legacy (J2EE, Java 6/7/8) → Java 21 | Placeholder | [`docs/technologies/java/`](../technologies/java/) |
| Python 2 → Python 3.12+ | Placeholder | [`docs/technologies/python/`](../technologies/python/) |

Para añadir una nueva tecnología, ver [`docs/technologies/README.md`](../technologies/README.md).

---

## Detalle por fase

- [`01-business-case.md`](01-business-case.md) — Fase 0: análisis económico previo
- [`02-assessment-planning-execution.md`](02-assessment-planning-execution.md) — Fases 1, 2 y 3 (núcleo de migración de código)
- [`05-cloud-deployment.md`](05-cloud-deployment.md) — Fase 4: arquitectura cloud target

---

## Decisiones que NO toma esta metodología

- Re-diseño de UX (proyecto separado)
- Refactor de modelo de datos (proyecto separado)
- Optimización de performance (post-migración)
- Decisiones de negocio (paridad fiel, incluyendo bugs históricos)

Mezclar cualquiera de estos con la migración garantiza que el proyecto se desborde.
