# Catálogo de agentes Copilot

Lista completa de agentes incluidos en el playbook, con prompts de ejemplo y referencia al archivo de definición.

Todos los agentes se invocan desde GitHub Copilot Chat en VS Code con la sintaxis `@<nombre-agente> <prompt>`.

---

## Agentes compartidos (cualquier tecnología)

### `@business-case-analyst`

**Fase 0: Construye el caso de negocio del proyecto.**

Entrevista al usuario, estima TCO actual del legacy, calcula ROI esperado de la modernización, evalúa riesgos, y produce un resumen ejecutivo para el cliente. Todos los entregables en versión Markdown + HTML autocontenido (offline).

Archivo: [`.github/agents/shared/00-business-case.agent.md`](../.github/agents/shared/00-business-case.agent.md)

Prompts típicos:

```text
@business-case-analyst Construye el caso de negocio para mi proyecto
```

```text
@business-case-analyst Estima el TCO del sistema legacy comparado con la versión modernizada
```

```text
@business-case-analyst Genera el resumen ejecutivo para presentar al sponsor
```

Outputs en `assessment/{ProjectName}/`:
- `tco-actual-DDMMYYYY.{md,html}`
- `roi-DDMMYYYY.{md,html}`
- `riesgo-DDMMYYYY.{md,html}`
- `ejecutivo-DDMMYYYY.{md,html}`

---

### `@security-assessor`

**Fase 0: Análisis de seguridad whitehat del código legacy.**

Revisa el código en `legacy/` desde la perspectiva de un atacante: vulnerabilidades comunes (SQL injection, XSS, deserialización insegura, hardcoded secrets, criptografía débil), dependencias con CVEs conocidas, y configuraciones inseguras.

Archivo: [`.github/agents/shared/02-security-assessor.agent.md`](../.github/agents/shared/02-security-assessor.agent.md)

Prompts típicos:

```text
@security-assessor Revisa la seguridad del código en legacy/
```

```text
@security-assessor Enfócate en la capa de autenticación y manejo de sesiones
```

```text
@security-assessor Genera el reporte de findings con clasificación CVSS
```

Output: `assessment/{ProjectName}/seguridad-DDMMYYYY.{md,html}`

---

### `@azure-architect`

**Fase 4: Diseña arquitectura cloud target en Azure con precios validados.**

Produce diagrama Mermaid, lista de servicios Azure recomendados, ADRs de cada decisión arquitectónica, IaC base, y costos estimados validados contra Azure Retail Prices API (no inventa precios).

Archivo: [`.github/agents/shared/05-azure-architect.agent.md`](../.github/agents/shared/05-azure-architect.agent.md)

Prompts típicos:

```text
@azure-architect Diseña la arquitectura cloud para MiProyecto en Azure
```

```text
@azure-architect Compara opciones de hosting: App Service vs Container Apps vs AKS
```

```text
@azure-architect Estima el costo mensual del entorno productivo según el ADR-001
```

```text
@azure-architect Genera el Bicep para desplegar la arquitectura aprobada
```

Output: `cloud-architectures/azure/`

---

## Agentes Visual Basic (VB6 + VB.NET)

### `@vb-assessment`

**Fase 1: Analiza un sistema VB6 o VB.NET legacy.**

Detecta automáticamente si es VB6 o VB.NET. Inventaria formularios, módulos, clases. Clasifica OCX/COM (VB6) o APIs deprecadas (VB.NET). Extrae reglas de negocio implícitas. Detecta dependencias entre módulos.

Archivo: [`.github/agents/vb/01-vb-assessment.agent.md`](../.github/agents/vb/01-vb-assessment.agent.md)

Prompts típicos:

```text
@vb-assessment Analiza el sistema en legacy/
```

```text
@vb-assessment Empieza por el módulo de facturación y profundiza en sus dependencias
```

```text
@vb-assessment Identifica todos los OCX usados y clasifícalos por criticidad
```

Output: `docs/features/`, `docs/dependency-graph.md`, `docs/SUMMARY.md`

---

### `@vb-planning`

**Fase 2: Diseña arquitectura target y produce ADRs.**

Lee el assessment de Fase 1, pregunta decisiones críticas (stack target, replacement de OCX bloqueantes, ORM, framework MVVM, patrón arquitectónico), y documenta cada decisión como ADR.

Archivo: [`.github/agents/vb/02-vb-planning.agent.md`](../.github/agents/vb/02-vb-planning.agent.md)

Prompts típicos:

```text
@vb-planning Revisa el assessment y planifica la migración
```

