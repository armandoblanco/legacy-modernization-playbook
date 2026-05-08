# Trampas semánticas VB6 → C#

Este documento cataloga las diferencias semánticas entre VB6 y C# que generan bugs sutiles si se migra "directo". Cada trampa incluye: el comportamiento VB6, el bug típico al migrar, y la solución correcta.

---

## 1. Indexing de strings: 1-based vs 0-based

### Comportamiento VB6

```vb
Dim s As String
s = "ABCDE"
MsgBox Mid(s, 1, 3)   ' Devuelve "ABC"
MsgBox Mid(s, 2, 2)   ' Devuelve "BC"
MsgBox Left(s, 2)     ' Devuelve "AB"
```

`Mid` es 1-based: el primer carácter es la posición 1.

### Bug al migrar

```csharp
string s = "ABCDE";
Console.WriteLine(s.Substring(1, 3));   // Devuelve "BCD" (no "ABC")
```

C# `Substring` es 0-based.

### Solución correcta

Crear un helper que replica comportamiento VB6:

```csharp
[Obsolete("Reemplazar con string.Substring nativo cuando se valide paridad")]
public static string Mid(string s, int start, int length)
{
    if (string.IsNullOrEmpty(s)) return string.Empty;
    var startZero = Math.Max(0, start - 1);
    if (startZero >= s.Length) return string.Empty;
    var available = s.Length - startZero;
    return s.Substring(startZero, Math.Min(length, available));
}
```

Migrar `Mid(s, 1, 3)` → `VB6Functions.Mid(s, 1, 3)` literalmente.

Cuando haya tests de paridad pasando, refactor a `s.Substring(0, 3)` con confianza.

---

## 2. División entera: `\` vs `/`

### Comportamiento VB6

```vb
Dim a As Integer
a = 10 \ 3      ' Devuelve 3 (división entera)
a = 10 / 3      ' Devuelve 3.33 (división flotante, error si tipo es Integer)
```

### Bug al migrar

```csharp
int a = 10 / 3;     // Devuelve 3 (división entera implícita por tipo)
double b = 10 / 3;  // Devuelve 3.0 (NO 3.33, porque ambos operandos son int)
double c = 10.0 / 3; // Devuelve 3.33
```

C# decide tipo de operación por tipo de operandos, no por operador.

### Solución correcta

Buscar todos los `\` en el código VB6 y migrar como cast explícito:

```csharp
int a = (int)(10 / 3);  // o int a = 10 / 3 si ambos son int
```

Para `/` en VB6 con resultado decimal:

```csharp
double b = (double)10 / 3;  // explícito
```

NUNCA confiar en coerción implícita.

---

## 3. Coerción automática de tipos (`Variant`)

### Comportamiento VB6

```vb
Dim v
v = "123"
If v = 123 Then MsgBox "Iguales"  ' Sí entra: VB6 coerce string a int
If v = 0 Then MsgBox "Cero"       ' No entra
v = ""
If v = 0 Then MsgBox "Vacio igual a cero"  ' Sí entra: "" coerce a 0
```

VB6 hace coerción automática y silenciosa entre string, número, null, vacío.

### Bug al migrar

```csharp
object v = "123";
if (v.Equals(123)) Console.WriteLine("Iguales");  // No entra: object compara referencias
```

### Solución correcta

Identificar el tipo real que `v` toma en runtime y declarar explícito:

```csharp
// Si v es string que a veces representa número:
string v = "123";
if (int.TryParse(v, out int parsed) && parsed == 123) { ... }

// Si v puede ser string vacío o número:
if (string.IsNullOrEmpty(v) || v == "0") { ... }
```

NUNCA migrar `Variant` a `dynamic` automáticamente. Eso esconde el problema.

---

## 4. `Nothing` vs `null`

### Comportamiento VB6

```vb
Dim obj As Object
' obj es Nothing aquí
If obj Is Nothing Then MsgBox "Vacio"
Set obj = New Cliente
If Not obj Is Nothing Then MsgBox "Lleno"
```

`Nothing` solo aplica a objetos. Tipos primitivos (String, Integer, Date) tienen valores default específicos.

### Bug al migrar

```csharp
Cliente obj = null;
if (obj == null) Console.WriteLine("Vacio");  // OK

