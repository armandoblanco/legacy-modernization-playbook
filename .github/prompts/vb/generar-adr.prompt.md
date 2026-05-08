---
mode: 'agent'
description: Genera un Architecture Decision Record (ADR) en formato estándar Michael Nygard con tres alternativas evaluadas.
---

# Generar ADR

Genera un ADR siguiendo el template estándar para la decisión: `${input:decision_titulo}`.

**Contexto del proyecto:**
${input:contexto_proyecto}

**Restricciones conocidas:**
${input:restricciones}

**Output:**

Genera `docs/adr/ADR-${input:numero}-${input:slug_kebab_case}.md` con esta estructura:

```markdown
# ADR-${input:numero}: ${input:decision_titulo}

**Fecha:** YYYY-MM-DD (usar fecha actual)
**Estado:** Propuesto

## Contexto

[Descripción del problema. ¿Qué situación nos lleva a tomar esta decisión? 
¿Qué restricciones existen? ¿Qué pasa si no decidimos nada?]

## Decisión

[Decisión propuesta en una o dos oraciones claras.]

## Alternativas evaluadas

### Opción A: [nombre]

**Cómo funciona:** [descripción técnica breve]

**Pros:**
- ...

**Contras:**
- ...

**Trade-offs técnicos:** [licencias requeridas, dependencias externas, complejidad operacional, lock-in con proveedor, etc.]

**Decisión:** Rechazada porque [razón concreta y técnica]

### Opción B: [nombre]

[mismo formato]

**Decisión:** Rechazada porque [razón]

### Opción C: [nombre]

[mismo formato]

**Decisión:** Elegida porque [razón concreta]

## Consecuencias

**Positivas:**
- [beneficio concreto y medible]
- ...

**Negativas / deuda técnica asumida:**
- [costo o limitación que se acepta conscientemente]
- ...

**Riesgos:**
- [riesgo identificado y plan de mitigación]
- ...

## Implementación

**Componentes a crear/modificar:**
- ...

**Criterios técnicos de salida:** [qué tiene que ser cierto para considerar la decisión implementada: tests pasando, integración validada, documentación actualizada, etc.]

**Tests requeridos:**
- ...

**Personas/roles requeridos:**
- ...

**Dependencias externas:**
- [proveedores, servicios, infraestructura]

## Referencias

- ADRs relacionados: [lista]
- Documentación externa: [enlaces]
```

**Reglas para escribir el ADR:**

1. **Cada alternativa debe ser viable.** No inventar straw-mans solo para descartarlos.
2. **Razones de rechazo deben ser técnicas y concretas.** No "es viejo" o "no me gusta".
3. **Sin emojis decorativos.** Lenguaje profesional directo.
4. **Sin promocionar la decisión elegida.** Documentar pros y contras honestamente.
5. **Documentar deuda técnica.** La opción elegida también tiene contras; declararlos.
6. **Riesgos con plan de mitigación.** No solo listarlos.

Si necesitas información adicional para escribir el ADR (ej: ¿cuál es el budget?), pregunta UNA SOLA VEZ consolidando todas las dudas. Si el usuario no responde en la primera intervención, asumir defaults razonables y documentar las asunciones en el ADR.
