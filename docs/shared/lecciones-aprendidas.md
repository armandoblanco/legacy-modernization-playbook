# Lecciones aprendidas en migraciones reales

Este documento contiene lecciones extraídas de migraciones reales de sistemas VB6 en banca, gobierno y servicios financieros. Las lecciones están agrupadas por categoría y cada una incluye contexto del proyecto donde se aprendió, qué falló y qué hacer en su lugar.

---

## Sobre el assessment

### Lección 1: La documentación existente miente

**Contexto:** Sistema bancario de compensación de cheques con 80 KLOC y "documentación completa" del cliente.

**Qué pasó:** El cliente entregó 200 páginas de manuales técnicos. Después de tres semanas de migración, descubrimos que el sistema usaba PISPEC.OCX para hablar con el mainframe del banco central. Esto NO estaba en la documentación. Estaba enterrado en `modIntegracion.bas` líneas 340-580.

**Lección:** La documentación describe el sistema que el equipo de TI cree que tiene. El código VB6 es el sistema real. Siempre.

**Qué hacer:** En la Fase 1, el agente de assessment debe leer el código fuente directamente. No basta con leer la documentación del cliente. La regla es: si el `.md` del feature dice algo distinto de lo que hace el código, gana el código.

---

### Lección 2: Los OCX no se "convierten", se reemplazan

**Contexto:** Mismo sistema bancario. Stack incluía PISPEC.OCX (Crítico), CRYSTL32.OCX v5.2 (Alto), LTOCX10N.OCX para imágenes de cheques (Alto), c4dll.dll dBASE de 1988-1996 (Alto/obsoleto), THREED32.OCX, MSCAL70.OCX, MSFLXGRD.OCX.

**Qué pasó:** El primer instinto fue intentar wrappear los OCX con interop COM en .NET. Funcionó técnicamente para los OCX simples (THREED32, MSCAL), pero falló para PISPEC porque el OCX dependía de un runtime que solo existía en máquinas con Windows XP de 32 bits y librerías propietarias del banco central.

**Lección:** Los OCX se clasifican por nivel de riesgo y se tratan distinto:

| Nivel | Estrategia | Ejemplos |
| --- | --- | --- |
| **Bajo** | Sustitución por control nativo equivalente | COMCTL32, MSCAL70, MSFLXGRD, DBLIST32, MSMASK32 |
| **Medio** | Reemplazo con NuGet package estándar | FTP32 → FluentFTP, IPPORT35 → TcpClient |
| **Alto** | Reemplazo con arquitectura alternativa documentada en ADR | LEADTools imágenes → PdfiumViewer/Magick.NET, Crystal Reports → FastReport.NET o SSRS |
| **Crítico** | NO migrar; aislar como microservicio o adapter pattern | PISPEC mainframe → microservicio Gateway |

**Qué hacer:** Para cada OCX Alto y Crítico, generar un ADR con tres alternativas evaluadas y una decisión justificada. NO inventar una migración que "se ve bien pero no funciona en producción".

---

### Lección 3: Las estimaciones iniciales subestiman sistemáticamente cuatro categorías de trabajo

**Contexto:** Sistema de gestión de personal de gobierno con dependencias OCX. La estimación inicial del equipo difería significativamente del trabajo real.

**Qué pasó:** El proyecto excedió la estimación inicial. Las razones se distribuyeron en cuatro categorías recurrentes:

- Assessment subestimado: lo que se vio "sencillo" en propuesta resultó tener más reglas implícitas en código de las que aparecían en la documentación del cliente
- OCX bloqueados que requirieron decisión arquitectónica con stakeholders externos (proveedor del mainframe, área de seguridad del cliente): trabajo no planificado al inicio
- Reglas de negocio implícitas en VB6 que requirieron extracción manual: cada cálculo financiero o validación específica del dominio tomó más esfuerzo del esperado
- Validación de paridad con datos reales del cliente: no había sido planeada como entregable separado y resultó ser comparable en tamaño a la migración misma