string s = null;  // En C#, string es referencia: puede ser null
// VB6: una variable String NUNCA es Nothing, es ""
if (s.Length == 0) ... // NullReferenceException
```

### Solución correcta

Para strings:

```csharp
string s = null;
if (string.IsNullOrEmpty(s)) ... // null-safe
```

Habilitar nullable reference types (`<Nullable>enable</Nullable>`) y dejar que el compilador detecte estos casos en build-time.

Para tipos value (int, DateTime), VB6 tiene defaults (0, #1899-12-30#). C# requiere inicialización o nullable:

```csharp
int? edad = null;  // si puede no estar definido
DateTime? fecha = null;
```

---

## 5. `On Error Resume Next`

### Comportamiento VB6

```vb
Sub ProcesarArchivos()
    On Error Resume Next
    Dim i As Integer
    For i = 1 To 10
        ProcesarArchivo i  ' Si falla cualquier llamada, continúa con la siguiente
    Next i
    On Error GoTo 0
End Sub
```

Cualquier error dentro del bloque se ignora silenciosamente. El error queda en `Err.Number` pero el código continúa.

### Bug al migrar

```csharp
void ProcesarArchivos()
{
    try
    {
        for (int i = 1; i <= 10; i++)
            ProcesarArchivo(i);
    }
    catch { /* ignorar */ }
}
```

Esto NO es equivalente. La diferencia: en VB6, si `ProcesarArchivo(3)` falla, sigue con 4, 5, ..., 10. En el try/catch C#, sale del loop completo al primer error.

### Solución correcta

Auditar caso por caso. Para el ejemplo:

```csharp
void ProcesarArchivos(ILogger logger)
{
    for (int i = 1; i <= 10; i++)
    {
        try
        {
            ProcesarArchivo(i);
        }
        catch (Exception ex)
        {
            // Decisión consciente: log y continuar (paridad con On Error Resume Next)
            logger.LogWarning(ex, "Falló procesamiento de archivo {Index}", i);
        }
    }
}
```

Si después del análisis se descubre que el comportamiento original era un bug y el cliente quiere arreglarlo, eso es decisión separada (documentar en `migration-log.md`).

---

## 6. `Val()` y parsing flexible

### Comportamiento VB6

```vb
Dim n As Double
n = Val("123abc")    ' Devuelve 123 (lee hasta primer no-numérico)
n = Val("  42")      ' Devuelve 42 (ignora espacios al inicio)
n = Val("")          ' Devuelve 0
n = Val("abc")       ' Devuelve 0
n = Val("12.5")      ' Devuelve 12.5
n = Val("1,5")       ' Devuelve 1 (coma NO es decimal en VB6, es separador)
```

`Val` es muy permisivo: nunca lanza error.

### Bug al migrar

```csharp
double n = double.Parse("123abc");  // FormatException
double m = double.Parse("");        // FormatException
```

### Solución correcta

```csharp
[Obsolete("Reemplazar con double.TryParse cuando se valide paridad")]
public static double Val(string? s)
{
    if (string.IsNullOrEmpty(s)) return 0;
    var trimmed = s.TrimStart();
    var i = 0;
    if (i < trimmed.Length && (trimmed[i] == '+' || trimmed[i] == '-')) i++;
    while (i < trimmed.Length && (char.IsDigit(trimmed[i]) || trimmed[i] == '.')) i++;
    if (i == 0) return 0;
    return double.TryParse(trimmed[..i], NumberStyles.Float, CultureInfo.InvariantCulture, out var v) ? v : 0;
}
```

Importante: `Val` siempre usa punto como separador decimal, NO el de la cultura local. La cultura por defecto de C# en LATAM puede ser coma. Esto es bug garantizado si no se usa `CultureInfo.InvariantCulture`.

---

## 7. `Date` con epoch 30 de diciembre de 1899

### Comportamiento VB6

```vb
Dim d As Date
d = 0      ' Equivale a 30/12/1899
d = 1      ' Equivale a 31/12/1899
d = Now    ' Fecha actual
d = #6/15/2024#  ' Literal de fecha
```

VB6 representa fechas como `Double`: parte entera = días desde 30/12/1899, parte decimal = fracción del día.

### Bug al migrar

```csharp
DateTime d = new DateTime();  // 01/01/0001 (NO 30/12/1899)
DateTime d2 = DateTime.MinValue;  // 01/01/0001
```

### Solución correcta

Si el código VB6 hace cálculos numéricos con fechas (raros pero existen):

```csharp
public static class VB6Date
{
    public static readonly DateTime Epoch = new DateTime(1899, 12, 30);
    
