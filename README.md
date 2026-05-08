# Modernización de sistemas legacy con GitHub Copilot

Plantilla **multi-tecnología** para modernizar aplicaciones legacy con asistencia de GitHub Copilot, cubriendo el ciclo completo: caso de negocio, assessment, planning, ejecución de migración y arquitectura cloud target. Construida a partir de migraciones reales en banca, gobierno y telco en LATAM.

> Hoy con cobertura completa para **Visual Basic 6 / VB.NET** y **.NET Framework 2.0–4.8**, con placeholders para **COBOL, Java legacy y Python**. Diseñada para extenderse a otras tecnologías sin romper la metodología.
>
> **English version:** [README.en.md](README.en.md)

---

## Metodología en cinco fases

```
[Fase 0]            [Fase 1]            [Fase 2]            [Fase 3]            [Fase 4]
Business Case  →    Assessment      →   Planning        →   Execution       →   Cloud Deployment
   (¿conviene?)       (¿qué hay?)        (¿hacia dónde?)    (construir)         (¿dónde corre?)
```

| Fase | Pregunta | Entregable | Agente Copilot |
| --- | --- | --- | --- |
| **0. Business Case** | ¿Vale la pena modernizar? | `assessment/{ProjectName}/` (TCO, ROI, riesgo, ejecutivo, seguridad) | `@business-case-analyst`, `@security-assessor` |
| **1. Assessment** | ¿Qué tiene el legacy? | `docs/features/` | `@<tech>-assessment` |
| **2. Planning** | ¿A qué stack y por qué? | `docs/ARQUITECTURA-TARGET.md` + ADRs | `@<tech>-planning` |
| **3. Execution** | ¿Cómo construirlo? | `migrated/` con paridad | `@<tech>-migration` |
| **4. Cloud Deployment** | ¿Dónde y bajo qué arquitectura? | `cloud-architectures/<provider>/` + IaC | `@cloud-architect` |

Detalle metodológico en [`docs/methodology/00-overview.md`](docs/methodology/00-overview.md).

---

## Tecnologías legacy soportadas

| Tecnología | Estado | Carpeta de referencia |
| --- | --- | --- |
| **Visual Basic** (VB6 + VB.NET legacy) | Completo y validado | [`docs/technologies/vb/`](docs/technologies/vb/) |
| **.NET Framework 2.0–4.8** | ✅ Completo (`@dotnet-assessment` / `@dotnet-planning` / `@dotnet-migration`) | [`docs/technologies/dotnet-framework/`](docs/technologies/dotnet-framework/) |
| **COBOL** (z/OS, distributed) | Placeholder | [`docs/technologies/cobol/`](docs/technologies/cobol/) |
| **Java legacy** (J2EE, Java 6/7/8) | Placeholder | [`docs/technologies/java/`](docs/technologies/java/) |
| **Python 2 / 3 antiguo** | Placeholder | [`docs/technologies/python/`](docs/technologies/python/) |

Para añadir una tecnología nueva, ver [`docs/technologies/README.md`](docs/technologies/README.md).

---

## Cómo usar esta plantilla

### Paso 1 — Clonar

```bash
git clone https://github.com/armandoblanco/legacy-modernization-playbook.git mi-proyecto
cd mi-proyecto
rm -rf .git && git init
```

### Paso 2 — Bootstrap interactivo

```bash
./bootstrap.sh        # Linux/macOS/WSL
.\bootstrap.ps1       # Windows
```

Te va a preguntar:

- Nombre del proyecto y cliente
- Tecnología legacy (`vb`, `dotnet-framework`, `cobol`, `java`, `python`, `other`)
- Si elegiste VB: sub-lenguaje (`vb6`/`vbnet`) y stack target (`winforms`/`wpf`/`blazor`)
- Proveedor cloud objetivo (`azure`/`aws`/`gcp`/`on-premise`/`undecided`)

Y va a:

- Reemplazar placeholders (`{{ProjectName}}`, `{{ClientName}}`, `{{LegacyTech}}`, `{{TargetStack}}`, `{{CloudProvider}}`)
- (Opcional) Eliminar carpetas de tecnologías y proveedores no elegidos
- Generar `.copilot-project.yml`

### Paso 3 — (Recomendado) Construir Business Case primero

```text
@business-case-analyst Construye el caso de negocio para mi proyecto
```