```text
@vb-planning Quiero discutir el target: WPF vs Blazor vs WinForms moderno
```

```text
@vb-planning Genera el ADR para reemplazar el OCX de SigPlusNET
```

Output: `docs/ARQUITECTURA-TARGET.md`, `docs/adr/`, `docs/migration-plan.md`

---

### `@vb-migration`

**Fase 3: Ejecuta la migración del sistema legacy a C# moderno.**

Lee `ARQUITECTURA-TARGET.md` y los ADRs, sigue el orden topológico del plan, genera código en `src/` con tests embebidos (Domain, Application, Parity). Trabaja feature por feature con compile-and-test entre capas.

Archivo: [`.github/agents/vb/03-vb-migration.agent.md`](../.github/agents/vb/03-vb-migration.agent.md)

Prompts típicos:

```text
@vb-migration Ejecuta la migración del sistema legacy
```

```text
@vb-migration Empieza por el feature autenticación
```

```text
@vb-migration Continúa con el siguiente feature del plan
```

```text
@vb-migration Reporta el estado actual de la migración con tabla de "Done" por feature
```

Output: `src/` (estructura Clean Architecture), `migration/migration-log.md`, `migration/parity-report.md`

---

## Agentes .NET Framework (2.0-4.8)

### `@dotnet-assessment`

**Fase 1: Analiza un sistema .NET Framework legacy.**

Detecta versión actual, tipo de proyecto (WebForms, WCF, MVC, Service), paquetes NuGet legacy con análisis de compatibilidad .NET 8, APIs deprecadas, configuración en `Web.config` que no migra 1:1.

Archivo: [`.github/agents/dotnet-framework/01-dotnet-assessment.agent.md`](../.github/agents/dotnet-framework/01-dotnet-assessment.agent.md)

Prompts típicos:

```text
@dotnet-assessment Analiza el sistema en legacy/
```

```text
@dotnet-assessment Identifica las dependencias NuGet sin versión .NET 8
```

```text
@dotnet-assessment Analiza específicamente el módulo de WCF y sus contratos
```

---

### `@dotnet-planning`

**Fase 2: Diseña target y produce ADRs.**

Decisiones: target framework (.NET 8 LTS vs 9), tipo de proyecto target, estrategia de WCF (CoreWCF vs gRPC vs REST), upgrade in-place vs greenfield, hosting target.

Archivo: [`.github/agents/dotnet-framework/02-dotnet-planning.agent.md`](../.github/agents/dotnet-framework/02-dotnet-planning.agent.md)

Prompts típicos:

```text
@dotnet-planning Revisa el assessment y planifica la migración
```

```text
@dotnet-planning Decidamos si vamos upgrade in-place o greenfield
```

```text
@dotnet-planning Genera el ADR de reemplazo de WCF
```

---

### `@dotnet-migration`

**Fase 3: Ejecuta migración a .NET 8/9.**

Aplica `.NET Upgrade Assistant` si la decisión fue in-place. Para greenfield: bootstrap ASP.NET Core, migra feature por feature.

Archivo: [`.github/agents/dotnet-framework/03-dotnet-migration.agent.md`](../.github/agents/dotnet-framework/03-dotnet-migration.agent.md)

Prompts típicos:

```text
@dotnet-migration Ejecuta la migración del sistema legacy
```

```text
@dotnet-migration Migra los servicios WCF a CoreWCF según el ADR-003
```

```text
@dotnet-migration Reporta cobertura de tests post-migración
```

---

## Agentes Java legacy

### Sub-stack J2EE

#### `@j2ee-assessment`

**Fase 1: Analiza sistema J2EE clásico (EJB + JSP + WebLogic/WebSphere).**

Archivo: [`.github/agents/java/j2ee-assessment.agent.md`](../.github/agents/java/j2ee-assessment.agent.md)

```text
@j2ee-assessment Analiza el sistema en legacy/
```

```text
@j2ee-assessment Profundiza en los Entity Beans CMP y su mapeo a JPA
```

#### `@j2ee-planning`

**Fase 2: Diseña target Spring Boot 3 o Quarkus + ADRs.**

Archivo: [`.github/agents/java/j2ee-planning.agent.md`](../.github/agents/java/j2ee-planning.agent.md)

```text
@j2ee-planning Diseña la arquitectura target para MiProyecto
```

```text
@j2ee-planning Discutamos cómo manejamos los Stateful Session Beans
```

#### `@j2ee-migration`

**Fase 3: Ejecuta migración a Spring Boot 3 + Java 21.**

