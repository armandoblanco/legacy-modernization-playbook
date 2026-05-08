---
description: Estrategia de testing transversal para cualquier migración legacy → moderno (paridad, caracterización, pirámide, Testcontainers)
applyTo: tests/**/*.{cs,ts,py,java}
---

# Estrategia de Testing — modernización legacy

> Reglas válidas para cualquier suite tecnológico (`vb`, `dotnet-framework`, `cobol`, `java`, `python`).

## Principios

1. **Sin tests no se migra.** Si el legacy no tiene cobertura, el primer commit de la task es **tests de caracterización**, no código moderno.
2. **Paridad antes que mejora.** Los tests prueban que el moderno hace lo mismo que el legacy (incluyendo bugs documentados como "bug-aceptado"), no lo "correcto".
3. **Pirámide invertida es anti-patrón.** Más unit que integration, más integration que e2e.
4. **Tests rápidos en CI.** Pirámide completa <10min en PR; suite extendida nightly.
5. **Datos reales anonimizados** > datos sintéticos para casos críticos de negocio.

## Pirámide objetivo

```
              /\
             /e2e\           5%   Smoke + happy paths críticos
            /------\
           /  intg  \        25%  Con BD/colas/HTTP reales (Testcontainers)
          /----------\
         /    unit    \      70%  Lógica de dominio sin I/O
        /--------------\
```

## Tipos de tests por capa

### Unit (70%)
- **Sin I/O.** Sin BD, sin red, sin filesystem real, sin reloj real.
- **Determinísticos.** Mismo input → mismo output siempre. Inyectar `IClock`, `IRandomProvider`.
- **Rápidos.** <50ms cada uno. Si tarda más, probablemente no es unit.
- **Aislados.** Un test no depende del orden de ejecución de otro.
- Stack default por lenguaje:
  - .NET: **xUnit + FluentAssertions + NSubstitute**
  - Java: JUnit 5 + AssertJ + Mockito
  - Python: pytest + pytest-mock
  - TypeScript: Vitest / Jest

### Integration (25%)
- **Con dependencias reales** vía **Testcontainers** (SQL Server, PostgreSQL, Redis, RabbitMQ, Azurite, LocalStack).
- **No mocks de BD.** Si el test requiere SQL, usa SQL real en container.
- **Una BD limpia por test class** (no por test — performance). Limpieza con `Respawn` o equivalente.
- **WebApplicationFactory<T>** (.NET) / `TestRestTemplate` (Spring) / `TestClient` (FastAPI) para HTTP in-process.
- Marcar con `[Trait("Category","Integration")]` o equivalente para correr selectivamente.

### E2E / Smoke (5%)
- **Solo happy paths críticos** (login, checkout, generar reporte regulatorio).
- **Playwright** para UI; **k6** o **NBomber** para perf-smoke.
- Corren contra ambiente staging post-deploy, no en PR.

## Tests de caracterización (legacy sin cobertura)

Cuando llegas a una feature **sin tests**:

1. **No la migres todavía.**
2. **Identifica entradas/salidas observables**: API request/response, BD rows antes/después, archivo generado, log emitido.
3. **Escribe tests sobre el legacy** que capturen esos comportamientos exactos (incluyendo bugs).
4. **Marca cada bug-legacy** detectado con `[Trait("Bug-Legacy", "ID-XXX")]` y registra en `docs/features/<feature>-bugs-legacy.md`.
5. **Hazlos pasar contra el legacy** primero. Esa es tu **red**.
6. **Migra**. Los mismos tests deben pasar contra el moderno.
7. Después de paridad, decide con el sponsor: ¿qué bugs corregimos vs qué se aceptan?

## Tests de paridad (legacy ↔ moderno)

Patrón canónico:

```csharp
public class CalcularImpuestosParityTests : IClassFixture<LegacyFixture>, IClassFixture<ModernFixture>
{
    [Theory]
    [MemberData(nameof(CasosReales))]  // datos anonimizados de prod
    public void Resultado_paridad(decimal monto, string regimen, ResultadoEsperado expected)
    {
        var legacy = _legacy.Calcular(monto, regimen);
        var modern = _modern.Calcular(monto, regimen);

        modern.Should().BeEquivalentTo(legacy, opts => opts
            .Excluding(r => r.Timestamp)
            .Using<decimal>(ctx => ctx.Subject.Should().BeApproximately(ctx.Expectation, 0.01m))
            .When(info => info.Path.EndsWith("Total")));
    }
}
```

- **Tolerancia explícita**: redondeos, timestamps, IDs auto-generados.
- **Casos representativos**: 80/20 — happy paths + edge cases (cero, negativos, máximos, fechas frontera, locale).
- **Datos**: anonimizar pero preservar distribución estadística.

## Coverage objetivo

| Componente | Línea | Branch |
|---|---|---|
| Lógica de negocio (Domain/Application) | **80%** | **70%** |
| API/Web controllers | 60% | 50% |
| Infra (Repos, EF, HTTP clients) | 40% | — |
| UI / Razor / Blazor | smoke E2E | — |
| Generated code | 0% (excluir) | 0% |

**No persigas 100%.** Cobertura sin aserciones útiles es teatro.

## Mutation testing (cuando vale la pena)

- Después de alcanzar coverage objetivo, correr `Stryker.NET` (o PIT, mutmut) en módulos críticos.
- Si el mutation score < 60%, los tests prueban poco aunque la cobertura diga "verde".
- No correr en PR (lento), solo nightly o on-demand.

## Performance / carga

- **No inventes** un proyecto de carga por hábito. Solo si:
  - Hay SLA contractual (RTO, latencia p99)
  - Se está cambiando engine de BD o paradigma (sync→async, monolito→servicios)
- Herramientas: **k6**, **NBomber** (.NET), **Locust** (Python).
- Línea base: medir el legacy en condiciones idénticas. El moderno **no debe** ser >2x peor en p95 sin justificación.

## Anti-patrones

- Tests que dependen del reloj del sistema (`DateTime.Now`) → usar `IClock` inyectado
- Tests que comparten estado vía variables estáticas
- Mocks de tu propio código (mockea las **fronteras** — DB, HTTP, archivos, no tus servicios)
- "Test que pasa solo si lo corro solo" → fix race condition o aislamiento
- Asserts gigantes (`obj.Should().Be(...)` con 200 props) → split en aserciones específicas
- `Thread.Sleep` en tests → `await` con polling determinístico (`AutoResetEvent`, `Polly`)
- Saltar tests de integración "porque son lentos" — corres seleccionados en PR + completos nightly
- Tests en producción sin feature flags ("todos somos chaos engineers ahora")