    public static DateTime FromDouble(double serial)
    {
        int days = (int)serial;
        double timeFraction = serial - days;
        var ticksInDay = TimeSpan.FromDays(1).Ticks;
        return Epoch.AddDays(days).AddTicks((long)(timeFraction * ticksInDay));
    }
    
    public static double ToDouble(DateTime dt)
    {
        var diff = dt - Epoch;
        return diff.TotalDays;
    }
}
```

Si no hay cálculos numéricos (la mayoría de casos), simplemente usar `DateTime` y no preocuparse.

---

## 8. Arrays con `Option Base` y bounds explícitos

### Comportamiento VB6

```vb
Option Base 1
Dim arr(10) As Integer  ' Indices 1 a 10 (NO 0 a 9)

' o explícito
Dim arr2(1 To 10) As Integer
Dim arr3(5 To 15) As String  ' Permitido: bounds arbitrarios
```

VB6 permite arrays con índice base configurable y bounds arbitrarios.

### Bug al migrar

```csharp
int[] arr = new int[10];
arr[1] = 5;   // Funciona pero el rango es 0-9
arr[10] = 5;  // IndexOutOfRangeException
```

### Solución correcta

Para arrays simples con `Option Base 1`:

```csharp
// Alternativa 1: usar índice 0-based y restar 1 al migrar accesos
int[] arr = new int[10];  // 0..9
// arr(1) en VB6 → arr[0] en C#

// Alternativa 2: usar Dictionary si hay bounds raros
var arr = new Dictionary<int, string>();
for (int i = 5; i <= 15; i++) arr[i] = "";
```

Alternativa 1 es preferible. Más rápido y obvio. Documentar en comentario:

```csharp
// arr[i-1] equivale a arr(i) del VB6 original (Option Base 1)
```

---

## 9. Eventos de controles: nombres y semántica

### Comportamiento VB6

```vb
Private Sub Text1_Change()
    ' Se dispara en cada tecla
End Sub

Private Sub Combo1_Click()
    ' Se dispara al seleccionar
End Sub
```

### Bug al migrar (a WinForms)

```csharp
private void textBox1_TextChanged(object sender, EventArgs e)
{
    // OK, equivalente a Change
}

private void comboBox1_Click(object sender, EventArgs e)
{
    // NO equivalente: este es click del usuario
    // El equivalente VB6 Combo1_Click es comboBox1_SelectedIndexChanged
}
```

### Mapeo común de eventos VB6 → WinForms

| VB6 | WinForms |
| --- | --- |
| Form_Load | Form.Load |
| Form_Unload | Form.FormClosing |
| Form_Activate | Form.Activated |
| Text1_Change | TextBox.TextChanged |
| Text1_KeyPress | TextBox.KeyPress |
| Text1_LostFocus | TextBox.Leave |
| Combo1_Click | ComboBox.SelectedIndexChanged |
| Combo1_Change | ComboBox.TextChanged (solo si DropDownStyle permite editar) |
| Command1_Click | Button.Click |
| MSFlexGrid1_Click | DataGridView.CellClick (modelo distinto) |

### Mapeo común a WPF

| VB6 | WPF / XAML |
| --- | --- |
| Form_Load | Window.Loaded |
| Form_Unload | Window.Closing |
| Text1_Change | TextBox TextChanged event o binding TwoWay |
| Combo1_Click | ComboBox SelectionChanged |
| Command1_Click | Button.Click o RelayCommand |

En WPF con MVVM, prefiere bindings y RelayCommands sobre event handlers en code-behind.

---

## 10. Comparación de strings y collation

### Comportamiento VB6

```vb
If "ABC" = "abc" Then MsgBox "Iguales"  ' No entra (case-sensitive default)

