---
applyTo: "src/**/*.{cs,razor,cshtml}"
description: Convenciones para Blazor Server / ASP.NET Core en migración VB legacy → .NET 8
---

# Convenciones Blazor / ASP.NET Core

Aplica si el ADR-001 eligió `blazor` (Blazor Server) o ASP.NET Core MVC como stack target.

**Importante:** elegir Blazor para una migración VB legacy NO es elección por moda. Si la app legacy es desktop puro con dependencias hardware (impresoras, scanners, OCX), Blazor NO es opción válida. Ver `docs/03-decision-stack.md` para criterios.

---

## Estructura de carpetas

### Blazor Server

```
src/{{ProjectName}}.Web/
├── Program.cs                       Entry point, DI, middleware
├── App.razor                        Root component
├── appsettings.json
├── appsettings.Development.json
├── Components/
│   ├── Layout/
│   │   ├── MainLayout.razor
│   │   └── NavMenu.razor
│   └── Shared/                      Componentes reutilizables
├── Pages/                           (rutas con @page)
│   ├── <Feature>/
│   │   ├── <Feature>List.razor
│   │   ├── <Feature>Detail.razor
│   │   └── <Feature>Edit.razor
├── Services/                        Servicios scoped (UI-side)
├── ViewModels/                      Si se separa estado de Razor (opcional)
└── wwwroot/                         CSS, JS, imágenes estáticas
```

### ASP.NET Core MVC

```
src/{{ProjectName}}.Web/
├── Program.cs
├── appsettings.json
├── Controllers/
├── Views/
│   ├── Shared/
│   └── <Feature>/
├── ViewModels/
├── Services/
└── wwwroot/
```

**Recomendación:** Blazor Server sobre MVC para migraciones VB legacy donde la app era stateful (formularios complejos con estado en memoria). MVC para flujos request-response simples.

---

## Componentes Razor

### Reglas obligatorias

1. **Componentes pequeños y enfocados.** Un componente Razor con >300 líneas es señal de que necesita dividirse.
2. **Code-behind separado** para lógica:
   ```
   Pages/Clientes/ClienteList.razor
   Pages/Clientes/ClienteList.razor.cs
   ```
3. **`@inject` para servicios**, NO `new` manual
4. **`@code` en `.razor` mínimo**: solo binding triviales; lógica en `.razor.cs`
5. **State management explícito**: para state compartido, usar servicios scoped, NO singletons
6. **CSS isolation**: `ClienteList.razor.css` para estilos del componente

### Ejemplo correcto

`Pages/Clientes/ClienteList.razor`:

```razor
@page "/clientes"
@inject NavigationManager Navigation
@inherits ClienteListBase

<PageTitle>Clientes</PageTitle>

<div class="filters">
    <input @bind="FiltroNombre" @bind:event="oninput" placeholder="Buscar..." />
    <button @onclick="BuscarAsync" disabled="@IsBusy">Buscar</button>
</div>

@if (IsBusy)
{
    <p>Cargando...</p>
}
else if (Clientes is null || Clientes.Count == 0)
{
    <p>Sin resultados.</p>
}
else
{
    <table>
        <thead>
            <tr><th>ID</th><th>Nombre</th><th>Email</th></tr>
        </thead>
        <tbody>
            @foreach (var c in Clientes)
            {
                <tr @key="c.Id">
                    <td>@c.Id</td>
                    <td>@c.Nombre</td>
                    <td>@c.Email</td>
                </tr>
            }
        </tbody>
    </table>
}
```

`Pages/Clientes/ClienteList.razor.cs`:

```csharp
using Microsoft.AspNetCore.Components;
using {{ProjectName}}.Application.UseCases.Clientes;

namespace {{ProjectName}}.Web.Pages.Clientes;

public class ClienteListBase : ComponentBase
{
    [Inject] protected BuscarClientesUseCase BuscarClientes { get; set; } = default!;
    [Inject] protected ILogger<ClienteListBase> Logger { get; set; } = default!;

    protected string FiltroNombre { get; set; } = string.Empty;
    protected bool IsBusy { get; set; }
    protected IReadOnlyList<ClienteDto>? Clientes { get; set; }

    protected async Task BuscarAsync()
    {
        if (IsBusy) return;
        IsBusy = true;
        try
        {
            var result = await BuscarClientes.ExecuteAsync(
                new BuscarClientesQuery { Nombre = FiltroNombre },
                CancellationToken.None);

            if (result.IsSuccess)
                Clientes = result.Value;
            else
                Logger.LogWarning("Búsqueda falló: {Error}", result.Error);
        }
        finally
        {
            IsBusy = false;
        }
    }
}
```

Notas:
- Code-behind como `ComponentBase`, el `.razor` hace `@inherits`
- `@inject` vía propiedades protegidas, NO en `@code`
- `@key` en loops para optimización de re-render
- `[Inject]` con `default!` para satisfacer nullable enabled

### Lo prohibido

- ❌ Lógica de negocio en `@code` del `.razor`
- ❌ `JSRuntime.InvokeAsync` desde lógica de negocio (solo desde UI helpers específicos)
- ❌ Singletons para state mutable (usar Scoped)
- ❌ `Task.Wait` o `.Result` (deadlock garantizado en Blazor Server)
- ❌ `StateHasChanged` manual sin razón clara (Blazor lo maneja)
- ❌ Eventos `onclick` con código inline largo: extraer a método

---

## Mapeo de patrones VB legacy → Blazor

### Sistema legacy con formularios MDI (VB6 / VB.NET WinForms)

**Antes:** ventana principal MDI con hijos (formularios) que se abren dentro.