Archivo: [`.github/agents/java/j2ee-migration.agent.md`](../.github/agents/java/j2ee-migration.agent.md)

```text
@j2ee-migration Ejecuta la migración según los ADRs aprobados
```

```text
@j2ee-migration Empieza por el feature autenticación
```

---

### Sub-stack Spring legacy

#### `@spring-legacy-assessment`

**Fase 1: Analiza Spring 3.x/4.x + Struts + Java 6/7/8.**

Archivo: [`.github/agents/java/spring-legacy-assessment.agent.md`](../.github/agents/java/spring-legacy-assessment.agent.md)

```text
@spring-legacy-assessment Analiza el sistema en legacy/
```

```text
@spring-legacy-assessment Cuenta los archivos afectados por el namespace change jakarta
```

#### `@spring-legacy-planning`

**Fase 2: Decide upgrade in-place vs greenfield + ADRs.**

Archivo: [`.github/agents/java/spring-legacy-planning.agent.md`](../.github/agents/java/spring-legacy-planning.agent.md)

```text
@spring-legacy-planning Diseña target para MiProyecto
```

```text
@spring-legacy-planning Discutamos upgrade in-place vs greenfield
```

#### `@spring-legacy-migration`

**Fase 3: Ejecuta migración con OpenRewrite + Hibernate 6.**

Archivo: [`.github/agents/java/spring-legacy-migration.agent.md`](../.github/agents/java/spring-legacy-migration.agent.md)

```text
@spring-legacy-migration Ejecuta la migración según los ADRs
```

```text
@spring-legacy-migration Empieza por el namespace change con OpenRewrite
```

---

### Sub-stack Oracle Forms

#### `@oracle-forms-assessment`

**Fase 1: Analiza Forms (.fmb extraídos a XML), PLLs, packages BD.**

Archivo: [`.github/agents/java/oracle-forms-assessment.agent.md`](../.github/agents/java/oracle-forms-assessment.agent.md)

```text
@oracle-forms-assessment Analiza el sistema Oracle Forms en legacy/extracted/
```

```text
@oracle-forms-assessment ¿Cómo extraigo los .fmb a XML?
```

#### `@oracle-forms-planning`

**Fase 2: Decide Java vs APEX + dónde vive la lógica + pilot del módulo más complejo.**

Archivo: [`.github/agents/java/oracle-forms-planning.agent.md`](../.github/agents/java/oracle-forms-planning.agent.md)

```text
@oracle-forms-planning Diseña target para MiProyecto
```

```text
@oracle-forms-planning Quiero discutir Java vs APEX antes de continuar
```

#### `@oracle-forms-migration`

**Fase 3: Ejecuta pilot primero, después escala al resto. Genera tests de paridad.**

Archivo: [`.github/agents/java/oracle-forms-migration.agent.md`](../.github/agents/java/oracle-forms-migration.agent.md)

```text
@oracle-forms-migration Ejecuta el pilot según docs/pilot-spec.md
```

```text
@oracle-forms-migration Continúa con el siguiente feature después del pilot exitoso
```

---

## Modelos recomendados

Cada agente declara su modelo recomendado en el frontmatter. Puedes override en `.copilot-project.yml` o cambiando `model:` en el agente.

| Tipo de tarea | Modelo recomendado | Por qué |
| --- | --- | --- |
| Assessment, business case | **Claude Opus 4.6** | Razonamiento profundo en análisis de código complejo |
| Planning, ADRs | **Claude Opus 4.6** | Razonamiento estructurado y trade-offs |
| Migration (refactor de código) | **Claude Sonnet 4.6** | Velocidad + precisión en transformaciones iterativas |
| Security assessment | **Claude Opus 4.6** | Análisis adversarial |
| Cloud architecture | **Claude Opus 4.6** | Trade-offs y validación de precios |

---

## Prompts adicionales (slash commands)

Además de los agentes, hay prompts reusables en `.github/prompts/` que se invocan con `/` en Copilot Chat:

- **Compartidos:** [`.github/prompts/shared/`](../.github/prompts/shared/): business case, validar precios Azure, etc.
- **VB:** [`.github/prompts/vb/`](../.github/prompts/vb/): analizar-feature, generar-adr, migrar-modulo, validar-paridad
- **.NET Framework:** [`.github/prompts/dotnet-framework/`](../.github/prompts/dotnet-framework/)
- **Java:** [`.github/prompts/java/`](../.github/prompts/java/): analizar-modulo, generar-adr, migrar-modulo, validar-paridad