El agente entrevista, estima rangos justificados, y rellena los 4 entregables en [`assessment/{ProjectName}/`](assessment/) (versión MD + HTML autocontenido).

Y luego el assessment de seguridad whitehat:

```text
@security-assessor Revisa la seguridad del código en legacy/
```

Genera `seguridad-DDMMYYYY.md` y `.html` en la misma carpeta del proyecto.

### Paso 4 — Cargar el código legacy

```bash
mkdir -p legacy/
cp -r /ruta/al/codigo-legacy/* legacy/
```

### Paso 5 — Iniciar Fase 1 (Assessment)

Para **VB6 / VB.NET**:

```text
@vb-assessment Analiza el sistema en legacy/
```

Para **.NET Framework 2.0–4.8**:

```text
@dotnet-assessment Analiza el sistema en legacy/
```

Para otras tecnologías, usa los templates en [`.github/agents/_templates/`](.github/agents/_templates/) para crear los agentes.

### Paso 6 — Continuar con Planning, Execution y Cloud

**VB:**
```text
@vb-planning            (Fase 2)
@vb-migration           (Fase 3)
```

**.NET Framework:**
```text
@dotnet-planning        (Fase 2)
@dotnet-migration       (Fase 3)
```

**Cloud (cualquier tecnología):**
```text
@cloud-architect        (Fase 4 multi-cloud)
@azure-architect        (Fase 4 Azure — Mermaid + precios validados)
```

---

## Estructura del repo

```
legacy-modernization-playbook/
├── README.md / README.en.md
├── bootstrap.sh / bootstrap.ps1
├── docs/
│   ├── methodology/                    Metodología agnóstica (5 fases)
│   │   ├── 00-overview.md
│   │   ├── 01-business-case.md         Fase 0
│   │   ├── 02-assessment-planning-execution.md   Fases 1, 2, 3
│   │   └── 05-cloud-deployment.md      Fase 4
│   ├── shared/                         Lecciones, anti-patrones (transversal)
│   └── technologies/
│       ├── README.md
│       ├── vb/                         ✅ Cobertura completa
│       ├── dotnet-framework/           ✅ Cobertura completa
│       ├── cobol/                      Placeholder
│       ├── java/                       Placeholder
│       └── python/                     Placeholder
├── assessment/                          Fase 0 (outputs por proyecto + templates)
│   ├── _templates/                      tco-actual, roi, riesgo, ejecutivo, seguridad
│   └── {ProjectName}/                   {categoria}-DDMMYYYY.{md,html}
├── scripts/                             md2html.{sh,py} (HTML autocontenido offline)
├── cloud-architectures/                Fase 4
│   ├── README.md
│   ├── azure/                          5 patrones documentados + @azure-architect
│   ├── aws/                            Placeholder
│   ├── gcp/                            Placeholder
│   ├── on-premise/                     Placeholder
│   └── _templates/                     Plantilla de ADR cloud
├── .github/
│   ├── agents/
│   │   ├── shared/                     @business-case-analyst, @security-assessor, @cloud-architect, @azure-architect
│   │   ├── vb/                         3 agentes VB (Fases 1-3)
│   │   ├── dotnet-framework/           3 agentes .NET Framework (Fases 1-3)
│   │   └── _templates/                 Plantillas para nuevas tecnologías
│   ├── instructions/
│   │   ├── vb-target/                  csharp / winforms / wpf-mvvm / blazor
│   │   ├── dotnet-target/              csharp-modern (.NET 8/9)
│   │   ├── shared/                     testing-strategy (pirámide, Testcontainers, paridad)
│   │   └── _templates/
│   └── prompts/
│       ├── shared/                     business-case, arquitectura cloud, validar-precios-azure
│       ├── vb/                         analizar-feature, generar-adr, migrar-modulo, validar-paridad
│       └── dotnet-framework/           analizar-proyecto, generar-adr, migrar-proyecto, validar-paridad
├── workshop/
│   ├── shared/                         lab-00 (business case), lab-04 (cloud)
│   ├── vb/                             lab-01 (assessment VB)
│   └── dotnet-framework/               lab-01 (assessment .NET Framework)
└── legacy/                             (vacío) código del cliente
```

---

## Filosofía

