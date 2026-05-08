# Trampas semánticas VB.NET legacy → C#/.NET 8

Este documento cataloga las diferencias entre VB.NET legacy (.NET Framework 1.1 a 4.8) y C# moderno en .NET 8 que generan bugs sutiles si se migra "directo".

**Importante:** VB.NET legacy es un lenguaje distinto a VB6, aunque comparten herencia. Si tu proyecto es VB6 puro, ve a [`04a-trampas-vb6.md`](04a-trampas-vb6.md).

VB.NET legacy tiene tres categorías de trampas:

1. **Heredadas de VB6** que sobrevivieron en VB.NET por compatibilidad
2. **Específicas de VB.NET** que no existen en VB6
3. **Específicas de .NET Framework** que cambian al pasar a .NET 8

---

## Categoría 1: Trampas heredadas de VB6

### 1.1 `Microsoft.VisualBasic.dll` — el caballo de Troya

VB.NET legacy puede usar (y casi siempre usa) las funciones de `Microsoft.VisualBasic.dll`:

```vbnet
Imports Microsoft.VisualBasic
Dim s As String = Mid("ABCDE", 1, 3)        ' "ABC" (1-based como VB6)
Dim n As Double = Val("123abc")              ' 123 (parsing flexible)
Dim r As Integer = Asc("A")                   ' 65
Dim d As Date = DateAdd(DateInterval.Day, 1, Now)
```

**El problema:** este DLL preserva la semántica VB6 dentro de un mundo .NET. Migrar a C# sin estos helpers introduce los mismos bugs documentados en `04a-trampas-vb6.md` (Mid 1-based, Val flexible, etc.).

**Solución:**

- En .NET Framework, `Microsoft.VisualBasic.dll` está en GAC; C# puede usarlo directamente:
  ```csharp
  using Microsoft.VisualBasic;
  string s = Strings.Mid("ABCDE", 1, 3);  // "ABC"
  ```
- En .NET 8, el paquete NuGet `Microsoft.VisualBasic` existe pero **no todas las funciones están disponibles**. Las de UI (`InputBox`, `MsgBox`) no están. Las de strings, números y fechas sí.
- **Recomendación:** crear `VBCompat.cs` que envuelve los helpers usados realmente, con `[Obsolete]` para reemplazo gradual.

### 1.2 `Option Strict Off` — la trampa más cara

```vbnet
Option Strict Off

Dim x As Integer = "123"           ' Coerción implícita string → int
Dim y As String = 42               ' Coerción implícita int → string
Dim obj As Object = "hola"
Dim z As Integer = obj             ' Late binding, falla solo en runtime
```

VB.NET con `Option Strict Off` permite coerciones que C# no permite. La mayoría de proyectos VB.NET legacy tienen `Option Strict Off` (default histórico hasta VS 2015).

**Cómo detectar:**

```bash
grep -r "Option Strict" --include="*.vb" .
# Si hay archivos sin línea explícita o con "Option Strict Off", asumir Off
```

**El problema al migrar:** cualquier código que dependía de coerciones implícitas se convierte en errores de compilación en C#. Y peor: detectar dónde hay late binding requiere análisis caso por caso.

**Solución:**

1. Habilitar `Option Strict On` en el proyecto VB.NET ANTES de migrar (paso recomendado en Fase 1)
2. Resolver todos los warnings que salgan (algunos serán cambios de comportamiento)
3. SOLO ENTONCES migrar a C#

Si saltas este paso, los bugs aparecerán durante migración pero atribuidos al "código nuevo".

### 1.3 `Option Explicit Off` y variables sin declarar

```vbnet
Option Explicit Off

Sub CalcularTotal()
    totl = monto * tasa     ' "totl" es typo, declarado implícitamente
    Return total            ' "total" no existe, devuelve 0 silenciosamente
End Sub
```

VB.NET con `Option Explicit Off` permite variables sin declarar (heredado de VB6).

**Cómo detectar:**

```bash
grep -r "Option Explicit Off" --include="*.vb" .
```

**Solución:** Habilitar `Option Explicit On` (default en proyectos nuevos desde VS 2003), corregir typos detectados, luego migrar.

### 1.4 `On Error Goto` y `On Error Resume Next`

VB.NET sigue soportando el manejo de errores estilo VB6. **Sí, en código VB.NET 4.8 todavía aparece:**

```vbnet
Sub ProcesarLote()
    On Error Resume Next
    ' 200 líneas de código
    On Error Goto 0
End Sub
```

