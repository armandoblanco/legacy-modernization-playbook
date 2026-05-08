# Anti-patrones al usar GitHub Copilot en migración

Este documento describe los errores comunes al usar Copilot para migrar código VB6. Cada anti-patrón incluye: cómo se manifiesta, por qué pasa, y qué hacer en su lugar.

---

## Anti-patrón 1: "Migra todo el sistema"

### Cómo se manifiesta

```
@migration-agent Migra todo el sistema VB6 a .NET 8.
```

### Por qué falla

El agente intenta procesar miles de líneas de código y archivos en una sola ejecución. Resultado típico:
- Pierde contexto entre features
- Genera código que asume infraestructura inexistente
- Mezcla patrones (un feature en MVVM, otro en code-behind)
- Cuando falla, falla en el archivo 47 y hay que rehacer 46 archivos

### Qué hacer

Migrar feature por feature con el agente. Una sesión = un feature.

```
@migration-agent Migra el feature autenticacion-y-acceso, sigue el flujo Domain → 
Application → Infrastructure → WPF, compilando entre cada capa.
```

Después del feature, revisar el output, validar que compile y los tests pasen, y luego pasar al siguiente.

---

## Anti-patrón 2: Aceptar código sin compilar

### Cómo se manifiesta

Copilot genera 200 líneas de C#, el desarrollador hace `git commit` sin correr `dotnet build`. Más tarde, alguien encuentra que ni siquiera compila.

### Por qué falla

Copilot puede generar código que parece correcto pero usa:
- APIs inexistentes
- NuGet packages no instalados
- Tipos que no existen
- Sintaxis de versiones de C# distintas a la del proyecto

### Qué hacer

Después de cada generación de código:

```bash
dotnet build
```

Si falla, NO aceptar el código. Pegar el error en el chat:

```
@migration-agent Tu código falla con:
[pegar error completo de dotnet build]

Corrígelo antes de continuar.
```

El agente del workshop tiene compile-and-test loop integrado. Si lo desactivas o ignoras, lo conviertes en un generador de texto sin garantías.

---

## Anti-patrón 3: No leer el código generado

### Cómo se manifiesta

El desarrollador acepta código que compila sin revisarlo. Asume "si compila y pasa los tests, está bien".

### Por qué falla

Copilot puede:
- Inventar reglas de negocio cuando le falta contexto
- Usar nombres de variables/métodos que parecen correctos pero son confusos
- Acoplar código a patrones que el equipo no usa
- Introducir dependencias innecesarias

Los tests pasan porque los tests también los escribió el agente, basados en su interpretación. Si la interpretación está mal, los tests validan el bug.

### Qué hacer

Revisar TODO el código generado antes de aceptar:

1. ¿La lógica de negocio coincide con lo que dice el `.md` del feature?
2. ¿La lógica coincide con el código VB6 original?
3. ¿Los tests cubren los casos reales de negocio o son sintéticos?
4. ¿Los nombres de clases y métodos son los que usa el equipo?

Si encuentras una desviación, corregir y re-generar:

```
@migration-agent En el método CalcularComision, asumiste tasa fija de 0.05. 
La regla en VB6 es: tasa variable según tabla en modCalculos.bas L120-L160. 
Lee ese código y regenera el método.
```

---

## Anti-patrón 4: Ignorar warnings de Copilot

### Cómo se manifiesta

Copilot genera código y dice algo como "Nota: no encontré la implementación de PISPEC.OCX en el repo, asumí stub". El desarrollador ignora la nota y acepta.

### Por qué falla

Las "notas" de Copilot son señales reales de problemas:
- "Asumí stub" significa el código no funciona
- "No estoy seguro de la lógica" significa que probablemente está mal
- "Esto requiere más contexto" significa que falta información

Si las ignoras, terminas con código que parece completo pero está vacío en partes críticas.

### Qué hacer

Tratar cada nota como un TODO bloqueante:

1. Si dice "asumí X", verificar si X es correcto
2. Si dice "no encontré Y", proveer Y como contexto adicional
3. Si dice "stub generado", agregar a `migration-log.md` como ítem pendiente

NUNCA hacer commit con notas sin resolver.

---

## Anti-patrón 5: Usar el agente equivocado para la fase

### Cómo se manifiesta

Usar el agente de migración para hacer assessment, o el de assessment para generar código.

### Por qué falla