- **5 fases en orden estricto.** Cada fase produce el insumo de la siguiente. Saltar fases genera re-trabajo predecible.
- **Tecnología-agnóstica en el núcleo.** El qué, cuándo y por qué son iguales para VB, COBOL, Java o Python; cambia el cómo táctico.
- **Cada decisión es un ADR.** Sin ADR la decisión no existe a los 6 meses.
- **El código legacy es la fuente de verdad.** Documentación y memoria del equipo son aproximaciones.
- **Copilot acelera, no reemplaza.** El agente propone; el humano decide.

---

## Lo que NO es esta plantilla

- **No es una promesa de migración automática.** Sistemas con OCX propietarios o dependencias de mainframe requieren decisiones humanas en ADR.
- **No es un convertidor de sintaxis.** Para conversión 1:1 línea por línea hay herramientas comerciales más baratas y específicas.
- **No incluye samples de código legacy.** Tú aportas el código del cliente en `legacy/`.
- **No estima duración del proyecto.** La estimación se hace en la propuesta comercial, fuera del alcance de la metodología.

---

## Agentes Copilot incluidos

### Compartidos (cualquier tecnología)

- [`@business-case-analyst`](.github/agents/shared/00-business-case.agent.md) — Fase 0
- [`@security-assessor`](.github/agents/shared/02-security-assessor.agent.md) — Fase 0 (whitehat / pentest)
- [`@cloud-architect`](.github/agents/shared/04-cloud-architect.agent.md) — Fase 4 (multi-cloud)
- [`@azure-architect`](.github/agents/shared/05-azure-architect.agent.md) — Fase 4 (Azure: Mermaid + precios validados vía Retail Prices API)

### Específicos por tecnología

- **VB:** [`@vb-assessment`](.github/agents/vb/01-vb-assessment.agent.md) · [`@vb-planning`](.github/agents/vb/02-vb-planning.agent.md) · [`@vb-migration`](.github/agents/vb/03-vb-migration.agent.md)
- **.NET Framework:** [`@dotnet-assessment`](.github/agents/dotnet-framework/01-dotnet-assessment.agent.md) · [`@dotnet-planning`](.github/agents/dotnet-framework/02-dotnet-planning.agent.md) · [`@dotnet-migration`](.github/agents/dotnet-framework/03-dotnet-migration.agent.md)
- Otras tecnologías: usar templates en [`.github/agents/_templates/`](.github/agents/_templates/)

### Modelos sugeridos

| Tipo de tarea | Modelo recomendado | Por qué |
|---|---|---|
| Assessment, business case (alto volumen lectura) | **Claude Sonnet 4.5** | Coste/rendimiento óptimo para leer mucho código |
| Planning, ADRs, decisiones arquitectónicas | **Claude Opus 4.1** | Razonamiento profundo |
| Migration (refactor de código) | **Claude Opus 4.1** | Precisión en transformaciones |
| Security assessment | **Claude Opus 4.1** | Análisis adversarial |
| Cloud architecture | **Claude Opus 4.1** | Trade-offs y validación de precios |

Los modelos están declarados en el frontmatter de cada agente. Override en `.copilot-project.yml` o cambiando `model:` en el agente.


---

## Lecciones aprendidas (resumen)

Versión completa con contexto en [`docs/shared/lecciones-aprendidas.md`](docs/shared/lecciones-aprendidas.md).

1. **El business case (Fase 0) salva proyectos** del primer recorte presupuestal del cliente.
2. **El assessment es 30% del trabajo total**, no el 5% que la mayoría asume.
3. **Componentes legacy bloqueados (OCX, COM, EJB 2.x, IDMS, etc.) no se migran**: se reemplazan con arquitectura alternativa documentada en ADR.
4. **Copilot inventa comportamiento** cuando el `.md` del feature está incompleto. Solución: forzarlo a leer el código legacy fuente.
5. **Una solución target separada** evita corromper el proyecto legacy y permite mantenerlo compilable durante la transición.
6. **Compile-and-test entre capas** detecta errores de inmediato en vez de acumularlos hasta el final.
7. **La arquitectura cloud (Fase 4) requiere disciplina propia.** App moderna en hosting legacy ≠ modernización.

---

## Contribuir

Si has modernizado un sistema con esta metodología y tienes lecciones nuevas o trampas no documentadas, abre issue. Especialmente buscamos:

- Casos reales de COBOL, Java legacy, .NET Framework, Python 2 → poblar placeholders
- Arquitecturas cloud en AWS y GCP equivalentes a las de Azure
- Templates de business case validados con áreas financieras de clientes

## Licencia

MIT — usa libremente, atribuye si quieres.
