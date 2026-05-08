---
applyTo: "src/{{ProjectName}}.WinForms/**/*.{cs,Designer.cs,resx}"
description: Convenciones para WinForms .NET 8 en migración VB legacy → .NET 8
---

# Convenciones WinForms .NET 8

Aplica si el ADR-001 eligió `winforms` como stack target. WinForms en .NET 8 NO es 100% compatible con WinForms .NET Framework 4.8 — hay diferencias sutiles en algunos controles que se documentan abajo.

---

## Estructura de carpetas

```
src/{{ProjectName}}.WinForms/
├── Program.cs                       Entry point, DI, Generic Host
├── Forms/
│   ├── MainForm.cs + .Designer.cs   Form principal (típicamente MDI o tabs)
│   ├── <Feature>/
│   │   ├── <Feature>ListForm.cs + .Designer.cs
│   │   └── <Feature>EditForm.cs + .Designer.cs
├── UserControls/                    Componentes reutilizables
├── Services/                        Helpers de UI (DialogService, etc.)
└── Resources/                       Iconos, imágenes, textos
```

---

## Forms

### Reglas obligatorias

1. **Heredar de `Form`** o `UserControl` según el caso
2. **Inyección por constructor** de servicios y casos de uso
3. **Nullable reference types habilitado** y respetado
4. **Code-behind solo coordina UI** — sin lógica de negocio
5. **Designer.cs NO se edita manualmente** salvo para corregir nullable warnings
6. **Form scoped o transient** según uso (transient para forms efímeros, scoped para forms persistentes con estado)

### Ejemplo de Form correcto

```csharp
namespace {{ProjectName}}.WinForms.Forms.Clientes;

public partial class ClientesListaForm : Form
{
    private readonly BuscarClientesUseCase _buscarClientes;
    private readonly ILogger<ClientesListaForm> _logger;
    private readonly BindingList<ClienteDto> _clientesBinding = new();

    public ClientesListaForm(
        BuscarClientesUseCase buscarClientes,
        ILogger<ClientesListaForm> logger)
    {
        ArgumentNullException.ThrowIfNull(buscarClientes);
        ArgumentNullException.ThrowIfNull(logger);

        _buscarClientes = buscarClientes;
        _logger = logger;

        InitializeComponent();
        dataGridView1.DataSource = _clientesBinding;
        dataGridView1.AutoGenerateColumns = false;
    }

    private async void btnBuscar_Click(object? sender, EventArgs e)
    {
        // async void permitido SOLO en event handlers
        try
        {
            await BuscarAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error en búsqueda de clientes");
            MessageBox.Show("Error al buscar. Ver log para detalles.", 
                "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private async Task BuscarAsync()
    {
        btnBuscar.Enabled = false;
        Cursor = Cursors.WaitCursor;
        try
        {
            var query = new BuscarClientesQuery { Nombre = txtFiltro.Text };
            var result = await _buscarClientes.ExecuteAsync(query, 
                CancellationToken.None);

            if (!result.IsSuccess)
            {
                _logger.LogWarning("Búsqueda falló: {Error}", result.Error);
                return;
            }

            _clientesBinding.Clear();
            foreach (var cliente in result.Value!)
                _clientesBinding.Add(cliente);
        }
        finally
        {
            btnBuscar.Enabled = true;
            Cursor = Cursors.Default;
        }
    }
}
```

Notas:
- `async void` SOLO en event handlers (regla absoluta)
- `try/catch` en event handlers async (sino las excepciones tumban el AppDomain)
- `BindingList<T>` para data binding mutable a DataGridView
- Cursor de espera + disable de botón para evitar doble-click
- Inyección por constructor de servicios e ILogger

---

## DI con Generic Host

`Program.cs`:

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;

namespace {{ProjectName}}.WinForms;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        ApplicationConfiguration.Initialize();

        var host = Host.CreateDefaultBuilder()
            .UseSerilog((ctx, cfg) => cfg
                .ReadFrom.Configuration(ctx.Configuration)
                .WriteTo.File("logs/log-.txt", rollingInterval: RollingInterval.Day)
                .WriteTo.Console())
            .ConfigureServices((ctx, services) =>
            {
                // Application + Infrastructure
                services.AddDbContext<{{ProjectName}}DbContext>(opt =>
                    opt.UseSqlServer(ctx.Configuration.GetConnectionString("DB")));
                services.AddScoped<IClienteRepository, ClienteRepository>();
                services.AddScoped<BuscarClientesUseCase>();

                // WinForms
                services.AddSingleton<MainForm>();
                services.AddTransient<Forms.Clientes.ClientesListaForm>();
            })
            .Build();

        var mainForm = host.Services.GetRequiredService<MainForm>();
        Application.Run(mainForm);
    }
}
```

`appsettings.json` en root del proyecto, marcado como `Copy to Output: Always` en `.csproj`.

---

## Marshaling al hilo UI

WinForms es single-threaded UI. Cualquier modificación de controles desde otro hilo requiere `Invoke`:

```csharp
private async Task ProcesarEnSegundoPlanoAsync()
{
    var resultado = await Task.Run(() => CalcularLargo());

    // Después de await en async, ya estamos de vuelta en UI thread (SynchronizationContext)
    txtResultado.Text = resultado.ToString();
}