Cada agente está diseñado con prompt y contexto específicos para su fase:
- El de assessment lee código VB6 y genera Markdown
- El de planning toma assessment y genera ADRs
- El de migración asume ambos y genera C#

Si pides al agente de migración que "primero analice y luego migre", va a fallar en una de las dos cosas. No está optimizado para hacer las dos.

### Qué hacer

Respetar las fases. Tres agentes separados:

```
Fase 1: @vb6-assessment Analiza el sistema VB6
Fase 2: @vb6-planning Genera arquitectura target y ADRs
Fase 3: @vb6-migration Migra feature por feature
```

Si necesitas hibridar (ej: en medio de migración descubres que el assessment está incompleto), pausa la migración, vuelve al agente de assessment para ese feature, y luego retoma migración.

---

## Anti-patrón 6: Permitir que el agente "decida" arquitectura

### Cómo se manifiesta

```
@migration-agent Migra este feature. Decide tú si usar MVVM o code-behind, 
WinForms o WPF, EF Core o Dapper.
```

### Por qué falla

El agente va a tomar decisiones inconsistentes entre features. Resultado: arquitectura Frankenstein donde cada feature usa patrones distintos.

### Qué hacer

Las decisiones arquitectónicas se toman UNA vez en Fase 2 y se documentan en ADRs. El agente de migración debe LEER los ADRs y respetarlos.

En el agente de migración, hardcodear las decisiones:

```markdown
**Stack confirmado (no negociable por feature):**
- UI: WPF + MVVM con CommunityToolkit.Mvvm
- ORM: EF Core 8 (queries simples) + Dapper (queries SQL legacy complejas)
- DI: Microsoft.Extensions.DependencyInjection
- Logging: Serilog
```

Si el agente intenta cambiar estas decisiones, rechazar y referirse al ADR.

---

## Anti-patrón 7: Saltarse los ADRs

### Cómo se manifiesta

"Los ADRs son burocracia, vamos directo al código."

### Por qué falla

Cuando aparece la primera disputa técnica con el cliente ("¿por qué eligieron WPF y no Blazor?", "¿por qué reemplazaron PISPEC con un microservicio?"), no hay documentación que respalde la decisión. Conversación derivada: 2-3 reuniones, posibles cambios de scope.

Tres meses después, alguien del equipo pregunta "¿por qué hicimos X?", nadie se acuerda, se decide cambiarlo, se rompe paridad.

### Qué hacer

Cada decisión arquitectónica relevante (no cada línea de código) genera un ADR:

```
docs/adr/
├── ADR-001-target-stack.md
├── ADR-002-pispec-replacement.md
├── ADR-003-bd-strategy.md
├── ADR-004-mvvm-framework.md
└── ADR-005-error-handling.md
```

Escribir un ADR bien hecho es trabajo de un par de iteraciones de pensamiento estructurado, no un proyecto. El costo de NO tenerlo es discusiones repetidas cada vez que la decisión se cuestiona, sin nadie que recuerde por qué se eligió lo que se eligió.

---

## Anti-patrón 8: Mezclar migración con refactor de negocio

### Cómo se manifiesta

"Ya que estamos migrando, aprovechemos para arreglar este cálculo de comisiones que está mal."

### Por qué falla

- Imposible validar paridad: si cambias la regla, los outputs no son comparables
- El cliente no sabe cuál es el comportamiento esperado: ¿el viejo o el nuevo?
- Re-trabajo: si después se decide volver a la regla vieja, hay que migrar de nuevo
- Bug introducido en migración pero atribuido a cliente "no, así nos pidió"

### Qué hacer

Política estricta: **migración preserva comportamiento, incluyendo bugs conocidos.**

Si se encuentra un bug en VB6 durante migración:
1. Documentar el bug en `migration-log.md`
2. Replicarlo fielmente en C#
3. Crear un ticket separado: "Post-migration: arreglar bug X"
4. NO mezclar fix con migración

Esta política es contraria a la intuición ("ya que tocamos el código, vamos a mejorarlo") pero es la única que protege paridad.

---

## Anti-patrón 9: Subestimar la validación de paridad

### Cómo se manifiesta

"Los tests unitarios pasan, está listo."

### Por qué falla

Tests unitarios validan lo que el desarrollador (o agente) entendió como reglas de negocio. NO validan que el sistema migrado se comporte igual al sistema VB6 con datos reales.