**Solución:** Tratar idéntico a la lección de VB6 en `02-lecciones.md`. Auditar caso por caso, NO migrar como `try { } catch { }` global.

---

## Categoría 2: Trampas específicas de VB.NET (no existen en VB6)

### 2.1 Eventos con `Handles` y `WithEvents`

```vbnet
Public Class FormCliente
    Inherits Form

    Private WithEvents btnGuardar As New Button()

    Private Sub btnGuardar_Click(sender As Object, e As EventArgs) Handles btnGuardar.Click
        ' lógica
    End Sub
End Class
```

**Bug al migrar:** C# no tiene `Handles`. La conexión evento-handler se pierde si solo se traduce sintaxis.

**Solución correcta:**

```csharp
public class FormCliente : Form
{
    private Button btnGuardar = new();

    public FormCliente()
    {
        InitializeComponent();
        btnGuardar.Click += BtnGuardar_Click;  // Conexión explícita
    }

    private void BtnGuardar_Click(object? sender, EventArgs e)
    {
        // lógica
    }
}
```

**Trampa adicional:** un mismo handler puede tener múltiples `Handles`:

```vbnet
Private Sub Boton_Click(sender As Object, e As EventArgs) _
    Handles btn1.Click, btn2.Click, btn3.Click
```

En C# requiere suscripción explícita a cada uno:

```csharp
btn1.Click += Boton_Click;
btn2.Click += Boton_Click;
btn3.Click += Boton_Click;
```

### 2.2 Propiedades con `ReadOnly` y `WriteOnly`

```vbnet
Public ReadOnly Property Total As Decimal
    Get
        Return _items.Sum(Function(i) i.Precio)
    End Get
End Property

Public WriteOnly Property Password As String
    Set(value As String)
        _hashedPassword = HashIt(value)
    End Set
End Property
```

**En C#:**

```csharp
public decimal Total => _items.Sum(i => i.Precio);   // ReadOnly equivalente

// WriteOnly NO existe directo en C# moderno; alternativa:
public string Password
{
    set => _hashedPassword = HashIt(value);
}
// (genera warning por property con solo setter; pattern más limpio: método)
```

**Recomendación:** convertir `WriteOnly Property` a método explícito `SetPassword(string value)` en C#. Es más claro.

### 2.3 Default properties / indexers

VB.NET permite default properties con argumentos (legacy de VB6):

```vbnet
Public Class Cuentas
    Default Public Property Item(id As String) As Cuenta
        Get
            Return _dict(id)
        End Get
        Set(value As Cuenta)
            _dict(id) = value
        End Set
    End Property
End Class

' Uso:
Dim c = miCuentas("123")     ' Llamada implícita a la default property
```

**En C#:** usar indexer:

```csharp
public class Cuentas
{
    private readonly Dictionary<string, Cuenta> _dict = new();
    
    public Cuenta this[string id]
    {
        get => _dict[id];
        set => _dict[id] = value;
    }
}

// Uso:
var c = miCuentas["123"];
```

### 2.4 `Module` y miembros estáticos

```vbnet
Module Calculos
    Public Function CalcularImpuesto(monto As Decimal) As Decimal
        Return monto * 0.13
    End Function
End Module

' Llamada desde cualquier parte:
Dim x = CalcularImpuesto(100)
```

`Module` en VB.NET es una clase con miembros estáticos accesibles globalmente sin namespace.

**Migración correcta:**

```csharp
public static class Calculos
{
    public static decimal CalcularImpuesto(decimal monto) => monto * 0.13m;
}

// En C# requiere using static o calificación:
using static MiApp.Calculos;
// O:
var x = Calculos.CalcularImpuesto(100);
```

**Trampa:** si el código VB.NET usa la función SIN calificarla, en C# hay que decidir: `using static` (más cerca al original) o calificar (más explícito). El estándar moderno C# prefiere calificar.

### 2.5 `My` namespace

```vbnet
My.Computer.FileSystem.WriteAllText("log.txt", "datos", True)
My.Settings.UltimoUsuario = "armando"
My.Application.Info.Version
```

`My` es un namespace mágico de VB.NET con accesos a settings, computer, application info.

**Migración:**

