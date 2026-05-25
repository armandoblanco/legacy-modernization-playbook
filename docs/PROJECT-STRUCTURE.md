# Estructura del repo

Este documento explica carpeta por carpeta qué contiene el repo y cuándo se usa cada cosa.

---

## Top level

```
legacy-modernization-playbook/
├── README.md / README.en.md            Portada del repo
├── bootstrap.sh / bootstrap.ps1        Adapta la plantilla a tu proyecto
├── TODO.md                              Roadmap pendiente del repo
├── .github/                             Agentes, prompts e instructions de Copilot
├── docs/                                Metodología, guías, tecnologías
├── assessment/                          Outputs de Fase 0 (business case + seguridad)
├── cloud-architectures/                 Outputs de Fase 4 (cloud)
├── scripts/                             Utilidades (md2html para entregables offline)
├── workshop/                            Labs prácticos por tecnología
└── legacy/                              Código del cliente (read-only, se crea con bootstrap)
```

---

## `.github/`

Donde viven los componentes de Copilot. La estructura es:

```
.github/
├── agents/
│   ├── _templates/                     Plantillas para crear agentes nuevos
│   ├── shared/                         Agentes transversales
│   │   ├── 00-business-case.agent.md         @business-case-analyst
│   │   ├── 02-security-assessor.agent.md     @security-assessor
│   │   ├── 04-cloud-architect.agent.md       @cloud-architect (multi-cloud)
│   │   └── 05-azure-architect.agent.md       @azure-architect (Azure específico)
│   ├── vb/                             Agentes Visual Basic
│   │   ├── 01-vb-assessment.agent.md         @vb-assessment
│   │   ├── 02-vb-planning.agent.md           @vb-planning
│   │   └── 03-vb-migration.agent.md          @vb-migration
│   ├── dotnet-framework/               Agentes .NET Framework
│   │   ├── 01-dotnet-assessment.agent.md
│   │   ├── 02-dotnet-planning.agent.md
│   │   └── 03-dotnet-migration.agent.md
│   └── java/                           Agentes Java (3 sub-stacks)
│       ├── j2ee-{assessment,planning,migration}.agent.md
│       ├── spring-legacy-{assessment,planning,migration}.agent.md
│       └── oracle-forms-{assessment,planning,migration}.agent.md
├── instructions/
│   ├── _templates/
│   ├── shared/                         testing-strategy (pirámide, Testcontainers, paridad)
│   ├── vb-target/                      csharp / winforms / wpf-mvvm / blazor
│   ├── dotnet-target/                  csharp-modern (.NET 8/9)
│   └── java-target/                    spring-boot-3 / quarkus / jpa-hibernate
└── prompts/
    ├── shared/                         business case, validar-precios-azure, etc.
    ├── vb/                             analizar-feature, generar-adr, migrar-modulo, validar-paridad
    ├── dotnet-framework/
    └── java/
```

### Cómo el bootstrap usa esto

Cuando corres `./bootstrap.sh` y eliges una tecnología, el script:

1. Copia los agentes del sub-stack elegido (3 agentes) más los compartidos (3-4) a `.github/agents/` plano para que Copilot los descubra
2. Opcionalmente elimina las subcarpetas de otras tecnologías (`vb`, `dotnet-framework`, `java`) para mantener el repo limpio del proyecto del cliente
3. Ajusta `.github/instructions/<tech>-target/` para dejar solo el stack target elegido

---

## `docs/`

Donde van los outputs de los agentes y la documentación del playbook.

```
docs/
├── README.md
├── PHILOSOPHY.md                       Filosofía, lecciones, qué NO es esta plantilla
├── AGENTS.md                           Catálogo de agentes con prompts ejemplo
├── PROJECT-STRUCTURE.md                Este archivo
├── QUICKSTART-dotnet.md                Quickstart .NET Framework
├── QUICKSTART-java.md                  Quickstart Java legacy
├── methodology/                        Metodología agnóstica
│   ├── 00-overview.md
│   ├── 01-business-case.md             Fase 0
│   ├── 02-assessment-planning-execution.md   Fases 1, 2, 3
│   └── 05-cloud-deployment.md          Fase 4
├── shared/                             Lecciones, anti-patrones (transversal)
└── technologies/                       Catálogo por tecnología
    ├── README.md
    ├── vb/                             Trampas VB6/VBNet, decision-stack
    ├── dotnet-framework/               Trampas .NET Framework
    ├── java/                           Trampas J2EE / Spring legacy / Oracle Forms + comparativa SB3 vs Quarkus
    ├── cobol/                          Placeholder
    └── python/                         Placeholder
```

### Outputs por fase (se generan en proyectos reales)

Cuando los agentes corren, agregan documentos a `docs/`:

#### Después de Fase 1 (Assessment)

```
docs/
├── README.md                           Índice maestro (actualizado por agente)
├── SUMMARY.md                          Resumen ejecutivo
├── dependency-graph.md                 Grafo Mermaid + orden topológico
└── features/
    └── <NN>-<feature-name>.md          Un .md por feature funcional
```

