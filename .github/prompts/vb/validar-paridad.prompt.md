---
mode: 'agent'
description: Genera tests de paridad que validan que el código C# migrado se comporta igual que el VB6 original ante los mismos inputs.
---

# Validar paridad VB6 ↔ C#

Genera tests de paridad para el feature `${input:feature_name}` en `tests/App.ParityTests/${input:feature_name}/`.

**Archivos VB6 originales:**
${input:vb6_files}

**Código C# migrado:**
${input:csharp_files}

**Pasos:**

1. Lee el código VB6 original y el C# migrado
2. Identifica las funciones/métodos públicos que cambiaron de VB6 a C#
3. Para cada uno, genera tests que cubren:
   - **Caso normal**: input típico, output esperado según VB6
   - **Casos borde**: vacío, null, cero, máximo, mínimo
   - **Trampas semánticas**: las relevantes según `docs/04-trampas-vb6.md`
4. Si la función usa helpers de `VB6Functions`, validar paridad de esos helpers también

**Trampas a validar siempre que apliquen:**

| Si el VB6 usa... | Test obligatorio |
| --- | --- |
| `Mid(s, 1, n)` | `VB6Functions.Mid(s, 1, n)` devuelve los primeros N caracteres (1-based) |
| `Val(s)` | Strings con prefijos numéricos devuelven el número, "abc" devuelve 0 |
| `\` (división entera) | Resultado es int, no double |
| Comparación con `Variant` | Coerción string ↔ número replicada |
| `On Error Resume Next` | Bug fielmente replicado, NO try/catch silencioso global |
| `Option Compare Text` | Comparaciones case-insensitive según locale |
| Eventos de controles | Evento equivalente correcto (`SelectedIndexChanged` no `Click`) |

**Estructura del test:**

```csharp
namespace App.ParityTests.${input:feature_name};

public class <Feature>ParityTests
{
    [Theory]
    [InlineData("ABCDE", 1, 3, "ABC")]    // VB6 Mid 1-based
    [InlineData("ABCDE", 2, 2, "BC")]
    [InlineData("", 1, 5, "")]            // String vacío
    [InlineData("AB", 1, 5, "AB")]        // Length excede
    public void Mid_DebeReplicarComportamientoVB6(string input, int start, int length, string expected)
    {
        var result = VB6Functions.Mid(input, start, length);
        result.Should().Be(expected);
    }

    [Fact]
    public async Task <CasoDeUso>_ConDatosNormales_ProduceResultadoIdenticoAVB6()
    {
        // Arrange: input según caso documentado en docs/features/<feature>.md
        // Act: ejecutar el caso de uso migrado
        // Assert: output igual al esperado del VB6
    }
}
```

**Reglas:**

- Tests usan FluentAssertions (`Should().Be(...)`)
- Theory + InlineData para casos múltiples del mismo escenario
- Cada test cita en comentario el origen VB6: `// modSeguridad.bas L142-L168`
- Si el VB6 tiene un bug conocido, replicarlo en el test (paridad incluye bugs)
- NO inventar casos que no están en el código VB6 ni en `docs/features/`
- Si encuentras una ambigüedad (¿cómo se comporta el VB6 con input X?), registrarla en `migration-log.md` y usar interpretación conservadora

**Validación final:**

Después de generar los tests:

```bash
dotnet test tests/App.ParityTests/App.ParityTests.csproj --filter "FullyQualifiedName~${input:feature_name}"
```

Reportar:
- N tests ejecutados
- N pasando, M fallando
- Para los fallidos: análisis de si es bug en el migrado o en los tests

NUNCA marcar un feature como migrado si los tests de paridad fallan.