**Lección:** Las estimaciones iniciales de migraciones VB legacy con OCX son sistemáticamente optimistas. No por mala fe del equipo, sino porque estas cuatro categorías de trabajo son invisibles hasta que estás en medio de la fase.

**Qué hacer:** En la propuesta inicial, **separar el trabajo en entregables independientes** y tratar cada uno como compromiso técnico separado:

- Fase 1 (Assessment) como entregable propio
- Fase 2 (Planning) como entregable propio con punto de control antes de Fase 3
- Fase 3 (Execution) con bandas (mínimo, esperado, máximo) revisadas después de cada feature migrado
- Validación de paridad como entregable separado con su propio compromiso técnico

Esta separación protege al equipo y al cliente: ambos tienen claridad sobre qué se está comprometiendo en cada fase, y la fase siguiente solo se inicia cuando la anterior está completa y los aprendizajes están incorporados.

**No incluir en este repo:** estimaciones absolutas de duración o esfuerzo en horas/días/semanas. Esas dependen del proyecto específico, perfil del equipo y restricciones del cliente, y son responsabilidad del proceso comercial, no de la metodología técnica.

---

## Sobre el uso de Copilot

### Lección 4: Copilot inventa cuando le falta contexto

**Contexto:** Migración de módulo de cálculo de prestaciones laborales (gobierno).

**Qué pasó:** El agente generó un cálculo de aguinaldo que parecía correcto pero usaba la fórmula de "30 días de salario base". El sistema VB6 real usaba "días trabajados en el año / 365 × salario base". El agente no tenía esa fórmula en el `.md` (estaba incompleto), así que improvisó con "lo que parece estándar".

**Lección:** Copilot completa con conocimiento general cuando le falta contexto específico. Esto es peligroso en lógica de negocio.

**Qué hacer:** En el agente de migración, instruir explícitamente:

```markdown
**Cuando una ambigüedad de negocio aparece:**
1. Busca en el .md del feature, sección "Reglas de Negocio"
2. Si no está, busca en el código VB6 fuente
3. Si el código VB6 implementa un comportamiento, ESE es el correcto
4. NUNCA improvises con "lo que parece estándar"
```

Y en el código generado, dejar comentarios de origen:

```csharp
// Fórmula heredada de modPlanilla.bas L240-L268.
// días_trabajados / 365 × salario_base. NO usar la fórmula estándar de 30 días.
```

---

### Lección 5: El compile-and-test loop es no negociable

**Contexto:** Tres equipos, mismo proyecto, distinta disciplina.

**Qué pasó:**
- Equipo A migró feature completo (Domain + Application + Infrastructure + UI) y luego compiló. Encontró 47 errores acumulados. Limpiarlos requirió un ciclo largo de cambios cruzados entre capas porque las dependencias estaban rotas en cadena.
- Equipo B migró feature por capas, compilando entre cada una. Encontró 3-4 errores por capa, los arregló inmediatamente. Avanzó de manera lineal sin retrocesos.
- Equipo C no compiló hasta el final del feature. Cuando lo hizo, no compilaba y encima los tests no estaban escritos. Tuvo que rehacer aproximadamente 40% del feature.

**Lección:** El compile-and-test entre capas no es lentitud, es velocidad real. La sensación de "estoy avanzando rápido sin compilar" es ilusión.

**Qué hacer:** En el agente, hardcodear el ciclo:
```
Domain → dotnet build → dotnet test → Application → dotnet build → dotnet test → ...
```
No avanzar si la capa anterior está rota. Esto es lo que más mejora la calidad del output del agente.

---

### Lección 6: Los warnings son señales, no ruido

**Contexto:** Migración con `<TreatWarningsAsErrors>false</TreatWarningsAsErrors>` global.

**Qué pasó:** Al final del proyecto había 380 warnings acumulados. Cuando QA detectó un bug en producción, fue por un nullable warning (CS8602) ignorado tres meses atrás.

