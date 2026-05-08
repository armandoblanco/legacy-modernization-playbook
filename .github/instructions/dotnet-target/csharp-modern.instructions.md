---
description: Convenciones de C# moderno (.NET 8/9) para código migrado desde .NET Framework legacy
applyTo: src/**/*.cs
---

# C# Moderno — Estilo y convenciones (.NET 8/9)

> Estas reglas aplican al código **migrado** o **nuevo** en `src/`. NO aplican a `legacy/` (read-only).

## Lenguaje

- **C# 12+**, `LangVersion=latest` en `Directory.Build.props`.
- **Nullable reference types habilitados** en toda la solución (`<Nullable>enable</Nullable>`). No usar `!` salvo casos justificados con comentario.
- **`ImplicitUsings=enable`**.
- **File-scoped namespaces** (`namespace Foo;`) — un solo nivel de indentación.
- **Records** para DTOs y value objects (`public record CustomerDto(int Id, string Name);`).
- **Primary constructors** para clases simples cuando reduce ruido.
- **Pattern matching** y **switch expressions** sobre `if/else` largos.
- **`global using`** en un archivo `GlobalUsings.cs` por proyecto, no esparcidos.

## Async / concurrencia

- Métodos I/O: `async Task<T>` / `async ValueTask<T>` (ValueTask solo si hay path síncrono frecuente).
- **Sufijo `Async`** obligatorio en métodos asíncronos públicos.
- **Nunca** `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` en código de aplicación.
- `ConfigureAwait(false)` en librerías reutilizables (no en apps ASP.NET Core, donde no aplica).
- Pasar `CancellationToken` por parámetro en cualquier operación cancelable.
- Para CPU-bound: `Task.Run` solo en bordes (controlador, host).

## Errores y resultados

- **No `try/catch` decorativo.** Solo capturar lo que sabes manejar.
- Para flujo de negocio **esperable** (validación, no encontrado, conflicto): usar **Result pattern** (`OneOf<TSuccess, TError>` o `ErrorOr<T>` o tipo propio). Excepciones son para lo **excepcional**.
- **Nunca** `catch (Exception)` sin re-lanzar o registrar contexto.
- Excepciones custom heredan de `Exception` (no de `ApplicationException`).
- **Prohibido** `BinaryFormatter` en cualquier forma. Usar `System.Text.Json` (default) o `MessagePack`.

## Logging

- **`ILogger<T>`** vía constructor DI. No `Console.WriteLine`, no `Debug.WriteLine`, no `log4net.LogManager.GetLogger`.
- **Source-generated logging** (`[LoggerMessage]`) en hot-paths.
- Mensajes con **structured logging** (`_logger.LogInformation("User {UserId} logged in", userId)`), no concatenación.
- Niveles: Trace/Debug (dev), Information (eventos), Warning (recuperable), Error (operación falló), Critical (sistema en riesgo).
- **No registres PII** (passwords, tokens, PAN, datos personales identificables) en logs.

## Configuración

- **`IConfiguration`** + **`IOptions<T>`** / **`IOptionsSnapshot<T>`**. NUNCA `ConfigurationManager`.
- Secretos en **User Secrets** (dev), **Azure Key Vault** (prod), o variables de entorno. Nunca en `appsettings.json` versionado.
- POCO de configuración con validación: `services.AddOptions<MyOptions>().Bind(...).ValidateDataAnnotations().ValidateOnStart()`.

## DI / IoC

- **Microsoft.Extensions.DependencyInjection** (no Unity, no Castle Windsor, no SimpleInjector salvo decisión documentada).
- **Constructor injection** únicamente. No service locator (`IServiceProvider.GetService`) fuera de composition root.
- Lifetimes correctos: `Singleton` (sin estado mutable), `Scoped` (por request/operation), `Transient` (caro de mantener vivo).
- Una interfaz por capacidad. Evitar interfaces "marker" sin métodos.

## Datos / EF Core

- `DbContext` registrado como `Scoped`. Inyectar el `DbContext`, no `IDbContextFactory<T>` salvo en código sin scope (background workers).
- **Async** siempre: `ToListAsync`, `FirstOrDefaultAsync`, `SaveChangesAsync`.
- **`AsNoTracking()`** por defecto en queries de solo lectura.
- **Sin lazy loading proxies** salvo decisión explícita en ADR. Usar `Include` / projections.
- **Nunca** concatenar SQL. Usar parámetros / `FromSqlInterpolated`.
- Migrations: una migración por cambio funcional, mensaje descriptivo.