| `My.*` | Equivalente .NET 8 |
| --- | --- |
| `My.Computer.FileSystem.*` | `System.IO.File.*` |
| `My.Computer.Network.*` | `System.Net.NetworkInformation.*` |
| `My.Settings.*` | `IConfiguration` o `IOptions<T>` (preferido) |
| `My.Application.Info.*` | `Assembly.GetExecutingAssembly()` |
| `My.Resources.*` | `ResourceManager` directo |
| `My.User.*` | `WindowsIdentity` o claims-based |

**Trampa:** `My.Settings` usa `app.config`/`user.config` con persistencia automática. `IOptions<T>` en .NET 8 NO persiste cambios automáticamente. Si la app guarda settings en runtime, requiere implementación custom.

### 2.6 `IIf` vs ternario

```vbnet
Dim resultado = IIf(edad >= 18, "Adulto", "Menor")
```

`IIf` evalúa AMBOS lados siempre (función, no operador):

```vbnet
Dim x = IIf(obj IsNot Nothing, obj.Valor, 0)
' NullReferenceException si obj es Nothing, porque obj.Valor se evalúa siempre
```

**En VB.NET 9+:** existe `If(...)` (operador real, short-circuit):

```vbnet
Dim x = If(obj IsNot Nothing, obj.Valor, 0)   ' Short-circuit, OK
```

**En C#:** ternario `?:` es short-circuit:

```csharp
var x = obj != null ? obj.Valor : 0;          // Short-circuit
// O con C# 8+:
var x = obj?.Valor ?? 0;
```

**Trampa de migración:** si el código VB.NET usa `IIf` sin null-check, migrar a `?:` puede funcionar correctamente, pero migrar a `IIf` C# (que no existe) o a una función helper que evalúa ambos lados replica el bug.

### 2.7 `String.Empty` vs `""` vs `Nothing`

VB.NET trata `Nothing`, `""`, y `String.Empty` distinto en algunas comparaciones:

```vbnet
Dim s As String = Nothing
If s = "" Then MsgBox "Igual"           ' Sí entra: VB.NET coerce Nothing a ""
If s Is Nothing Then MsgBox "Es Nothing" ' Sí entra
If String.IsNullOrEmpty(s) Then ...      ' Sí entra
```

**En C#:**

```csharp
string s = null;
if (s == "") Console.WriteLine("Igual");           // No entra (es null, no "")
if (s == null) Console.WriteLine("Es null");       // Sí entra
if (string.IsNullOrEmpty(s)) Console.WriteLine("Vacío"); // Sí entra
```

**Solución:** auditar comparaciones de string en VB.NET. Si encuentras `s = ""`, decidir si la intención original era "vacío o null" (entonces `IsNullOrEmpty`) o estrictamente "string vacío" (entonces `s == ""`).

### 2.8 `Object` con late binding

```vbnet
Option Strict Off

Dim obj As Object = SomeMethod()
obj.PropiedadQueQuizasExiste = "valor"      ' Late binding, OK en runtime si existe
obj.MetodoQueQuizasExiste()
```

