# Metodología de Modernización VB6 con GitHub Copilot

Este documento explica las tres fases de la metodología en profundidad, con criterios de entrada y salida para cada una. La metodología es opinionada: tiene un orden estricto y rechaza atajos que parecen ahorrar tiempo pero generan re-trabajo.

---

## Por qué tres fases separadas

El error más común al migrar VB6 con asistencia de IA es saltar directamente a generar código. Esto produce dos resultados predecibles:

1. **Código que compila pero hace lo equivocado**, porque el modelo no entendió las reglas de negocio reales (que están en el código VB6, no en la documentación).
2. **Re-arquitectura accidental**: el modelo elige WinForms o WPF según lo que le suena bien, no según los criterios del proyecto.

Las tres fases existen para forzar que las decisiones se tomen en el orden correcto:

```
[Assessment] → entender qué hay
        ↓
[Planning] → decidir hacia qué se va
        ↓
[Execution] → construir
```

Si saltas Assessment, el modelo va a inventar reglas. Si saltas Planning, el modelo va a improvisar arquitectura. Solo cuando ambas están hechas, Execution produce código de calidad.

---

## Fase 1: Assessment

### Objetivo

Producir un entendimiento del sistema VB6 lo suficientemente preciso como para tomar decisiones de arquitectura informadas. Sin tocar una sola línea de C#.

### Entradas

- Repositorio con el código VB6 fuente (.vbp, .vbg, .frm, .bas, .cls, .ctl)
- Acceso al sistema en ejecución si es posible (para validar comportamiento observable)
- Documentación existente del sistema, aunque sea incompleta o desactualizada

### Salidas

```
docs/
├── README.md              Índice maestro del assessment
├── SUMMARY.md             Resumen ejecutivo (1-2 páginas)
└── features/
    ├── 01-<feature>.md    Un archivo por módulo funcional
    ├── 02-<feature>.md
    └── ...
```

Cada archivo de feature debe contener:

- **Propósito del módulo**: qué problema resuelve
- **Archivos VB6 que lo componen**: rutas exactas y líneas de código
- **Reglas de negocio**: explícitas (en código) e implícitas (deducibles)
- **Dependencias**: con otros módulos, BD, OCX, sistemas externos
- **Riesgos de migración**: OCX bloqueados, lógica compleja, datos sensibles
- **Estimación**: tamaño relativo (S, M, L, XL)

### Criterios de salida (Definition of Done)

La fase está completa cuando:

1. Cada `.frm`, `.bas` y `.cls` del proyecto VB6 está mapeado a algún feature documentado
2. Cada OCX usado está identificado con su nivel de riesgo (Bajo, Medio, Alto, Crítico)
3. Las dependencias entre features están explícitas (grafo dirigido)
4. Existe un orden de migración propuesto basado en dependencias

### Anti-patrón clásico

"Lo voy a hacer rápido y empiezo a migrar mientras documento." No funciona. Las decisiones de Fase 2 dependen de tener el assessment completo. Si lo haces parcial, vas a tomar decisiones parciales y vas a refactorizar la arquitectura tres veces.

---

## Fase 2: Planning

### Objetivo

Tomar todas las decisiones arquitectónicas del sistema target ANTES de generar código. Cada decisión queda documentada en un ADR (Architecture Decision Record) que sirve como contrato con el equipo.

### Entradas

- Output completo de Fase 1
- Restricciones del cliente: perfil del equipo, infraestructura disponible, políticas internas
- Políticas técnicas de la organización: stack permitido, BD soportadas, requisitos de seguridad

### Salidas

```
docs/
├── ARQUITECTURA-TARGET.md    Decisión consolidada de stack y patrones
├── adr/
│   ├── ADR-001-stack-decisions.md
│   ├── ADR-002-<ocx-bloqueado>-replacement.md
│   ├── ADR-003-<bd-strategy>.md
│   └── ...
└── migration-plan.md         Orden de migración con justificación
```

### Decisiones que deben tomarse en esta fase

1. **Target framework**: .NET 8, .NET 9, .NET Framework 4.8 (último caso muy raro)
2. **UI framework**: WinForms, WPF, Blazor (criterios en `03-decision-stack.md`)
3. **Patrón arquitectónico**: monolito modular, Clean Architecture, vertical slices
4. **MVVM o code-behind**: si WPF, qué framework MVVM (CommunityToolkit.Mvvm, Prism, ninguno)
5. **DI container**: Microsoft.Extensions.DependencyInjection, Autofac, Lamar
6. **ORM**: EF Core, Dapper, ambos
7. **Estrategia de BD**: scaffold de BD existente o migrations from scratch
8. **Logging**: Serilog, NLog, Microsoft.Extensions.Logging directo
9. **Manejo de errores**: excepciones, Result pattern, ambos por capa
10. **Reemplazo de cada OCX bloqueado**: arquitectura alternativa específica

### Criterios de salida

