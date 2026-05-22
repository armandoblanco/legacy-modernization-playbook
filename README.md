# Modernización de sistemas legacy con GitHub Copilot

Plantilla **multi-tecnología** para modernizar aplicaciones legacy con asistencia de GitHub Copilot. Cubre el ciclo completo: caso de negocio, assessment, planning, refinamiento de scope, modernization strategy, ejecución, testing y arquitectura cloud. Construida a partir de migraciones reales en banca, gobierno y telco en LATAM.

> Hoy con cobertura completa para **Visual Basic 6 / VB.NET** y **.NET Framework 2.0–4.8**. Placeholders para **COBOL, Java legacy y Python**, extensible a otras tecnologías sin romper la metodología.
>
> **English version:** [README.en.md](README.en.md)

---

## Flujo completo de modernización (7 fases)

```
[Fase 0]          [Fase 1]          [Fase 2]          [Fase 2.5]        [Fase 3]          [Fase 4]          [Fase 5]          [Fase 6]
Business      →   Assessment    →   Planning      →   Plan          →   Modernization →   Execution     →   Testing &     →   Cloud
Case              técnico           arquitectura      Refinement        Strategy          (construir)       QA                Deployment
                                                      (scope)           (6R + path)                         (paridad)
```

| Fase | Agente | Entregable principal |
| --- | --- | --- |
| **0. Business Case** | `business-case-analyst`, `security-assessor` | `assessment/{Proyecto}/` (TCO, ROI, riesgo, seguridad) |
| **1. Assessment técnico** | `vb-assessment` o `dotnet-assessment` | `docs/features/` (reglas, dependencias, bloqueos) |
| **2. Planning** | `vb-planning` o `dotnet-planning` | `docs/ARQUITECTURA-TARGET.md` + ADRs |
| **2.5. Plan Refinement** | `plan-refiner` | `docs/MIGRATION-SCOPE.md` (scope acordado con cliente) |
| **3. Modernization Strategy** | `modernization-strategy` | `docs/MODERNIZATION-PATH.md` (6R + path) |
| **4. Execution** | `vb-migration` o `dotnet-migration` | Código en `src/` con paridad funcional |
| **5. Testing & QA** | `migration-tester` | `testing/parity-report.md`, coverage, gaps |
| **6. Cloud Deployment** | `cloud-architect` o `azure-architect` | `cloud-architectures/<proveedor>/` + IaC |

Detalle metodológico en [`docs/methodology/00-overview.md`](docs/methodology/00-overview.md).

---

## Tecnologías legacy soportadas

| Tecnología | Estado | Agentes técnicos |
| --- | --- | --- |
| Visual Basic 6 / VB.NET legacy | Completo y validado | `vb-assessment` · `vb-planning` · `vb-migration` |
| .NET Framework 2.0–4.8 | Completo | `dotnet-assessment` · `dotnet-planning` · `dotnet-migration` |
| COBOL (z/OS, distributed) | Placeholder | Crear desde `.github/agents/_templates/` |
| Java legacy (J2EE, Java 6/7/8) | Placeholder | Crear desde `.github/agents/_templates/` |
| Python 2 / 3 antiguo | Placeholder | Crear desde `.github/agents/_templates/` |

Para añadir una tecnología, ver [`docs/technologies/README.md`](docs/technologies/README.md).

---

## Cómo usar la plantilla

### 1. Clonar

```bash
git clone https://github.com/armandoblanco/legacy-modernization-playbook.git mi-proyecto
cd mi-proyecto
rm -rf .git && git init
```

### 2. Bootstrap interactivo

```bash
./bootstrap.sh       # Linux/macOS/WSL
.\bootstrap.ps1      # Windows
```

El bootstrap pregunta proyecto, cliente, tecnología legacy, stack target y cloud, y luego:

- Reemplaza placeholders (`{{ProjectName}}`, etc.) en todos los `.md`.
- **Copia los agentes de la tecnología elegida + shared a `.github/agents/` flat** (ver nota técnica abajo).
- Genera `.copilot-project.yml` con la configuración.
- Crea carpetas de trabajo: `legacy/`, `src/`, `assessment/{ProjectName}/`, `testing/`.
- Genera `NEXT-STEPS.md` con el flujo personalizado para tu tech/stack.

**El bootstrap NO se autoelimina.** Puedes re-ejecutarlo para cambiar tech/stack/cloud sin perder trabajo. Las elecciones anteriores se sobrescriben.

