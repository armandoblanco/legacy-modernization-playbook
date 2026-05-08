# .NET Framework legacy → .NET 8/9 — Guía técnica

> Conocimiento específico de la tecnología que complementa los agentes `@dotnet-assessment`, `@dotnet-planning` y `@dotnet-migration`.

## ¿Cuándo usar este suite?

Esta guía aplica a **proyectos en .NET Framework 2.0 a 4.8**, típicamente con:
- `.csproj` legacy (`<Project ToolsVersion="...">`, no SDK-style)
- `packages.config` (no `<PackageReference>`)
- Mezcla de ASP.NET MVC 5, WebForms, WCF, WinForms, Servicios Windows, librerías compartidas.

**No es para:**
- Proyectos ya en `.NET 5/6/7+` → usar el agente oficial **`@modernize-dotnet`** de Microsoft.
- Proyectos ya en SDK-style con `<PackageReference>` y .NET 6+ → usar **`@modernize-dotnet`** + `dotnet-upgrade-assistant`.
- Proyectos VB6 / VB.NET → usar el suite `vb/` (`@vb-assessment`, etc.).

## Stack target recomendado (default conservador)

| Capa | Recomendación default | Alternativas |
|---|---|---|
| Runtime | **.NET 8 LTS** (soporte hasta 11/2026) | .NET 9 STS si el cliente actualiza ágil |
| Project format | **SDK-style + Central Package Management** | SDK-style sin CPM si <5 proyectos |
| Web framework | **ASP.NET Core MVC** o **Razor Pages** | Blazor Server (si hay que reemplazar WebForms) |
| Data access | **EF Core 8** | Dapper si EF6 era pesadilla; mantener EF6 transitorio si aplica |
| Auth | **ASP.NET Core Identity + Entra ID externo** | Auth0 / Okta |
| Logging | **Serilog + ILogger\<T\> + OpenTelemetry** | NLog si ya está en uso pesado |
| DI | **Microsoft.Extensions.DI** | — |
| Mensajería | **Azure Service Bus** o **RabbitMQ** | MassTransit como abstracción |
| Cache | **Redis (StackExchange.Redis)** | IMemoryCache para estado local |
| Config | **IConfiguration + Azure Key Vault** | User Secrets en dev |
| Tests | **xUnit + FluentAssertions + NSubstitute + Testcontainers** | NUnit si legacy ya lo usa |
| CI/CD | **GitHub Actions** o **Azure DevOps Pipelines** | — |

## Decision stack — preguntas que debe responder Fase 2

1. ¿`.NET 8 LTS` o `.NET 9 STS`? → ADR-0001
2. ¿In-place o side-by-side por proyecto? → ADR-0002
3. ¿Qué hacer con WCF servidor? CoreWCF / gRPC / REST → ADR-0003
4. ¿WebForms se reemplaza por Blazor Server / Razor Pages / MVC? → ADR-0004
5. ¿EF6 → EF Core all-at-once o por bounded context? → ADR-0005
6. ¿Identity con IdP externo (Entra ID) o stack propio? → ADR-0006
7. ¿Multi-target temporal `net48;net8.0`? ¿Hasta cuándo? → ADR-0012
8. ¿COM Interop / OCX cómo se aislan? → ADR-0011
9. ¿MSMQ → Service Bus / RabbitMQ? → ADR-0010

## Trampas comunes (.NET Framework legacy)

### `BinaryFormatter` (CRÍTICO de seguridad)
- **Por qué duele:** RCE remota en cualquier deserialización no confiable. Bloqueado por defecto en .NET 5+.
- **Detección:** `grep -r "BinaryFormatter\|IFormatter" src/`.
- **Solución:** `System.Text.Json` para nuevos formatos; `MessagePack` si necesitas binario compacto. Si hay datos persistidos en disco/BD con BinaryFormatter, escribir un **converter one-shot** que los re-serialice durante una migración offline.

### `ConfigurationManager` muy acoplado
- **Por qué duele:** miles de llamadas estáticas dispersas. Incompatible con `IConfiguration` directo.
- **Solución progresiva:** crear un `LegacyConfig` adapter que internamente usa `IConfiguration` pero expone `string Get(string key)` igual que el legacy. Migrar consumers gradualmente.

### `HttpContext.Current`
- **Por qué duele:** estático en `System.Web`, no existe en ASP.NET Core.
- **Solución:** `IHttpContextAccessor` inyectado, pero **no lo uses como muleta global** — extrae solo lo que necesitas (`Request.Headers`, `User`) en el border y pásalo limpio.

