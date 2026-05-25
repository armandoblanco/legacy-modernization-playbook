---
description: Generar un Architecture Decision Record (ADR) para una decisión técnica de migración Java
---

# Generar ADR

Genera un Architecture Decision Record para la decisión: **${input:decisionTitle}**.

Estructura el documento siguiendo el formato estándar:

```markdown
# ADR-NNN: [Título]

**Status:** [Propuesto / Acordado / Implementado / Deprecado]
**Date:** YYYY-MM-DD
**Deciders:** [Nombres]

## Contexto

[2-3 párrafos describiendo la situación actual, restricciones, y por qué hay que decidir algo]

## Decisión

[Decisión tomada, una frase clara y específica]

## Razones

[Lista numerada de razones objetivas. NO opiniones, hechos verificables]

## Alternativas consideradas

### [Alternativa A]
- Pros: [...]
- Contras: [...]
- Por qué no: [razón específica para no elegirla]

### [Alternativa B]
- Pros: [...]
- Contras: [...]
- Por qué no: [...]

## Consecuencias

### Positivas
- [Consecuencia 1]
- ...

### Negativas
- [Consecuencia 1]
- ...

### Mitigaciones
[Para cada consecuencia negativa, cómo se mitiga]

## Vinculación

[ADRs afectados por esta decisión, o que afectan a esta]
```

Determina el número del ADR basado en los archivos existentes en `docs/adr/` (siguiente número secuencial).

Si la decisión involucra trade-offs no triviales (ej. Spring Boot vs Quarkus, monolito vs microservicios, mantener BD legacy vs migrar), valida primero con el usuario las razones específicas del cliente antes de generar el ADR. NO inventes contexto del cliente.

Guarda el resultado en `docs/adr/NNN-${input:slug}.md`.
