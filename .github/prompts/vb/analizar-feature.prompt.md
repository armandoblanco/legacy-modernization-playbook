---
mode: 'agent'
description: Analiza un módulo funcional VB6 específico y genera el archivo Markdown del feature con reglas de negocio extraídas del código.
---

# Analizar feature VB6

Lee los archivos VB6 que componen el feature `${input:feature_name}` y genera `docs/features/<feature>.md` siguiendo el template estándar.

**Archivos VB6 a analizar:**
${input:vb6_files}

**Pasos:**

1. Lee CADA archivo completo (no solo extractos)
2. Identifica todos los `Sub` y `Function` públicos
3. Para cada uno, traza qué llamadas hace internamente
4. Extrae reglas de negocio:
   - **Explícitas:** validaciones con `If`, constantes con nombres de negocio, mensajes de error
   - **Implícitas:** cálculos numéricos, side effects, manejo de errores con `On Error`
5. Identifica dependencias:
   - Otros archivos VB6 que llama
   - Tablas de BD que toca
   - OCX/COM que usa
   - Sistemas externos (FTP, mainframe, APIs)
6. Detecta riesgos de migración:
   - OCX bloqueados
   - Lógica compleja (cálculos financieros, parsing de archivos)
   - Datos sensibles
   - `On Error Resume Next` que requieren auditoría caso por caso

**Output:**

Genera `docs/features/${input:feature_name}.md` con esta estructura:

```markdown
# Feature: ${input:feature_name}

## Propósito
[qué problema resuelve este módulo en el negocio]

## Archivos VB6 que lo componen
- ruta/archivo.frm (N líneas)
- ...

## Reglas de negocio explícitas
1. [regla con referencia a archivo y líneas]
2. ...

## Reglas de negocio implícitas
1. [regla deducida del código con referencia]
2. ...

## Dependencias
**Otros features:** [lista]
**Base de datos:** [tablas usadas]
**OCX/COM:** [lista con riesgo]
**Sistemas externos:** [APIs, mainframe, FTP]

## Riesgos de migración
- [riesgo identificado]
- ...

## Caracterización
**Tamaño relativo:** S | M | L | XL
**Complejidad:** Baja | Media | Alta
**Bloqueos detectados:** [lista]
```

**Reglas:**
- Cada regla DEBE citar archivo y líneas concretas (formato: `archivo.bas L120-L145`)
- NO juzgar si una regla parece bug; documentar comportamiento real
- Si encuentras código muerto, registrarlo como tal
- NO generar C#, solo Markdown
- NO sugerir reemplazos de OCX (eso es Fase 2)

Si el código de algún archivo no es claro, leer primero los archivos relacionados (los que lo llaman o son llamados) para entender contexto. NO inventar reglas.