## API Web (ASP.NET Core)

- **Minimal APIs** o **Controllers** según consistencia del proyecto (no mezclar arbitrariamente).
- Validación con **FluentValidation** o **DataAnnotations** + `ValidationProblemDetails`.
- **Problem Details** (RFC 7807) para errores HTTP.
- **OpenAPI** (`Microsoft.AspNetCore.OpenApi` o Swashbuckle) en todas las APIs.
- Versioning con `Asp.Versioning.Http`.
- **No HttpContext.Current**. Inyectar `IHttpContextAccessor` solo en servicios que realmente lo necesitan.

## Seguridad

- **Autenticación** vía ASP.NET Core Identity + IdP externo (Entra ID, Auth0). No construir IdP propio.
- **Autorización** con `[Authorize]` y políticas (`AddAuthorization(o => o.AddPolicy(...))`).
- **HTTPS obligatorio** (`UseHttpsRedirection`, `UseHsts`).
- **CORS** restrictivo, no `AllowAnyOrigin` en producción.
- **Anti-forgery** habilitado en formularios server-rendered.
- **Cookies**: `HttpOnly=true`, `Secure=true`, `SameSite=Lax|Strict`.
- **Headers de seguridad**: CSP, X-Content-Type-Options, Referrer-Policy (NWebsec o middleware propio).

## Testing

- **xUnit** como framework default. **NUnit** solo si el legacy ya lo usa pesadamente.
- **FluentAssertions** para aserciones legibles.
- **NSubstitute** o **Moq** para mocks (uno solo, consistente en el repo).
- **Testcontainers** para integración con BD/colas reales en CI.
- **WebApplicationFactory<T>** para tests de integración HTTP.
- Cobertura objetivo: **70% líneas / 80% branches** en lógica de negocio (no en infra ni controllers triviales).

## Estilo

- **`.editorconfig`** con `dotnet_diagnostic.CAxxxx.severity=error` para reglas críticas.
- **`dotnet format`** ejecutable y verificado en CI.
- **Nombres**: `PascalCase` (tipos, métodos, propiedades), `camelCase` (locales, parámetros), `_camelCase` (private fields), `IPascalCase` (interfaces).
- **Una clase por archivo**. Nombre de archivo == nombre de tipo.
- **Métodos cortos**: objetivo <30 líneas. Si crece, extraer.

## Prohibido en código nuevo

| Anti-patrón | Reemplazo |
|---|---|
| `BinaryFormatter` | `System.Text.Json` / MessagePack |
| `ConfigurationManager.AppSettings` | `IConfiguration` |
| `ConfigurationManager.ConnectionStrings` | `IConfiguration.GetConnectionString` |
| `HttpContext.Current` | `IHttpContextAccessor` (inyectado) |
| `ServiceLocator` / `IServiceProvider.GetService` fuera de root | Constructor injection |
| `Thread.Abort` | `CancellationToken` |
| `WebRequest` / `HttpWebRequest` | `HttpClient` (vía `IHttpClientFactory`) |
| `Newtonsoft.Json` (en código nuevo) | `System.Text.Json` (excepto si el contrato exige Newtonsoft) |
| `log4net` / `NLog` direct API | `ILogger<T>` |
| `EntityFramework` (EF6) en código nuevo | `Microsoft.EntityFrameworkCore` |
| `System.Web.*` | ASP.NET Core equivalente |
| `AppDomain.CreateDomain` | `AssemblyLoadContext` |
| `Remoting` | gRPC / REST |

## Ejemplo canónico

```csharp
namespace Acme.Customers.Application;

public sealed class GetCustomerByIdHandler(
    ICustomerRepository repository,
    ILogger<GetCustomerByIdHandler> logger)
{
    public async Task<ErrorOr<CustomerDto>> HandleAsync(
        int customerId,
        CancellationToken cancellationToken)
    {
        var customer = await repository.FindAsync(customerId, cancellationToken);
        if (customer is null)
        {
            logger.LogInformation("Customer {CustomerId} not found", customerId);
            return Errors.Customer.NotFound;
        }

        return new CustomerDto(customer.Id, customer.Name);
    }
}
```