Caso real: módulo de cálculo de impuestos pasaba 100% de tests unitarios. Con datos reales del cliente, el 4% de los registros daba un valor distinto. Causa: redondeo bancario que el VB6 hacía implícitamente y los tests sintéticos no cubrían.

### Qué hacer

Para sistemas críticos, además de tests unitarios:

1. **Parity Test Suite**: corre el módulo migrado con datos del cliente (anonimizados) y compara contra output del VB6.
2. **Aceptación condicional**: módulo aceptado solo cuando paridad operacional > 99.5% (los 0.5% restantes son fix-on-purpose documentados).
3. **Run paralelo en producción**: ambos sistemas corren con los mismos datos durante un período de validación acordado con el cliente. Diferencias se investigan y resuelven.

Esto NO es trabajo del agente de migración, es un sub-proyecto de validación. Si el cliente lo pide, contratarlo como entregable separado.

---

## Anti-patrón 10: No registrar las decisiones que el agente toma

### Cómo se manifiesta

El agente, ante una ambigüedad, decide algo razonable y sigue. La decisión NO se registra. Más adelante en el proyecto, nadie sabe por qué tal regla está implementada de tal forma.

### Por qué falla

Las migraciones tienen cientos de micro-decisiones. Si no se registran, el conocimiento se pierde. Cuando aparece un bug, nadie puede diferenciar entre:
- "Es así porque así era en VB6 (confirmado)"
- "Es así porque el agente lo interpretó así (no validado)"
- "Es así porque es un bug introducido en migración"

### Qué hacer

El agente del workshop tiene un campo dedicado en `migration-log.md`:

```markdown
**Decisiones tomadas autónomamente desde código VB6:**
- Regla de "3 intentos fallidos = bloqueo 15 min" tomada de modSeguridad.bas L142-L168 (no estaba documentada en .md)
- Cálculo de aguinaldo usa fórmula días_trabajados/365 según modPlanilla.bas L240-L268 (NO la fórmula estándar de 30 días)
```

Esto permite a cualquier persona del equipo:
1. Validar la decisión consultando el código VB6 referenciado
2. Discutir con el cliente si la regla es correcta
3. Cambiar conscientemente si hace falta

Sin este registro, la migración es opaca.

---

## Anti-patrón 11: Confiar en "modo agente" sin checkpoints

### Cómo se manifiesta

```
@agente Ejecuta la migración completa de los 10 features.
```

Y dejar correr al agente sin validación intermedia hasta que termine.

### Por qué falla

Si en el feature 2 hubo un error de interpretación, ese error se propaga al 3, 4, 5... porque cada feature usa estructuras del anterior. Al final tienes 10 features con el mismo error subyacente.

### Qué hacer

El agente del workshop tiene autonomía pero con circuit breakers:
- Después de cada feature, reporte automático
- Después de 2 ambigüedades pendientes en un feature, parada automática
- Después del feature 1, parada para validación humana antes de seguir con 2..N

Si construyes un agente custom, agrega circuit breakers similares. NUNCA dejes correr sin validación intermedia.

---

## Anti-patrón 12: Usar Copilot como única fuente de conocimiento

### Cómo se manifiesta

El equipo confía en Copilot para todo. Cuando aparece un problema (ej: PISPEC.OCX), preguntan al agente "¿qué hacemos?" y aceptan su respuesta sin más.

### Por qué falla

Copilot tiene buen conocimiento general pero:
- No conoce el contexto específico del cliente, su mainframe, sus políticas
- Puede sugerir soluciones que técnicamente funcionan pero violan políticas de seguridad del cliente
- Puede inventar arquitecturas que no existen en el catálogo de tecnología aprobada de la organización

### Qué hacer

Copilot acelera, no decide. Para decisiones arquitectónicas:

1. Copilot sugiere alternativas técnicas
2. El arquitecto valida contra políticas del cliente y la organización
3. La decisión se discute con stakeholders relevantes
4. Se documenta en ADR

Esto NO es lentitud, es responsabilidad. Una decisión técnica mal tomada en migración garantiza re-trabajo masivo más adelante.

---

## Resumen ejecutivo

Si solo tienes capacidad para internalizar tres reglas:

1. **Compile-and-test entre capas, sin excepción.** No avances con build roto.
2. **Lee el código generado, no asumas que es correcto porque compila.** Validar contra el VB6 original.
3. **Decisiones arquitectónicas en ADRs antes de generar código.** No dejes que el agente improvise.

Las otras 9 reglas detallan estos tres principios.