**Lección:** Los warnings de nullable reference types en C# 8+ son señales reales de bugs latentes, no ceremonia.

**Qué hacer:** Política diferenciada por capa:
- **Domain y Application**: `TreatWarningsAsErrors=true`. La disciplina importa donde la lógica vive.
- **Infrastructure y Presentation**: `WarningsAsErrors=CS8600;CS8601;CS8602;CS8603;CS8604`. Solo nullable críticos como error. El resto se documenta como deuda en `migration-log.md`.

Si el mismo warning aparece 3 veces seguidas en un feature, parar y discutirlo con el equipo. Es señal de que algo del patrón está mal.

---

## Sobre las trampas semánticas VB6 → C#

### Lección 7: `On Error Resume Next` es un cementerio de bugs

**Contexto:** Sistema de carga de archivos batch.

**Qué pasó:** El código VB6 tenía `On Error Resume Next` al inicio de un procedimiento de 200 líneas. El equipo lo migró como `try { ... } catch { /* ignore */ }`. La app empezó a "funcionar bien" pero perdiendo silenciosamente registros que deberían fallar visiblemente.

**Lección:** `On Error Resume Next` no significa "ignora errores". Significa "el desarrollador original no quiso o no pudo manejar errores caso por caso". Migrarlo como try/catch silencioso replica el bug.

**Qué hacer:** Auditar cada `On Error Resume Next` específicamente:

1. Buscar todas las líneas `On Error Resume Next` en el código VB6
2. Para cada una, identificar QUÉ errores se podían generar en el bloque protegido
3. Decidir caso por caso:
   - ¿Era un error esperado (ej: archivo no existe, conexión cae)? → manejar explícitamente con try/catch específico
   - ¿Era un error inesperado? → propagar, no tragar
   - ¿No se puede determinar? → registrar en `migration-log.md` como "ambigüedad pendiente" y propagar conservadoramente

NUNCA usar `catch (Exception) { }` como traducción automática. Eso es importar el bug.

---

### Lección 8: Las funciones de string cambian semántica

**Contexto:** Procesamiento de líneas de archivo posicional.

**Qué pasó:** El código VB6 usaba `Mid(linea, 1, 5)` para extraer los primeros 5 caracteres. El equipo lo migró como `linea.Substring(1, 5)` directamente. El bug: VB6 `Mid` es 1-based, C# `Substring` es 0-based. Estaban omitiendo el primer carácter de cada línea.

**Lección:** Estas funciones VB6 NO tienen equivalente directo:

| VB6 | Comportamiento | Equivalente C# directo (incorrecto) | Equivalente correcto |
| --- | --- | --- | --- |
| `Mid(s, 1, 5)` | 1-based | `s.Substring(1, 5)` | `s.Substring(0, 5)` |
| `Left(s, n)` | Maneja null | `s.Substring(0, n)` | requiere null check |
| `Right(s, n)` | Maneja null | `s.Substring(s.Length - n)` | requiere null check + bounds |
| `Val("123abc")` | Devuelve 123 | `int.Parse("123abc")` | falla con FormatException |
| `\` (división entera) | `10 \ 3 == 3` | `10 / 3` | `(int)(10 / 3)` solo si tipos son int |

**Qué hacer:** Crear una clase `VB6Functions` con helpers que replican el comportamiento exacto, marcados con `[Obsolete]` para reemplazo gradual:

```csharp
[Obsolete("Reemplazar con string.Substring nativo cuando se valide paridad")]
public static string Mid(string s, int start, int length) { ... }
```

Esto permite migrar línea por línea sin cambiar semántica, y luego ir reemplazando por nativo C# cuando hay tests de paridad que respaldan el cambio.

---

### Lección 9: `Variant` y la coerción automática

**Contexto:** Validador de campos en formulario de captura.

**Qué pasó:** El código VB6 hacía `If valor = 0` donde `valor` era un `Variant` que a veces venía como string vacío "", a veces como Null, a veces como 0. VB6 coerce todo eso a 0 silenciosamente. C# no.

**Lección:** Cualquier variable VB6 declarada sin tipo (o como `Variant`) puede ser cualquier cosa en runtime. Migrar a `object` o `dynamic` es perezoso y contagia el problema.

**Qué hacer:**
1. Para cada `Variant`, identificar los tipos reales que toma en runtime (revisar el código de uso)
2. Si son 1-2 tipos: usar la unión via `record` o `oneof`
3. Si son string + número: tipear como string y parsear explícitamente cuando se necesita
4. Documentar la decisión: "Variable X migrada como string porque se usa siempre como display, parsing a int en validación específica"

NUNCA usar `dynamic` como traducción automática de `Variant`.

---

## Sobre la arquitectura

### Lección 10: La solución .NET separada evita corrupción del proyecto legacy

**Contexto:** Migración donde el `.vbg` (Visual Basic Group) original se modificó.

**Qué pasó:** El equipo creó los proyectos .NET dentro de la misma carpeta del proyecto VB6 y editó el `.sln` original. El IDE de VB6 dejó de abrir el proyecto correctamente. Tuvieron que detener el avance de la migración mientras restauraban el ambiente legacy desde backup, porque el cliente seguía usando el VB6 en producción y no se podía dejar el ambiente roto.

**Lección:** VB6 y .NET 8 conviven mal en el mismo nivel del filesystem. Los proyectos SDK-style de .NET tienen archivos como `obj/` y `bin/` que VB6 no entiende, y al revés.

**Qué hacer:** Crear la solución .NET en una carpeta hermana o separada:

```
mi-proyecto/
├── legacy/                  ← código VB6 intacto
│   ├── MyApp.vbg
│   └── ...
├── migrated/                ← código .NET 8 nuevo
│   ├── MyApp.Migrated.sln
│   └── src/
└── docs/                    ← assessment compartido
```

Esto permite mantener el VB6 compilable durante toda la migración y mover features uno por uno sin romper el ambiente legacy.

---

### Lección 11: Clean Architecture sí, pero ajustada

**Contexto:** Sistema mediano (30 KLOC) donde se aplicó Clean Architecture pura con 6 proyectos por feature.

**Qué pasó:** Para 25 features se generaron 150 proyectos. La solución tardaba 4 minutos en abrir. Los desarrolladores empezaron a saltar la disciplina de capas para no lidiar con las referencias.

**Lección:** Clean Architecture es valiosa, pero no significa "un proyecto por capa por feature". Para sistemas legacy de tamaño medio:

**Estructura sugerida para 10-30 features:**
```
src/
├── App.Domain/              ← un solo proyecto, carpetas por feature
├── App.Application/
├── App.Infrastructure/
├── App.Shared/
└── App.<UI>/                ← WinForms o WPF
```

**Solo dividir por feature** cuando:
- El feature tiene equipo dedicado (ej: equipo de pagos)
- Hay necesidad real de deployment independiente (raro en legacy)
- El feature tiene >5KLOC y dependencias claramente aisladas

---

## Sobre la organización del trabajo

### Lección 12: Un feature por sesión, no más

**Contexto:** Equipo intentando migrar varios features en paralelo con el mismo agente.

**Qué pasó:** El contexto se mezclaba: el agente perdía track de qué feature estaba en cuál capa, generaba código que asumía estado de un feature distinto, los desarrolladores no lograban revisar a velocidad de generación.

**Lección:** Un feature por sesión de Copilot. No abrir tres conversaciones paralelas con el mismo agente sobre features distintos.

**Qué hacer:**
- Una sesión = un feature de inicio a fin (Domain → Application → Infra → UI → Tests → Migration log)
- Si necesitas pausar, cierra la sesión y abre una nueva cuando retomes (con contexto de "estoy en el feature X, ya migré Y, ahora voy con Z")
- El agente debe leer `migration-log.md` al inicio de cada sesión para reconstruir contexto

---

### Lección 13: Validación de paridad con datos reales

**Contexto:** Sistema de cálculo de comisiones bancarias.

**Qué pasó:** Los tests unitarios del módulo migrado pasaban al 100%. Cuando se corrió en producción con datos reales, el 8% de las comisiones daba un resultado distinto al sistema VB6.

Causa raíz: los tests usaban casos sintéticos (números redondos, fechas simples). Los datos reales tenían cosas como redondeo bancario, montos en moneda con escala 4 decimales, fechas de feriados que el VB6 manejaba con un calendario propio.

**Lección:** Los tests unitarios validan paridad lógica, NO paridad operacional. Para sistemas críticos:

**Qué hacer:**
1. Mantener una "Parity Test Suite" separada que ejecuta el módulo .NET con datos reales del cliente (anonimizados)
2. Comparar output contra el output del VB6 en los mismos datos
3. Aceptar el módulo como migrado solo cuando paridad operacional > 99.5% (los 0.5% restantes son comportamientos de fix-on-purpose documentados)

Esto NO es trabajo del agente de migración, es un sub-proyecto de validación. Si el cliente lo pide, contratar como entregable separado.

---

## Sobre el cliente y la comunicación

### Lección 14: El cliente quiere ver progreso, no completitud

**Contexto:** Migración larga con entrega final al cliente, sin checkpoints intermedios.

**Qué pasó:** No hubo demos durante la mayor parte del proyecto. En la demo final el cliente cambió 3 requerimientos, había malentendidos en 2 features, y se descubrió que el cliente esperaba reportes de Crystal Reports idénticos visualmente (no se había documentado).

**Lección:** Sin checkpoints visibles, los malentendidos se acumulan invisiblemente. Cuanto más larga la migración, más malentendidos acumulados al final.

**Qué hacer:** Demos periódicas cada vez que se completen 2-3 features migrados. Mostrar en cada demo:

- Lo que funciona
- Lo que está pendiente con razón concreta (OCX bloqueado, ADR pendiente de aprobación)
- Lo que fue interpretado autónomamente desde el código VB6 (lista de "decisiones tomadas")

El cliente puede corregir interpretaciones temprano. Cuesta menos que rehacer features al final.

---

### Lección 15: La "migración 1:1" es mentira útil

**Contexto:** Acuerdo con cliente: "migramos exactamente lo mismo, sin cambios funcionales".

**Qué pasó:** En cada feature aparecían situaciones donde "exactamente lo mismo" no era posible:
- Un OCX no tiene equivalente nativo → cambia comportamiento de UI
- Una llamada a API obsoleta de Windows → hay que cambiar de API
- Un cálculo con un bug de overflow conocido → ¿lo replicamos?

**Lección:** "Migración 1:1" es una expectativa razonable a nivel de propósito, pero imposible a nivel de implementación. Comunicar esto al cliente desde el inicio.

**Qué hacer:** En la propuesta y en el ADR-001, dejar explícito:

> El sistema migrado preservará el comportamiento de negocio del sistema VB6 actual. Donde no exista equivalente directo (controles, APIs, OCX propietarios), se documentará la sustitución en un Architecture Decision Record y se notificará al cliente para validación. Los bugs conocidos del sistema VB6 NO se replicarán intencionalmente; cada uno será evaluado caso por caso.

Esto blinda al equipo cuando aparece la inevitable conversación de "es que en VB6 funcionaba distinto".

---

## Resumen ejecutivo

Si solo tienes capacidad para internalizar tres lecciones:

1. **El código VB6 es la fuente de verdad. Siempre.** Documentación y memoria del cliente son aproximaciones.
2. **Compile-and-test entre capas es velocidad real, no lentitud aparente.** La disciplina previene el re-trabajo masivo de descubrir errores acumulados.
3. **Los OCX Críticos no se migran, se reemplazan con arquitectura documentada en ADR.** Saltarse esto garantiza re-trabajo masivo cuando aparezca el primer crash en producción.

Las otras 12 lecciones detallan estos tres principios en distintos contextos.
