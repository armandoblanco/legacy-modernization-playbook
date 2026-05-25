---
description: Migrar un módulo específico del sistema Java legacy al stack target
---

# Migrar módulo

Migra el módulo `${input:moduleName}` del sistema legacy al stack target definido en `docs/ARQUITECTURA-TARGET.md`.

## Pre-requisitos

Antes de empezar, valida que existen:
- `docs/ARQUITECTURA-TARGET.md`
- `docs/adr/` con decisiones de stack
- `docs/features/${input:moduleName}.md` (output del assessment)

Si falta alguno, detente y reporta.

## Pasos

1. **Lee el feature**: `docs/features/${input:moduleName}.md`
2. **Lee el código legacy** referenciado (no asumas, lee)
3. **Identifica el stack target** de los ADRs (Spring Boot 3 o Quarkus, frontend strategy, etc.)
4. **Aplica las instrucciones** de `.github/instructions/java-target/` según el target
5. **Migra capa por capa**:
   - Capa de datos: entities + repositories + tests
   - Capa de servicios: business logic + tests
   - Capa de presentación: REST controllers o vistas + tests
6. **Compile-and-test loop** después de cada capa
7. **Documenta en `migration/migration-log.md`**:
   - Mappings legacy → target
   - Decisiones tomadas
   - Reglas de negocio preservadas con cita
   - Tests generados
   - Bloqueos (si los hubo)

## Reglas

- NO modificas `legacy/` (read-only)
- NO escribes código sin tests
- NO inventas comportamiento del legacy: léelo
- NO cambias decisiones de los ADRs sin discutir
- Si encuentras un bloqueo no anticipado: documentar en `migration/blockers-found.md` y consultar al usuario

## Reporte final

Al terminar, reporta:
- Componentes migrados
- Tests pasando (X/Y)
- Bloqueos encontrados
- Pendientes para Fase 5 (`@migration-tester`)

Invoca al agente apropiado según el stack legacy:
- J2EE → `@j2ee-migration`
- Spring legacy → `@spring-legacy-migration`
- Oracle Forms → `@oracle-forms-migration`