> **Nota técnica importante: descubrimiento de agentes en `.github/agents/`**
>
> GitHub Copilot **no descubre agentes en subcarpetas** de `.github/agents/`. Lee únicamente los archivos `.agent.md` que están directamente en `.github/agents/`. Es comportamiento conocido (issues abiertos en `github/copilot-cli` #2245, #1859, #1506).
>
> Esta plantilla mantiene los agentes organizados por categoría en subcarpetas (`shared/`, `vb/`, `dotnet-framework/`) como **fuente de verdad**. El `bootstrap` copia los que aplican a tu proyecto al nivel flat. No edites las copias en `.github/agents/*.agent.md` directamente — edita las fuentes en subcarpetas y re-ejecuta el bootstrap.

### 3. Cargar el código legacy

```bash
mkdir -p legacy/
cp -r /ruta/al/codigo-legacy/* legacy/
```

### 4. Abrir VS Code

```bash
code .
```

En Copilot Chat, verifica que los agentes aparecen. **Cómo invocarlos depende del entorno:**

| Entorno | Cómo invocar |
| --- | --- |
| VS Code (Copilot Chat) | Click en el **dropdown del agent picker** y selecciona el agente. `@nombre` solo funciona para agentes built-in como `@workspace`. |
| Visual Studio 2026 (18.4+) | `@nombre` directo en el input del chat |
| GitHub Copilot CLI | `/agent <nombre>` o argumento `--agent` |
| GitHub.com (Copilot cloud agent) | Dropdown en la página de Agents |

Si los agentes no aparecen: `Cmd/Ctrl+Shift+P` → "Developer: Reload Window".

### 5. Ejecutar el flujo

Sigue `NEXT-STEPS.md` que generó el bootstrap, o consulta `docs/methodology/00-overview.md`.

---

## Agentes incluidos

### Compartidos (cualquier tecnología) — `.github/agents/shared/`

- `business-case-analyst` — Fase 0. TCO, ROI, riesgo, ejecutivo.
- `security-assessor` — Fase 0. Análisis whitehat de seguridad sobre `legacy/`.
- `modernization-strategy` — Fase 3. **Nuevo.** 6R's de Gartner + sub-flujo Windows desktop (desktop/web, contenedores, Kubernetes).
- `plan-refiner` — Fase 2.5. **Nuevo.** Refina scope con el usuario: features descartados, gaps, reglas modificadas.
- `migration-tester` — Fase 5. **Nuevo.** Tests de paridad sistemáticos + cobertura + reporte.
- `cloud-architect` — Fase 6. Arquitectura cloud multi-proveedor con ADRs.
- `azure-architect` — Fase 6. Azure específico: Mermaid + precios validados con Retail Prices API.

### Específicos por tecnología

- **VB** (`.github/agents/vb/`): `vb-assessment` · `vb-planning` · `vb-migration`
- **.NET Framework** (`.github/agents/dotnet-framework/`): `dotnet-assessment` · `dotnet-planning` · `dotnet-migration`
- Otras tecnologías: usar templates en `.github/agents/_templates/`.

### Modelos sugeridos

| Tipo de tarea | Modelo | Por qué |
| --- | --- | --- |
| Assessment, business case, planning, strategy, refinement | Claude Opus 4.6 | Razonamiento profundo + trade-offs |
| Migration (refactor de código) | Claude Sonnet 4.6 | Velocidad + precisión iterativa |
| Testing | Claude Sonnet 4.6 | Generación masiva de tests |
| Security assessment, cloud architecture | Claude Opus 4.6 | Análisis adversarial |

Override en `.copilot-project.yml` o en el frontmatter del agente.

---

## Estructura del repo

```
legacy-modernization-playbook/
├── README.md / README.en.md
├── bootstrap.sh / bootstrap.ps1        Adaptación interactiva (no se autoelimina)
├── docs/
│   ├── methodology/                    Metodología agnóstica (7 fases)
│   ├── shared/                         Lecciones, anti-patrones (transversal)
│   └── technologies/
│       ├── vb/                         Completo
│       ├── dotnet-framework/           Completo
│       ├── cobol/                      Placeholder
│       ├── java/                       Placeholder
│       └── python/                     Placeholder
├── assessment/                          Outputs Fase 0 por proyecto
├── testing/                             Outputs Fase 5 (parity, coverage, gaps)
├── cloud-architectures/                Outputs Fase 6 por proveedor
├── .github/
│   ├── agents/
│   │   │   <-- aquí van las COPIAS flat que Copilot descubre (las genera bootstrap)
│   │   ├── shared/                     Fuente de verdad: 7 agentes transversales
│   │   ├── vb/                         Fuente de verdad: 3 agentes VB
│   │   ├── dotnet-framework/           Fuente de verdad: 3 agentes .NET FX
│   │   └── _templates/                 Plantillas para nuevas tecnologías
│   ├── instructions/                   Custom instructions por capa/stack
│   └── prompts/                        Prompts reusables
├── workshop/                           Labs prácticos
├── scripts/                            Utilidades (md2html, etc.)
└── legacy/                             (vacío) código del cliente
```

---

## Filosofía

- **7 fases en orden estricto.** Cada fase produce el insumo de la siguiente. Saltar fases genera retrabajo predecible.
- **Plan Refinement (2.5) es obligatorio.** El plan generado por `vb-planning` / `dotnet-planning` casi siempre tiene gaps que solo el usuario que trabaja con el cliente puede resolver. Saltarlo significa migrar código muerto.
- **Modernization Strategy es decisión consciente, no default.** Cada sistema requiere su recomendación de 6R. No todo se Refactoriza. No todo va a Kubernetes.
- **Testing es fase explícita, no apéndice de Execution.** Tiene su agente, su cobertura objetivo y su reporte de paridad.
- **Tecnología-agnóstica en el núcleo.** El qué, cuándo y por qué son iguales para VB, COBOL, Java o Python; cambia el cómo táctico.
- **Cada decisión arquitectónica es un ADR.** Sin ADR la decisión no existe más adelante.
- **El código legacy es la fuente de verdad.** Documentación y memoria del equipo son aproximaciones.
- **Copilot acelera, no reemplaza.** El agente propone; el humano decide.

---

## Lo que NO es esta plantilla

- **No es promesa de migración automática.** Sistemas con OCX propietarios, dependencias de mainframe o lógica oculta en BD requieren decisiones humanas documentadas en ADR.
- **No es convertidor de sintaxis.** Para conversión 1:1 línea por línea hay herramientas comerciales más baratas y específicas.
- **No incluye samples de código legacy.** El código del cliente va en `legacy/`.
- **No estima duración del proyecto.** La estimación se hace en propuesta comercial, fuera del alcance de la metodología.
- **No vende cloud ni Kubernetes.** El agente `modernization-strategy` decide si y dónde tiene sentido contenerizar, basándose en criterios objetivos.

---

## Validación local antes de usar con cliente

Antes de usar la plantilla con un cliente real, ejecuta el checklist:

```bash
cat VALIDATION-CHECKLIST.md
```

Cubre: bootstrap funcional en Linux/Mac/Windows, agentes descubribles por Copilot, sanity check de cada agente nuevo, ejecución de un ciclo end-to-end con código de muestra.

---

## Lecciones aprendidas

Versión completa en [`docs/shared/lecciones-aprendidas.md`](docs/shared/lecciones-aprendidas.md). Resumen:

1. El business case (Fase 0) salva proyectos del primer recorte presupuestal.
2. **Plan Refinement (Fase 2.5) ahorra meses de migración inútil.** El cliente sabe qué código ya no se usa, pero solo lo dice si se le pregunta sistemáticamente.
3. El assessment es 30% del trabajo total, no el 5% que la mayoría asume.
4. Componentes legacy bloqueados (OCX, COM, EJB 2.x, IDMS) no se migran: se reemplazan con arquitectura alternativa documentada en ADR.
5. Copilot inventa comportamiento cuando el `.md` del feature está incompleto. Solución: forzarlo a leer el código legacy fuente.
6. **Los tests de paridad NO son los mismos tests que escribe el agente de migración.** Por eso `migration-tester` es agente separado: aporta perspectiva adversarial.
7. Una solución target separada evita corromper el proyecto legacy y permite mantenerlo compilable durante la transición.
8. Compile-and-test entre capas detecta errores de inmediato en vez de acumularlos hasta el final.
9. La arquitectura cloud (Fase 6) requiere disciplina propia. App moderna en hosting legacy no es modernización. **Kubernetes no es default — es decisión específica con criterios.**

---

## Contribuir

Si has modernizado un sistema con esta metodología y tienes lecciones nuevas o trampas no documentadas, abre issue. Especialmente buscamos:

- Casos reales de COBOL, Java legacy, Python 2 → poblar placeholders.
- Arquitecturas cloud en AWS y GCP equivalentes a las de Azure.
- Reportes de uso de `modernization-strategy` con decisiones que NO fueron Refactor (Retire, Replatform, Rebuild) para enriquecer el árbol de decisión.
- Datasets de paridad legacy-vs-migrado para hacer `migration-tester` más robusto.

---

## Licencia

MIT — usa libremente, atribuye si quieres.