// Si se invoca desde thread sin SynchronizationContext:
private void DesdeThreadExterno(string mensaje)
{
    if (InvokeRequired)
    {
        Invoke(() => DesdeThreadExterno(mensaje));
        return;
    }
    txtMensaje.Text = mensaje;
}
```

**Trampa común:** dentro de `ContinueWith` o callbacks de hilos POCO (ej. timers de `System.Threading.Timer`), `InvokeRequired == true`. Olvidar el check produce `InvalidOperationException`.

---

## Mapeo VB legacy → WinForms .NET 8

### Desde VB6

| VB6 control | WinForms .NET 8 | Notas |
| --- | --- | --- |
| `Form` | `Form` | Heredar de `Form` |
| `MDIForm` | `Form` con `IsMdiContainer = true` | MDI sigue funcionando |
| `Frame` | `GroupBox` o `Panel` | |
| `TextBox` | `TextBox` | |
| `Label` | `Label` | |
| `CommandButton` | `Button` | |
| `OptionButton` | `RadioButton` | |
| `CheckBox` | `CheckBox` | |
| `ComboBox` | `ComboBox` | API cambia: `Items.Add` y `SelectedItem` |
| `ListBox` | `ListBox` | Igual |
| `MSFlexGrid` | `DataGridView` | API completamente distinta |
| `Picture Box` | `PictureBox` | |
| `Timer` | `System.Windows.Forms.Timer` | NO `System.Timers.Timer` (ese es no-UI) |
| `MSCAL Calendar` | `MonthCalendar` o `DateTimePicker` | |

### Desde VB.NET WinForms

Mayormente 1:1, pero atender:

| VB.NET WinForms | WinForms .NET 8 |
| --- | --- |
| `Application.DoEvents()` | NO usar (anti-patrón en .NET moderno) |
| `My.Application.OpenForms` | `Application.OpenForms` |
| `Me.MdiChildren` | `this.MdiChildren` |
| `BackgroundWorker` | `Task.Run` + `IProgress<T>` |
| `Settings.Default.Save()` | `IConfiguration` + custom persistence |

---

## Diferencias importantes WinForms .NET 4.8 → .NET 8

WinForms en .NET 8 tiene cambios de comportamiento que deben atenderse:

1. **High DPI por default.** En .NET 4.8 había que activarlo. En .NET 8 está activo. Forms diseñados para 96 DPI fijo pueden verse mal escalados.
   ```csharp
   ApplicationConfiguration.Initialize();  // Configura high DPI
   ```
2. **Nullable warnings en Designer.cs** generado. Apagar warnings o regenerar designer files.
3. **`DataGridView` con virtualización**: comportamiento sutilmente distinto al cargar con `DataSource = lista`.
4. **`MaskedTextBox`** y otros controles antiguos: comportamiento ligeramente distinto en validación.
5. **OLE drag-drop**: API igual, pero el comportamiento en algunos casos cambió.

**Recomendación:** después de migrar a .NET 8, hacer pase específico de UI testing antes de declarar done.

---

## Manejo de OCX bloqueados (solo VB6)

Si la app legacy usa OCX que NO se migran (Crystal Reports, LeadTools, PISPEC):

```csharp
private async void btnGenerarReporte_Click(object? sender, EventArgs e)
{
    // ADR-XXX: Crystal Reports reemplazado por servicio de reportería externo.
    // Pendiente integración con servicio.
    MessageBox.Show(
        "Funcionalidad de reportes en migración. Ver ADR-XXX.",
        "Pendiente",
        MessageBoxButtons.OK,
        MessageBoxIcon.Information);
}
```

NO dejar `throw new NotImplementedException()` en event handler de UI sin try/catch — tumba la app. Mostrar mensaje al usuario.

---

## Lo prohibido

- ❌ Lógica de negocio en code-behind del Form
- ❌ Acceso directo a DbContext desde Form (vía servicios)
- ❌ `Application.DoEvents()` (anti-patrón)
- ❌ Llamadas síncronas a casos de uso async (`.Result`, `.Wait()` — deadlock)
- ❌ Modificar controles desde otro thread sin `Invoke`
- ❌ `MessageBox.Show` para errores en bucles (genera N mensajes; loggear y mostrar resumen)
- ❌ Strings hardcoded de UI: usar `.resx` si hay i18n
- ❌ Forms con >2000 líneas (refactorizar en UserControls)
- ❌ Designer-generated code editado a mano salvo nullable warnings
