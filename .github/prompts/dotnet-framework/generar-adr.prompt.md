---
description: Genera un ADR (Architecture Decision Record) en formato MADR para una decisión de la migración .NET
mode: agent
---

# Generar ADR

Genera un ADR para la decisión que indique el usuario. Escribe el archivo en `docs/adr/NNNN-<slug>.md` con numeración secuencial (lee la carpeta para detectar el próximo número).

## Estructura

```markdown
# ADR-NNNN: <Título conciso de la decisión>

- **Estado:** Propuesto | Aceptado | Reemplazado por ADR-MMMM | Obsoleto
- **Fecha:** YYYY-MM-DD
- **Decisores:** <sponsor / arquitecto / equipo>
- **Tags:** <data-access | auth | hosting | messaging | observability | ...>

## Contexto

<situación actual, restricciones, fuerzas en juego — 5-10 líneas máx>

## Opciones consideradas

### Opción A — <nombre>
- **Pros:**
  - ...
- **Contras:**
  - ...
- **Coste/esfuerzo:** bajo | medio | alto

### Opción B — <nombre>
- **Pros:** ...
- **Contras:** ...
- **Coste/esfuerzo:** ...

### Opción C — <nombre>
- **Pros:** ...
- **Contras:** ...
- **Coste/esfuerzo:** ...

## Decisión

**Elegida: Opción <X> — <nombre>**

Razones principales:
1. ...
2. ...
3. ...

## Consecuencias

### Positivas
- ...

### Negativas / aceptadas
- ...

### Riesgos a monitorear
- ...

## Plan de implementación
- Fase: 2 (decisión) | 3 (ejecución)
- Tareas asociadas: ...
- Criterios de éxito: ...

## Referencias
- Features impactadas: docs/features/<x>.md
- Hallazgos: docs/inventory/runtime-surface.md SEC/SUR-XXX
- ADRs relacionados: ADR-MMMM
- Bibliografía: <links>
```

## Reglas

1. **Mínimo 3 opciones** consideradas (incluyendo "no hacer nada" si aplica).
2. **Decisión explícita** — no "depende".
3. **Consecuencias negativas obligatorias** — toda decisión tiene trade-offs.
4. **Vincula al menos un hallazgo** del assessment (sin contexto del legacy, no hay ADR válido).
5. Si la decisión es **irreversible** (cambio de IdP, cambio de motor de BD), márcalo en `Tags` como `irreversible`.