' Pero con Option Compare Text al inicio del módulo:
Option Compare Text
If "ABC" = "abc" Then MsgBox "Iguales"  ' Sí entra
```

VB6 tiene `Option Compare Binary` (default) y `Option Compare Text` (case-insensitive según locale).

### Bug al migrar

```csharp
if ("ABC" == "abc") Console.WriteLine("Iguales");  // No entra
if ("ABC".Equals("abc", StringComparison.OrdinalIgnoreCase)) Console.WriteLine("Iguales");  // Sí
```

### Solución correcta

Buscar `Option Compare Text` en el código VB6. Si está, todas las comparaciones de string en ese módulo son case-insensitive según locale. Migrar como:

```csharp
if (string.Equals(a, b, StringComparison.CurrentCultureIgnoreCase)) ...
```

Si NO está (o `Option Compare Binary`), comparaciones son case-sensitive ordinal:

```csharp
if (a == b) ... // C# default es ordinal case-sensitive
```

---

## 11. `IsNumeric`, `IsDate`, `IsNull` y similares

### Comportamiento VB6

```vb
If IsNumeric("123") Then ...   ' True
If IsNumeric("12abc") Then ... ' False
If IsDate("2024-06-15") Then ...
If IsNull(v) Then ...          ' Solo true si v es DBNull o Variant null
```

### Solución correcta

Usar helpers explícitos:

```csharp
public static class VB6Functions
{
    public static bool IsNumeric(string? s) =>
        !string.IsNullOrEmpty(s) && double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out _);

    public static bool IsDate(string? s) =>
        !string.IsNullOrEmpty(s) && DateTime.TryParse(s, out _);

    public static bool IsNull(object? v) =>
        v is null || v == DBNull.Value;
}
```

---

## 12. ADO Recordset con cursor server-side

### Comportamiento VB6

```vb
Dim rs As ADODB.Recordset
Set rs = New ADODB.Recordset
rs.CursorLocation = adUseServer
rs.Open "SELECT * FROM Clientes WHERE Activo = 1", conn, adOpenStatic, adLockReadOnly
Do While Not rs.EOF
    ' procesar
    rs.MoveNext
Loop
rs.Close
```

Recordsets con cursor server-side mantienen estado en SQL Server. Performance puede ser muy distinta a un read directo.

### Bug al migrar

Usar `dbContext.Clientes.Where(c => c.Activo).ToList()` directamente puede tener performance distinta porque:
- VB6 con cursor server-side puede streamear filas
- EF Core sin `AsNoTracking` carga TODO en memoria con tracking

### Solución correcta

Para queries de solo lectura, EF Core con `AsNoTracking`:

```csharp
var clientes = await _context.Clientes
    .Where(c => c.Activo)
    .AsNoTracking()
    .ToListAsync(cancellationToken);
```

Para queries muy grandes con streaming real, usar Dapper o `DbDataReader` directo:

```csharp
await using var conn = new SqlConnection(_connectionString);
await conn.OpenAsync(cancellationToken);
await using var cmd = conn.CreateCommand();
cmd.CommandText = "SELECT * FROM Clientes WHERE Activo = 1";
await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
while (await reader.ReadAsync(cancellationToken))
{
    // procesar fila por fila sin cargar todo en memoria
}
```

---

## Checklist rápido para revisar código migrado

Antes de aceptar código migrado por Copilot, buscar:

- [ ] ¿Se usan helpers para `Mid`/`Left`/`Right`/`Val` o se migró directo a `Substring`?
- [ ] ¿Las comparaciones de string respetan `Option Compare` del módulo VB6 original?
- [ ] ¿Hay `On Error Resume Next` en el VB6 que se migró como `try/catch` silencioso?
- [ ] ¿Los `Variant` se migraron a tipo concreto o quedaron como `dynamic`/`object`?
- [ ] ¿División entera `\` se migró como `(int)(a/b)` y no como `a/b`?
- [ ] ¿Eventos de controles tienen el equivalente correcto (`SelectedIndexChanged`, no `Click`)?
- [ ] ¿Arrays con `Option Base 1` se migraron con offset -1 documentado?
- [ ] ¿Cálculos con fechas usan epoch correcto si VB6 hacía aritmética numérica?

Si alguno responde "no sé", revisar el código VB6 original antes de aceptar la migración.