VB.NET con `Option Strict Off` permite acceso a miembros sin verificación en compile-time (similar a `dynamic` en C#).

**Migración:**

| Caso | Migración |
| --- | --- |
| Sabes el tipo real | Cast: `((TipoReal)obj).Propiedad` |
| Necesitas dynamic dispatch | `dynamic` en C# |
| Es reflection legítimo | `obj.GetType().GetProperty(...)` |
| Es por pereza del dev original | Refactor a interfaces o tipos concretos |

`dynamic` en C# es la traducción "literal" pero raramente la correcta. La mayoría de los casos son pereza original que vale la pena resolver.

### 2.9 Operadores específicos de VB.NET

| VB.NET | C# equivalente | Notas |
| --- | --- | --- |
| `And` (no short-circuit) | `&` (bitwise) o expandir lógica | Bug típico al migrar a `&&` |
| `Or` (no short-circuit) | `\|` (bitwise) | |
| `AndAlso` | `&&` | Short-circuit |
| `OrElse` | `\|\|` | Short-circuit |
| `Mod` | `%` | Igual semántica |
| `\` (división entera) | `/` con tipos int | Igual a VB6 |
| `Is` | `is` (con cuidado: en VB.NET es comparación de referencia) | |
| `IsNot` | `is not` (C# 9+) o `!(... is ...)` | |
| `Like` | `Regex.IsMatch` o `LikeOperator.LikeString` | No tiene equivalente C# directo |
| `&` (concatenación) | `+` o string interpolation | En VB.NET `+` también funciona pero `&` no falla con tipos no-string |

**Trampa típica:** el dev que migra escribe `&&` donde el VB.NET tenía `And` (no `AndAlso`). Esto cambia la semántica si los operandos tienen side effects:

```vbnet
If validar(x) And actualizar(y) Then    ' AMBAS funciones se ejecutan SIEMPRE
```

```csharp
if (validar(x) && actualizar(y))         // actualizar(y) NO se ejecuta si validar(x) es false
```

Si `actualizar` tenía side effects esperados, el código migrado tiene un bug.

### 2.10 Inicializadores de objetos con `With`

```vbnet
Dim cliente As New Cliente With {
    .Nombre = "Juan",
    .Edad = 30,
    .Email = "juan@ejemplo.com"
}
```

**En C# (idéntico):**

```csharp
var cliente = new Cliente {
    Nombre = "Juan",
    Edad = 30,
    Email = "juan@ejemplo.com"
};
```

Trivial. Pero el `With` para acceso (no inicialización) NO existe en C#:

```vbnet
With cliente
    .Nombre = "Juan"
    .Edad = 30
    .Mostrar()
End With
```

```csharp
// No hay equivalente directo. Repetir el nombre o usar variable corta:
cliente.Nombre = "Juan";
cliente.Edad = 30;
cliente.Mostrar();
```

---

## Categoría 3: Trampas .NET Framework → .NET 8

Estas aplican aunque mantengas VB.NET (no migres a C#) si el target es .NET 8.

### 3.1 APIs deprecadas o removidas

| .NET Framework | .NET 8 |
| --- | --- |
| `System.Web.Forms` (WebForms) | NO existe; migrar a Blazor o ASP.NET Core MVC |
| `System.ServiceModel` (WCF cliente) | `System.ServiceModel.Primitives` (parcial) o gRPC |
| WCF servidor | NO existe; CoreWCF (community) o ASP.NET Core |
| `Remoting` (`MarshalByRefObject`) | NO existe; gRPC, REST, SignalR |
| `AppDomain` (multi-domain) | Solo single AppDomain en .NET Core/8 |
| `BinaryFormatter` | Removido en .NET 8 por seguridad; usar `System.Text.Json` o protobuf |
| `System.Drawing` | Solo en Windows; cross-platform usar `ImageSharp` o `SkiaSharp` |
| `System.Configuration.ConfigurationManager` | `IConfiguration` (preferido) |
| Enterprise Services COM+ | NO existe |
| `System.EnterpriseServices` | NO existe |
| `System.DirectoryServices` | Solo Windows en .NET 8 |
| `System.Management` (WMI) | Solo Windows |

**Implicación:** si tu sistema VB.NET usa WebForms, WCF servidor, Remoting o COM+, NO es migración: es re-arquitectura.

### 3.2 ConfigurationManager y app.config

```vbnet
Dim conn = ConfigurationManager.ConnectionStrings("DB").ConnectionString
Dim setting = ConfigurationManager.AppSettings("Modo")
```

En .NET 8 esto sigue funcionando si agregas `System.Configuration.ConfigurationManager` NuGet, pero **no es idiomático**. El estándar moderno:

```csharp
public class MisOpciones
{
    public string ConnectionString { get; set; }
    public string Modo { get; set; }
}

// En Program.cs:
builder.Services.Configure<MisOpciones>(builder.Configuration.GetSection("Mis"));

// Uso:
public class MiServicio(IOptions<MisOpciones> options)
{
    public void Hacer() {
        var conn = options.Value.ConnectionString;
    }
}
```

**Recomendación de migración:** convertir `app.config` a `appsettings.json` en Fase 2. ADR explícito para esto.

### 3.3 ADO.NET clásico vs Entity Framework Core

VB.NET legacy típicamente usa ADO.NET con `SqlConnection` + `SqlCommand` + `DataSet`/`DataTable`:

```vbnet
Dim conn As New SqlConnection(connStr)
Dim ds As New DataSet
Dim adapter As New SqlDataAdapter("SELECT * FROM Clientes", conn)
adapter.Fill(ds)
DataGrid1.DataSource = ds.Tables(0)
```

**Migración:**

- **Si la query es simple:** EF Core 8 con scaffold from existing
- **Si la query es compleja con joins legacy:** Dapper directo (más cercano a ADO.NET)
- **Si usa `DataSet` tipado:** convertir a entidades EF Core o records

**Trampa:** no intentar convertir DataSet/DataTable a EF Core 1:1. La impedancia es alta. Mejor: scaffold de las tablas reales y refactor de la lógica que las usaba.

### 3.4 Globalization y culture

VB.NET .NET Framework usa por default `CultureInfo.CurrentCulture`. .NET 8 sigue igual, pero el comportamiento puede cambiar en .NET 8 con `System.Globalization.Invariant` (si está habilitado en el proyecto).

**Caso típico:** parsing de números/fechas que en .NET Framework usaba la cultura local (es-MX, es-CR), en .NET 8 puede usar invariant si está mal configurado.

**Solución:** ser explícito SIEMPRE:

```csharp
double n = double.Parse("12.5", CultureInfo.InvariantCulture);
DateTime d = DateTime.ParseExact("2024-06-15", "yyyy-MM-dd", CultureInfo.InvariantCulture);
```

### 3.5 Threading y async

VB.NET legacy frecuentemente usa:

```vbnet
Dim t As New Thread(AddressOf TrabajoLargo)
t.Start()
```

O con `BackgroundWorker` en WinForms.

**Migración:** todo a `Task` y `async/await`:

```csharp
await Task.Run(() => TrabajoLargo());
// O para CPU-bound:
await Task.Run(TrabajoLargo);
```

**Trampa:** `BackgroundWorker` tiene eventos `DoWork`, `ProgressChanged`, `RunWorkerCompleted` que dependen del context de UI. Migrar a `Task` requiere reportar progreso vía `IProgress<T>` y manejar el contexto de UI explícitamente con `Dispatcher.Invoke` (WPF) o `Control.Invoke` (WinForms).

---

## Estrategia recomendada de migración VB.NET legacy

### Opción A: VB.NET FX → VB.NET .NET 8

**Cuándo:** equipo con experiencia VB.NET, no quiere aprender C#, código bien estructurado.

**Pasos:**
1. Habilitar `Option Strict On` y `Option Explicit On` en proyecto VB.NET FX
2. Resolver warnings
3. Usar `.NET Upgrade Assistant` de Microsoft
4. Migrar APIs deprecadas según sección 3.1
5. Validar con tests

**Ventaja:** menor curva de aprendizaje. **Desventaja:** VB.NET tiene ecosistema más limitado en .NET moderno (menos NuGets, menos stack overflow, MVPs activos en C#).

### Opción B: VB.NET FX → C# .NET 8

**Cuándo:** equipo abierto a C#, código con suficiente deuda técnica que la migración requiere refactor de todos modos, ecosistema NuGet importante.

**Pasos:**
1. Mismo paso 1 y 2 que Opción A
2. Migrar a C# usando los agentes de esta plantilla
3. Migrar APIs deprecadas
4. Validar con tests

**Ventaja:** ecosistema moderno, mejor talento disponible. **Desventaja:** curva de C# y costo de cambio cultural.

### Opción C: VB.NET FX → C# .NET 8 (re-arquitectura)

**Cuándo:** sistema usa WebForms, WCF servidor, Remoting, COM+; o el dominio cambió mucho.

**Pasos:** no es migración, es proyecto nuevo con migración de datos. Cotizar separado.

---

## Checklist de revisión para código VB.NET migrado

Antes de aceptar código migrado por Copilot, buscar:

- [ ] ¿`Option Strict Off` en VB.NET original fue resuelto antes de migrar?
- [ ] ¿Funciones de `Microsoft.VisualBasic.dll` (`Mid`, `Val`, etc.) se reemplazaron con helpers explícitos o nativo C#?
- [ ] ¿Eventos con `Handles` se conectaron explícitamente con `+=` en C#?
- [ ] ¿Operadores `And`/`Or` (no short-circuit) se distinguieron de `AndAlso`/`OrElse`?
- [ ] ¿`IIf` (no short-circuit) se distinguió de `If(...)` (short-circuit)?
- [ ] ¿APIs deprecadas en .NET 8 (WebForms, WCF servidor, Remoting, BinaryFormatter) se reemplazaron?
- [ ] ¿`ConfigurationManager` se migró a `IConfiguration` con `IOptions<T>`?
- [ ] ¿Threading (`Thread`, `BackgroundWorker`) se migró a `async/await` con manejo correcto de UI context?
- [ ] ¿`My` namespace se mapeó a APIs estándar?
- [ ] ¿Comparaciones de string distinguieron `null` de `""`?

Si alguno responde "no sé", revisar el código VB.NET original antes de aceptar la migración.