### EF6 → EF Core: trampas
- `EntityState.Detached` se comporta distinto.
- `Database.SqlQuery<T>(...)` no existe igual; usar `FromSqlInterpolated`.
- `DbModelBuilder` (EF6) ≠ `ModelBuilder` (EF Core), API similar pero no idéntica.
- Lazy loading: en EF Core requiere `Microsoft.EntityFrameworkCore.Proxies` y propiedades virtuales **explícitas**.
- Migrations: empezar baseline desde cero (no portar migrations de EF6).
- Connection resiliency: hay que opt-in (`EnableRetryOnFailure`).
- `IncludeFilter` (EF6) → `Where` dentro de `Include` con sintaxis diferente.

### WCF servidor → CoreWCF
- **CoreWCF** preserva contratos `[ServiceContract]` y `[OperationContract]`.
- **No soporta**: WSFederation, Reliable Sessions complex, MSMQ binding (deprecate).
- **Sí soporta**: BasicHttpBinding, NetTcpBinding, NetNamedPipeBinding (parcial), WSHttpBinding.
- Cliente WCF antiguo puede seguir consumiendo WSDL generado por CoreWCF — **valida con un cliente real**.

### Unity (DI legacy)
- Deprecado oficialmente. Migrar a `Microsoft.Extensions.DependencyInjection`.
- Las features no soportadas: `ResolveAll`, named registrations complejas, interceptors. Reemplazar interceptors con `DispatchProxy` o un decorator manual.

### `log4net` configurado en `Web.config`
- Migrar a Serilog con configuración en `appsettings.json` o builder fluido.
- Mapear appenders: RollingFileAppender → Serilog.Sinks.File con rolling; SmtpAppender → Serilog.Sinks.Email; AdoNetAppender → Serilog.Sinks.MSSqlServer.

### `<system.web>` de `Web.config`
- En ASP.NET Core ya no existe. Las equivalencias:
  - `<httpRuntime maxRequestLength>` → `IISOptions.MaxRequestBodySize` o `KestrelServerOptions.Limits`
  - `<authentication mode="Forms">` → `AddAuthentication().AddCookie()`
  - `<sessionState>` → `AddSession()`
  - `<customErrors>` → middleware `UseExceptionHandler` + Problem Details

### COM Interop / OCX
- Si el OCX es x86, no puedes ejecutarlo en proceso x64 / AnyCPU.
- **Patrón aislamiento**: proceso "shim" en .NET Framework 4.8 (x86) que expone gRPC/named pipes hacia el moderno.
- **Plan de salida**: ADR de retiro del OCX cuando regulación lo permita.

### `AppDomain.CreateDomain` para plug-ins
- No soportado en .NET Core+.
- Reemplazar con **`AssemblyLoadContext`** (collectible).

### MSMQ
- Funciona en .NET 8 vía `System.Messaging` package, pero está en mantenimiento.
- Migrar a Azure Service Bus / RabbitMQ con MassTransit como abstracción.

## Lecciones aprendidas

- **Empezar por libs hoja.** Migrar la app web primero condena al equipo a multi-target eterno.
- **Tests de caracterización primero.** Sin red de seguridad, cualquier refactor introduce regresiones invisibles.
- **CPM (Central Package Management) desde el día 1.** Solucionar conflictos de versión en 30 proyectos sin CPM es ingeniería de la nostalgia.
- **No mezcles upgrade + redesign.** Modernizar la sintaxis primero (paridad), redesignar después (mejora). Mezclarlos hace imposible aislar regresiones.
- **El plan vive y muere por el ADR.** Sin ADR, los devs re-discuten lo mismo 3 veces y eligen distinto cada vez.
- **El cliente no quiere `Kubernetes`.** Quiere el sistema funcionando en .NET 8 con su mismo SLA. Resiste el over-engineering de Fase 4.

## Comparación con agentes externos

| Agente | Cuándo usar | Cuándo NO |
|---|---|---|
| **`@dotnet-assessment` / `@dotnet-planning` / `@dotnet-migration` (este suite)** | .NET Framework 2.0–4.8 con packages.config y mezcla WCF/WebForms/EF6 | Proyecto ya en .NET 6+ |
| **`@modernize-dotnet`** (Microsoft, oficial) | SDK-style + .NET 6+ → .NET 8/9 | .NET Framework legacy con bloqueantes severos |
| **`@dotnet-upgrade`** (awesome-copilot) | Upgrades versión a versión modernos | Migración cross-paradigm (System.Web → ASP.NET Core) |
| **`@modernization`** (awesome-copilot, stack-agnostic) | Visión por feature en cualquier stack | Cuando necesitas decisiones específicas de .NET (este suite las tiene) |

## Referencias canónicas

- [.NET Framework → .NET migration overview](https://learn.microsoft.com/dotnet/core/porting/)
- [.NET Upgrade Assistant](https://github.com/dotnet/upgrade-assistant)
- [try-convert](https://github.com/dotnet/try-convert)
- [CoreWCF](https://github.com/CoreWCF/CoreWCF)
- [GitHub Copilot app modernization for .NET](https://learn.microsoft.com/dotnet/core/porting/github-copilot-app-modernization/)
