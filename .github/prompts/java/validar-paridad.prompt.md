---
description: Validar paridad funcional entre el módulo legacy y el módulo migrado
---

# Validar paridad

Valida que el módulo `${input:moduleName}` migrado en `src/` mantiene paridad funcional con el legacy en `legacy/`.

## Estrategia

1. **Lee las reglas de negocio** del módulo en `docs/features/${input:moduleName}.md`
2. **Identifica los escenarios de paridad** que cubren cada regla:
   - Caso happy path
   - Casos edge (null, vacío, límites)
   - Casos de error esperados
3. **Para cada escenario**:
   - Identifica el comportamiento esperado (del legacy o de los tests existentes)
   - Genera test en `src/${input:moduleName}/src/test/java/...ParityTest.java`
   - Ejecuta y valida que el comportamiento del nuevo código coincide

## Casos específicos por stack

### Si el stack legacy es J2EE
- Validar mapping de transaction attributes (Required, RequiresNew, etc.)
- Validar comportamiento de Stateful Session Beans (si se migraron a equivalente)
- Validar XA transactions (si se eliminaron, validar que la consistencia se mantiene con Saga/Outbox)

### Si el stack legacy es Spring 3/4
- Validar que el upgrade de Hibernate no cambió semántica de queries (especialmente HQL ↔ JPQL)
- Validar que comportamiento de cache de segundo nivel (si existía) se preservó
- Si se reescribió Struts → Spring MVC, validar redirects y forwards

### Si el stack legacy es Oracle Forms
- **Crítico**: validar NULL semantics. PL/SQL trata `NULL = NULL` como NULL, no como TRUE.
- Validar que validaciones de WHEN-VALIDATE-ITEM se ejecutan en el mismo punto del flujo
- Validar que triggers de auditoría siguen generando los mismos registros
- Validar que generación de DML automática de Forms se replica explícitamente
- Validar reglas de validación cliente vs servidor (Forms validaba en cliente, web debe validar en servidor)

## Reporte

Genera reporte en `migration/parity-report-${input:moduleName}.md`:

```markdown
# Reporte de paridad — ${input:moduleName}

## Escenarios validados: N/M

| Escenario | Comportamiento legacy | Comportamiento nuevo | Status |
| --- | --- | --- | --- |
| Crear con datos válidos | Inserta + audita | Inserta + audita | ✅ |
| Crear con cedula inválida | Error + no inserta | Error + no inserta | ✅ |
| Buscar con NULL | Ignora filtro NULL | Ignora filtro NULL | ✅ |
| ... | | | |

## Discrepancias encontradas

[Si las hay, listar con análisis: ¿es bug del nuevo, comportamiento legacy no documentado, o decisión consciente?]

## Tests generados

[Lista]

## Pendientes

[Casos no cubiertos, razón]
```

Si encuentras discrepancias críticas, NO las "arregles" en el nuevo código sin antes consultar — pueden ser comportamiento intencional o requerir actualización del ADR.

Invocar después: `@migration-tester` para tests de regresión continuos.
