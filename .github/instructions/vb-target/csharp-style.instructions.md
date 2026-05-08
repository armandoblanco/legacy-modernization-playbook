---
applyTo: "**/*.cs"
description: Estilo y convenciones de código C# para el proyecto de migración VB6 → .NET 8
---

# Convenciones de código C# en migración VB6 → .NET 8

Este archivo define cómo se debe escribir C# en la solución migrada. Aplica a todo archivo `.cs` en `migrated/`.

## Versión de lenguaje

- **C# 12** (`<LangVersion>12</LangVersion>` en `Directory.Build.props`)
- **Nullable reference types habilitado** globalmente
- **ImplicitUsings habilitado**
- **File-scoped namespaces** siempre (`namespace App.Domain;` no `namespace App.Domain { }`)

## Naming

- **Clases, structs, records, enums:** `PascalCase` (ej: `ClienteService`, `OrderStatus`)
- **Métodos públicos:** `PascalCase` (ej: `CalcularComision`)
- **Métodos privados:** `PascalCase` también (no usar `_camelCase`)
- **Parámetros y variables locales:** `camelCase`
- **Campos privados:** `_camelCase` con prefijo underscore
- **Constantes:** `PascalCase` (no `SCREAMING_CASE`)
- **Interfaces:** prefijo `I` + `PascalCase` (ej: `IUsuarioRepository`)
- **Genéricos:** `T` solo o `TNombreDescriptivo` (ej: `TEntity`)

## Visibilidad

- **Default `internal`**, no `public` por defecto
- Solo marcar `public` cuando es API pública del proyecto (assembly boundary)
- `private` para campos y métodos internos
- `sealed` por default en clases que no se diseñan para herencia

## Tipos

- **`record` para DTOs y value objects** sin comportamiento
- **`class` para entidades** con identidad y comportamiento
- **`struct` solo para tipos pequeños inmutables y value-semantic** (raro)
- **`record struct` para value objects pequeños** (preferir sobre `struct` clásico)

## Async

- **`Async` suffix** en métodos asíncronos: `GetClienteAsync`, `SaveAsync`
- **`CancellationToken` end-to-end** en TODOS los métodos async
- **`ConfigureAwait(false)`** en Infrastructure (NO en UI)
- **`ValueTask` solo cuando hay evidencia de hot path**, default `Task`
- **Nunca `async void`** excepto event handlers

## Excepciones y errores

- **Result pattern en Domain y Application**: usar `Result<T>` de `App.Shared.Results`
- **Excepciones en Infrastructure**: capturar errores de IO/BD/red y convertir a `Result.Failure(...)` antes de propagar a Application
- **`ArgumentNullException.ThrowIfNull(param)`** en métodos públicos
- **Nunca `throw new Exception(...)`** sin tipo específico
- **Nunca `catch (Exception) { }`** vacío. Si necesitas suprimir, log y comentario explicativo.
- **Las excepciones DOMINIO específicas** heredan de `DomainException` base

## Comentarios

- **En español** para reglas de negocio
- **En inglés** para conceptos técnicos generales
- **Citar origen VB6** cuando se replica comportamiento heredado:
  ```csharp
  // Heredado de modSeguridad.bas L142-L168.
  // Bloqueo por 15 min después de 3 intentos en 5 min.
  ```
- **Documentación XML** (`///`) en API pública del proyecto
- **NO comentarios obvios** que repiten el código

## Logging

- **Serilog vía `ILogger<T>`** inyectado por constructor
- **Logging estructurado** siempre, NO interpolación:
  ```csharp
  // Sí
  _logger.LogInformation("Procesando cliente {ClienteId}", clienteId);
  
  // No
  _logger.LogInformation($"Procesando cliente {clienteId}");
  ```
- **Niveles correctos:**
  - `Trace`: detalle muy fino, raramente
  - `Debug`: información para developer
  - `Information`: hitos de negocio (login exitoso, transacción procesada)
  - `Warning`: situación inesperada pero recuperable
  - `Error`: error que afecta operación pero el sistema sigue
  - `Critical`: falla que afecta disponibilidad

## Validación

- **FluentValidation** para validación de DTOs/inputs en Application
- **Invariantes en constructor** de entidades de Domain
- **NO validación duplicada** entre capas
- **Cada validador en archivo separado**: `CrearClienteCommandValidator.cs`

## Acceso a datos

- **EF Core 8** para queries simples y modelo principal
- **Dapper** para queries SQL legacy complejas o con performance crítica
- **`AsNoTracking()` por default** en lecturas
- **`Include` explícito**, NO lazy loading
- **Migrations en proyecto separado** o en Infrastructure según ADR
- **Connection strings desde `IConfiguration`**, NUNCA hardcoded

## Inmutabilidad

- **Records inmutables** preferidos sobre classes mutables para datos
- **Colecciones**: `IReadOnlyList<T>` o `IReadOnlyCollection<T>` en propiedades públicas
- **Init-only setters** (`init`) en lugar de `set` cuando es posible

## Ejemplos comparativos

### Bien

```csharp
namespace App.Application.UseCases.Clientes;

internal sealed class CrearClienteUseCase(
    IClienteRepository clienteRepository,
    ILogger<CrearClienteUseCase> logger)
{
    public async Task<Result<ClienteDto>> ExecuteAsync(
        CrearClienteCommand command, 
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);
        
        logger.LogInformation("Creando cliente {Nombre}", command.Nombre);
        
        var cliente = Cliente.Create(command.Nombre, command.Email);
        if (!cliente.IsSuccess)
            return Result<ClienteDto>.Failure(cliente.Error!);
        
        await clienteRepository.AddAsync(cliente.Value!, cancellationToken)
            .ConfigureAwait(false);
        
        return Result<ClienteDto>.Success(ClienteDto.From(cliente.Value!));
    }
}
```

### Mal

```csharp
public class CrearClienteUseCase
{
    private IClienteRepository _repo;
    private ILogger _log;
    
    public CrearClienteUseCase(IClienteRepository repo, ILogger log)
    {
        _repo = repo;
        _log = log;
    }
    
    public ClienteDto Execute(string nombre, string email)
    {
        try {
            _log.LogInformation($"Creando cliente {nombre}");
            var cliente = new Cliente() { Nombre = nombre, Email = email };
            _repo.Add(cliente);
            return new ClienteDto() { Id = cliente.Id };
        } catch (Exception) { return null; }
    }
}
```

Problemas del "mal":
- No async
- No cancellationToken
- Logging no estructurado
- Constructor manual en vez de primary constructor
- Cliente con setters mutables en vez de factory method
- `catch (Exception) { }` silencioso
- Retorna `null` en vez de Result
- Visibilidad `public` por default
- No marca `sealed`