Para sistemas grandes, también:

```
docs/inventory/                          Inventarios técnicos (no funcionales)
├── projects.md         (.NET) o forms.md (Oracle) o ejbs.md (J2EE)
├── ...
```

#### Después de Fase 2 (Planning)

```
docs/
├── ARQUITECTURA-TARGET.md              Stack target + mapping legacy → moderno
├── migration-plan.md                   Orden de migración con dependencias
└── adr/
    └── ADR-NNN-<decision-slug>.md      Un ADR por decisión arquitectónica
```

Para Oracle Forms adicionalmente:

```
docs/pilot-spec.md                      Especificación del módulo pilot
```

#### Después de Fase 3 (Migration)

```
src/                                     Código moderno (la mayor parte del trabajo)
migration/
├── migration-log.md                    Bitácora de migración por feature
├── blockers-found.md                   Bloqueos no anticipados con propuestas
└── parity-report.md                    Reporte de tests de paridad
```

---

## `assessment/`

Outputs de Fase 0 (Business Case + Security) por proyecto.

```
assessment/
├── _templates/                         Plantillas tco-actual, roi, riesgo, ejecutivo, seguridad
└── {ProjectName}/
    ├── tco-actual-DDMMYYYY.{md,html}
    ├── roi-DDMMYYYY.{md,html}
    ├── riesgo-DDMMYYYY.{md,html}
    ├── ejecutivo-DDMMYYYY.{md,html}
    └── seguridad-DDMMYYYY.{md,html}
```

Cada entregable se genera en Markdown + HTML autocontenido (CSS embebido, sin dependencias externas) usando `scripts/md2html.py`. El HTML se puede enviar al cliente offline.

---

## `cloud-architectures/`

Outputs de Fase 4: arquitectura cloud target.

```
cloud-architectures/
├── README.md
├── _templates/                         Plantilla de ADR cloud
├── azure/                              5 patrones documentados + @azure-architect
│   ├── README.md
│   ├── pattern-01-app-service-sql.md
│   ├── pattern-02-container-apps.md
│   ├── pattern-03-aks-microservices.md
│   ├── pattern-04-functions-eventgrid.md
│   ├── pattern-05-hybrid-arc.md
│   └── prices-lookup-guide.md         Cómo validar precios con Retail Prices API
└── on-premise/                         Patrón on-premise / híbrido
```

Cuando se corre `@azure-architect`, agrega en `cloud-architectures/azure/{ProjectName}/`:

```
cloud-architectures/azure/{ProjectName}/
├── ARQUITECTURA-CLOUD.md               Diagrama Mermaid + servicios elegidos
├── adr-cloud/                          ADRs específicos de cloud
├── pricing-estimate.md                 Costos validados vía Retail Prices API
└── iac/                                Bicep / Terraform base
```

---

## `workshop/`

Labs prácticos por tecnología. Se usan en entrenamientos internos o para validar el playbook con casos sintéticos.

```
workshop/
├── shared/
│   ├── lab-00-business-case/
│   └── lab-04-cloud/
├── vb/
│   └── lab-01-assessment/
└── dotnet-framework/
    └── lab-01-assessment/
```

---

## `scripts/`

```
scripts/
├── md2html.sh                          Bash wrapper
└── md2html.py                          Genera HTML autocontenido offline desde .md
```

Se usa para producir versiones HTML de los entregables (business case, security, ARQUITECTURA-TARGET, ADRs) que se pueden enviar al cliente sin dependencias.

---

## `legacy/`

Se crea con el bootstrap si no existe. **El código fuente del cliente va acá.**

Reglas:

1. Read-only para los agentes
2. No commitear secretos (limpia connection strings, API keys)
3. Respeta la estructura original (`.sln`, `.csproj`, `pom.xml`, descriptores XML)
4. Anonimiza datos sensibles según regulación

Si el legacy es muy grande o propietario, deja un `LEGACY_LOCATION.md` con la ruta del snapshot analizado.

---

## `src/`

Se crea cuando empieza Fase 3. **El código moderno va acá.**

La estructura específica depende del stack target y del patrón arquitectónico elegido en el ADR-006 (o equivalente):

- Clean Architecture (Domain + Application + Infrastructure + UI)
- Hexagonal (Domain + Ports + Adapters)
- Capas tradicionales (Presentation + Business + Data)

El agente de Fase 3 genera la estructura según el ADR.

---

## `migration/`

Se crea cuando empieza Fase 3. Contiene la bitácora del trabajo:

```
migration/
├── migration-log.md                    Qué se migró, cuándo, con qué decisiones
├── blockers-found.md                   Bloqueos no anticipados encontrados
├── parity-notes.md                     Notas para el agente de tests de paridad
└── parity-report.md                    Reporte final de tests de paridad
```

Es útil para auditoría posterior y para que un nuevo miembro del equipo entienda decisiones tomadas durante la migración.