1. Existe un ADR por cada decisión de la lista de arriba
2. Cada OCX clasificado como Crítico o Alto en Fase 1 tiene un ADR de reemplazo con tres alternativas evaluadas
3. El orden de migración respeta dependencias y prioriza módulos sin OCX bloqueados
4. El plan está aprobado por el cliente o stakeholder técnico antes de pasar a Fase 3

### Anti-patrón clásico

"Empiezo a migrar y veo qué arquitectura sale." Lo que sale es Frankenstein: cada feature con su propio patrón, código inconsistente, refactors permanentes. Las decisiones arquitectónicas se toman antes y se respetan.

---

## Fase 3: Execution

### Objetivo

Generar la solución .NET 8 funcional, feature por feature, con compile-and-test entre capas y trazabilidad completa de decisiones.

### Entradas

- Output completo de Fase 2 (ADRs aprobados)
- Acceso a Copilot con el agente de migración configurado
- Solución .NET 8 base creada (puede ser parte del primer paso del agente)

### Salidas

```
migrated/
├── <Sln>.Migrated.sln
├── src/
│   ├── <App>.Domain/
│   ├── <App>.Application/
│   ├── <App>.Infrastructure/
│   ├── <App>.Shared/
│   └── <App>.Wpf/                (o .WinForms, según ADR)
├── tests/
│   ├── <App>.Domain.Tests/
│   ├── <App>.Application.Tests/
│   └── <App>.ParityTests/
└── docs/
    ├── adr/                       Nuevos ADRs que surjan durante migración
    ├── migration-log.md           Bitácora cronológica
    └── parity-report.md           Estado de paridad por feature
```

### Sub-fases dentro de Execution

#### 3.1 Bootstrapping (una sola vez)

Crear estructura de solución, proyectos, referencias, NuGet packages, cross-cuttings (logging, DI, error handling). Validar que compila vacío.

**Criterio de salida:** `dotnet build` limpio, `dotnet test` con 0 tests pasando (no fallando).

#### 3.2 Migración por feature (iterativo)

Para cada feature en el orden definido en Fase 2:

1. **Pre-validación**: lectura del `.md` del feature y del código VB6 fuente
2. **Domain layer**: entidades y reglas de negocio puras
3. **Application layer**: casos de uso, DTOs, validadores
4. **Infrastructure layer**: repositorios, persistencia, servicios externos
5. **Presentation layer**: ViewModels (si MVVM) y Views
6. **Parity tests**: tests específicos de paridad VB6 vs C#
7. **Migration log**: registro de la entrada del feature

Entre cada capa: `dotnet build` debe pasar. Entre cada feature: `dotnet test` debe pasar al 100%.

#### 3.3 Cierre

Cuando todos los features migrables están completos:

- `parity-report.md` consolidado
- `blocked-modules.md` con los features bloqueados por OCX y sus ADRs
- Demo funcional al cliente

### Criterios de salida globales

1. `dotnet build` limpio en toda la solución
2. `dotnet test` al 100% de pasada
3. La aplicación arranca sin excepciones no manejadas
4. Cada feature tiene entrada en `migration-log.md`
5. Cada decisión tomada autónomamente desde código VB6 está documentada
6. Cada OCX bloqueado tiene `NotImplementedException` con ADR asociado

---

## Decisiones que NO se toman en esta metodología

Para evitar scope creep, esto está fuera de alcance:

- **Decisiones de negocio**: si una regla VB6 tiene un bug, la metodología la replica fielmente. Decidir si arreglar el bug es trabajo aparte (post-migración).
- **Re-diseño de UX**: la metodología es 1:1 visual cuando es posible. Re-diseño moderno es proyecto separado.
- **Optimización de performance**: si VB6 era lento por mala SQL, la migración replica la SQL fielmente. Optimizar es post-migración.
- **Cambios de modelo de datos**: si la BD tiene problemas de normalización, la migración no los arregla. Refactor de BD es proyecto separado.

Mezclar migración con cualquiera de estos cuatro garantiza que el proyecto se desborde.

---

## Cuándo NO usar esta metodología

Hay casos donde lo correcto es no migrar o migrar diferente:

| Caso | Recomendación |
| --- | --- |
| El sistema VB6 será descontinuado en menos de 2 años | No migrar, mantener hasta sunset |
| El cliente quiere una app completamente nueva con UX moderna | Re-write desde cero, no migración |
| Más del 50% del código son OCX propietarios sin alternativa | Re-arquitectura completa, no migración |
| El sistema tiene menos de 5KLOC | Migración manual o herramienta comercial es más barata |
| El equipo no tiene experiencia en .NET | Capacitar primero o subcontratar, no migrar improvisando |

---

## Referencias

- ADRs: [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) (Michael Nygard)
- Clean Architecture: Robert C. Martin, "Clean Architecture: A Craftsman's Guide to Software Structure and Design"
- Strangler Fig Pattern: Martin Fowler, [bliki](https://martinfowler.com/bliki/StranglerFigApplication.html)
