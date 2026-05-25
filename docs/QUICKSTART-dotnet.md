# Quickstart: .NET Framework 2.0-4.8

Guía rápida para modernizar un sistema en .NET Framework (WebForms, WCF, ASP.NET MVC clásico, Windows Services) a .NET 8 o .NET 9 usando el playbook.

---

## Cuándo usar esta guía

Tu sistema legacy es .NET Framework si:

- El `.csproj` tiene `<TargetFrameworkVersion>v4.x</TargetFrameworkVersion>` o `<TargetFramework>net4x</TargetFramework>`
- Hay `packages.config` (no `PackageReference`)
- Usa WebForms (`.aspx`), WCF (`.svc`), ASMX, o ASP.NET MVC 4/5
- Hay `Global.asax`, `Web.config` con secciones grandes, o `app.config` con `<system.serviceModel>`
- Depende de `System.Web.*` o `Microsoft.AspNet.*`

Si en cambio tu legacy es VB6 / VB.NET, usa los agentes `@vb-*` (ver README principal).

---

## Pre-requisitos

1. **GitHub Copilot** habilitado en tu cuenta o organización
2. **VS Code** con la extensión GitHub Copilot Chat
3. **.NET 8 SDK** o **.NET 9 SDK** instalado localmente
4. Acceso al código fuente del sistema legacy (no solo binarios)

---

## Setup del proyecto

```bash
git clone https://github.com/armandoblanco/legacy-modernization-playbook.git mi-proyecto
cd mi-proyecto
rm -rf .git && git init

./bootstrap.sh      # Linux/macOS/WSL
.\bootstrap.ps1     # Windows
```

En el bootstrap, elige:

- **Tecnología legacy:** `dotnet-framework`
- **Stack target:** según assessment posterior (ASP.NET Core, Worker Service, Blazor, etc.): el bootstrap no fuerza esta decisión, se toma en Fase 2

Coloca el código del sistema legacy:

```bash
mkdir -p legacy/
cp -r /ruta/al/sistema-dotnet-framework/* legacy/
```

---

## Flujo de 3 agentes

### Fase 1: Assessment

```text
@dotnet-assessment Analiza el sistema en legacy/
```

Detecta:

- Versión de .NET Framework actual y dependencias
- Tipo de aplicación (WebForms, WCF, MVC clásico, Windows Service, Console)
- APIs deprecadas o removidas en .NET 8+ (`System.Web.HttpContext`, `WCF service host`, `Remoting`, `AppDomain.CreateDomain`, etc.)
- Paquetes NuGet legacy y su equivalente moderno
- Configuración en `Web.config` / `app.config` que no migra 1:1
- Tests existentes y framework usado

Produce:

```
docs/
├── README.md
├── SUMMARY.md
├── dependency-graph.md
└── features/
    └── ...               (un .md por feature funcional)

docs/inventory/
├── projects.md           Inventario de .csproj con tipo y versión
├── nuget-packages.md     Paquetes con análisis de compatibilidad .NET 8
├── deprecated-apis.md    APIs problemáticas para migración
└── config-sections.md    Secciones de Web.config / app.config
```

### Fase 2: Planning

```text
@dotnet-planning Revisa el assessment y planifica la migración
```

Pregunta al usuario decisiones clave:

- **Target framework:** .NET 8 LTS vs .NET 9 (default: .NET 8 LTS por estabilidad)
- **Tipo de proyecto target:**
  - WebForms → Blazor Server, ASP.NET Core MVC, o Razor Pages
  - WCF SOAP → CoreWCF (si SOAP no es negociable) o gRPC / REST
  - ASP.NET MVC 5 → ASP.NET Core MVC (mecánico)
  - Windows Service → Worker Service
- **Estrategia de migración:** in-place upgrade (.NET Upgrade Assistant) o greenfield
- **Manejo de dependencias bloqueantes:** librerías sin versión .NET 8 (caso por caso)
- **Hosting target:** IIS, Kestrel standalone, contenedor, Azure App Service

Produce:

```
docs/
├── ARQUITECTURA-TARGET.md
├── migration-plan.md
└── adr/
    ├── ADR-001-target-framework.md         .NET 8 LTS
    ├── ADR-002-tipo-proyecto-target.md     ASP.NET Core MVC (vs Blazor)
    ├── ADR-003-wcf-replacement.md          CoreWCF / gRPC / REST según caso
    ├── ADR-004-config-strategy.md          appsettings.json + DI Options pattern
    ├── ADR-005-orm-strategy.md             EF Core 8
    ├── ADR-006-auth-strategy.md            Migración de Forms Auth / Windows Auth a ASP.NET Core Identity
    ├── ADR-007-logging-strategy.md         Serilog / ILogger
    └── ADR-008-upgrade-vs-greenfield.md    Estrategia elegida con justificación
```

### Fase 3: Migration

```text
@dotnet-migration Ejecuta la migración del sistema legacy
```

Ejecuta:

- Si la decisión fue **in-place upgrade**: aplica `.NET Upgrade Assistant`, migra `packages.config` → `PackageReference`, actualiza target framework, refactoriza APIs deprecadas caso por caso
- Si fue **greenfield**: crea solución nueva en `src/` con estructura ASP.NET Core moderna y migra feature por feature

Genera:

```
src/
├── MiProyecto.sln
├── MiProyecto.Api/                  ASP.NET Core endpoints
├── MiProyecto.Application/          Use cases + DTOs
├── MiProyecto.Domain/               Entities + Value Objects
├── MiProyecto.Infrastructure/       EF Core, External APIs
└── MiProyecto.Tests/
    ├── UnitTests/
    └── IntegrationTests/            Con WebApplicationFactory + Testcontainers
```

Reporta tabla de "Done" por proyecto y feature.

---

## Casos especiales

### Sistema con mezcla WebForms + ASP.NET MVC clásico

Migración a ASP.NET Core MVC unificado. Los flujos WebForms se reescriben como controllers + Razor views o Blazor pages según ADR-002.

### Sistema con WCF expuesto a clientes externos

Tres opciones según el ADR-003:

1. **CoreWCF** si los clientes externos no pueden cambiar (contratos SOAP intactos, atado a una librería relativamente nueva pero menos mainstream)
2. **gRPC** si los clientes son internos y se pueden actualizar (mejor performance, fuerte tipado)
3. **REST + OpenAPI** si los clientes pueden adoptar HTTP/JSON (más mainstream, ecosistema amplio)

### Sistema con dependencias NuGet sin versión .NET 8

El agente las identifica en `docs/inventory/nuget-packages.md`. Por cada una, la Fase 2 genera un ADR con la decisión:

- Buscar alternativa moderna equivalente
- Mantener la versión legacy si compila contra `netstandard2.0` (compatibilidad)
- Reescribir la funcionalidad internamente si no hay alternativa viable

### Web.config con custom config sections

El agente migra las secciones estándar a `appsettings.json`. Las custom sections (`ConfigurationSection` clases) se reescriben como `IOptions<T>` con el pattern moderno.

---

## Documentación complementaria

- **Trampas técnicas:** [`docs/technologies/dotnet-framework/trampas-dotnet-framework.md`](technologies/dotnet-framework/trampas-dotnet-framework.md)
- **Convenciones de código:** [`.github/instructions/dotnet-target/csharp-modern.instructions.md`](../.github/instructions/dotnet-target/csharp-modern.instructions.md)
- **Prompts adicionales:** [`.github/prompts/dotnet-framework/`](../.github/prompts/dotnet-framework/)
- **Workshop:** [`workshop/dotnet-framework/lab-01-assessment/`](../workshop/dotnet-framework/lab-01-assessment/)