**Migración a Blazor:**
- MainLayout con NavMenu lateral
- Cada "form hijo" se convierte en una página con `@page "/<feature>"`
- Navegación con `NavigationManager`
- State compartido vía servicios scoped si necesario

**Trampa:** el MDI tradicional permitía tener varios formularios abiertos simultáneamente. Blazor (web) no replica esto naturalmente. Si el cliente usa eso intensivamente, considerar tabs en Blazor o reconsiderar el stack.

### Sistema legacy con WebForms (VB.NET)

**Antes:** páginas `.aspx` con `code-behind` `.aspx.vb`, ViewState, eventos server-side.

**Migración a Blazor:** mucho más natural que desde desktop, pero con cambios:

| WebForms | Blazor |
| --- | --- |
| `<asp:TextBox>` | `<input @bind="Property">` |
| `<asp:Button onClick=...>` | `<button @onclick="Handler">` |
| `<asp:GridView>` | `<table>` con `@foreach`, o componente custom |
| `<asp:Repeater>` | `@foreach` |
| `<asp:Validator>` | `EditForm` + `DataAnnotations` o componente FluentValidation |
| `Page_Load` | `OnInitializedAsync` o `OnParametersSetAsync` |
| ViewState | State explícito en componente o servicio |
| PostBack | Re-renderizado automático de Blazor |

**Trampa de migración:** WebForms managers ViewState automáticamente. Blazor requiere pensar el estado explícitamente. Migración 1:1 sin repensar es problema.

### Reportería (Crystal Reports en VB6/VB.NET WebForms)

Crystal Reports embedido NO existe naturalmente en Blazor. Alternativas:

1. **Generar PDFs server-side** con QuestPDF, FastReport.NET, o iTextSharp y servirlos como descarga
2. **Reportes inline** con componentes Razor para visualización + opción de export
3. **Microservicio de reportería** separado (si hay >50 reportes complejos)

ADR específico para reportería es casi siempre necesario.

---

## Datos y servicios

### Inyección de dependencias

`Program.cs`:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Configuración
builder.Services.Configure<DatabaseOptions>(
    builder.Configuration.GetSection("Database"));

// Logging
builder.Host.UseSerilog((ctx, cfg) => cfg
    .ReadFrom.Configuration(ctx.Configuration)
    .Enrich.FromLogContext());

// Application + Infrastructure
builder.Services.AddDbContext<{{ProjectName}}DbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("DB")));

builder.Services.AddScoped<IClienteRepository, ClienteRepository>();
builder.Services.AddScoped<BuscarClientesUseCase>();

// Blazor
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

var app = builder.Build();

app.UseStaticFiles();
app.UseAntiforgery();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
```

### Lifetimes

- **Singleton:** servicios sin estado, configuración inmutable
- **Scoped:** repositorios, casos de uso, DbContext, servicios con estado de usuario
- **Transient:** servicios stateless livianos

**En Blazor Server, "scoped" = duración del circuito (conexión SignalR), NO request HTTP.** Esto es crítico:

- Un usuario abre la app → 1 circuito → 1 scope
- DbContext scoped vive todo lo que dure la conexión del usuario
- Si esto es problema (memory, connections), usar `IDbContextFactory<T>` y crear contextos efímeros

---

## Autenticación y autorización

Para sistemas que migran de VB.NET WebForms con Forms Authentication:

```csharp
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/login";
        options.AccessDeniedPath = "/forbidden";
    });

builder.Services.AddAuthorization();
builder.Services.AddCascadingAuthenticationState();
```

En componentes:

```razor
@attribute [Authorize]
@attribute [Authorize(Roles = "Admin")]

<AuthorizeView>
    <Authorized>
        <p>Hola @context.User.Identity!.Name</p>
    </Authorized>
    <NotAuthorized>
        <p>Inicia sesión.</p>
    </NotAuthorized>
</AuthorizeView>
```

Para sistemas con AD interno: agregar `Microsoft.AspNetCore.Authentication.Negotiate` para Windows Auth.

---

## Performance

### Lo que se subestima

1. **Re-renderizado innecesario.** Cada `StateHasChanged` re-renderiza el componente. Usar `@key` en loops y `ShouldRender()` cuando sea necesario.
2. **Componentes grandes.** Dividir en sub-componentes mejora rendering parcial.
3. **Listas grandes.** Para >500 filas, usar `Virtualize` component:
   ```razor
   <Virtualize Items="@items" Context="item">
       <ItemRow Item="@item" />
   </Virtualize>
   ```
4. **Conexión SignalR perdida.** En redes inestables, configurar reconexión automática y mostrar UI durante desconexión.

### Limitaciones de Blazor Server

- **Latencia entre cliente y servidor:** cada interacción es round-trip. UX feels lento si servidor está lejos.
- **Concurrencia:** N circuitos simultáneos = N scopes consumiendo memoria/conexiones BD. Para apps con >5000 usuarios concurrentes, evaluar Blazor WebAssembly.
- **Offline:** Blazor Server NO funciona offline. Requiere conexión persistente.

Si alguna de estas limitaciones es problema para el cliente, reconsiderar el stack.

---

## Lo prohibido

- ❌ Lógica de negocio en componentes Razor (mover a Application layer)
- ❌ Acceso directo a DbContext desde componentes (siempre vía repositorios o casos de uso)
- ❌ Mantener estado de aplicación en servicios singleton mutables
- ❌ `JSInterop` para resolver problemas que se resuelven en C#
- ❌ Componentes con >5 parámetros: refactorizar a record `Parameters`
- ❌ `Task.Run` para operaciones IO-bound (solo CPU-bound)
- ❌ Sincronización manual con `lock` en Blazor Server (cada circuito es single-threaded)
- ❌ Strings hardcoded de UI: usar `IStringLocalizer<T>` si hay i18n
