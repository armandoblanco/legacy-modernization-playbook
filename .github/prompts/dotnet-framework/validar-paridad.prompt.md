---
description: Valida paridad funcional entre el módulo legacy .NET Framework y su versión migrada en .NET 8/9
mode: agent
---

# Validar paridad — .NET Framework → .NET 8/9

Valida que el módulo migrado produce el **mismo comportamiento observable** que el legacy.

## Inputs
- Feature o módulo a validar (`docs/features/<feature>.md`).
- Ruta del legacy y del moderno.

## Salida

Crea `docs/features/<feature>-paridad.md`:

```markdown
# Paridad — <feature>

- Fecha: YYYY-MM-DD
- Legacy: <path/binario/endpoint>
- Moderno: <path/binario/endpoint>
- Estado: ✅ 100% | 🟡 Divergencias menores documentadas | 🔴 Divergencias bloqueantes

## Casos validados

| # | Caso | Input | Output legacy | Output moderno | ¿Paridad? | Notas |
|---|---|---|---|---|---|---|
| 1 | ... | ... | ... | ... | ✅ | |
| 2 | ... | ... | ... | ... | 🟡 | redondeo distinto, aceptado |

## Divergencias detectadas

### D-001: <título>
- Tipo: aceptable | bug-legacy | bug-moderno | bloqueante
- Comportamiento legacy: ...
- Comportamiento moderno: ...
- Decisión: mantener legacy / corregir moderno / aceptar nuevo / ADR adicional
- Acción: ...

## Tests automatizados
- Localización: tests/Modern/<feature>.ParityTests.cs
- Cantidad: N tests
- Cobertura de los casos de la tabla: 100%

## Performance comparativa (opcional)
- Latencia p50/p95/p99
- Memoria
- CPU

## Conclusión
<recomendación: aprobar / no aprobar / aprobar con seguimientos>
```

## Metodología

1. **Identifica casos representativos** desde `docs/features/<feature>.md` (workflows, edge cases, datos reales anonimizados).
2. **Ejecuta legacy** capturando outputs (DB rows, JSON responses, archivos generados, eventos emitidos).
3. **Ejecuta moderno** con los mismos inputs.
4. **Diff estructurado** (no `diff` de texto crudo si hay timestamps/UUIDs).
5. **Documenta cada divergencia** y clasifícala.
6. **Escribe tests automatizados** que perpetúan la verificación (no validación manual única).

## No aprobar paridad si
- Hay divergencias bloqueantes sin ADR.
- Performance del moderno es >2x peor sin justificación.
- Cobertura de casos < 80% de los workflows críticos.
- Tests automatizados no existen.
