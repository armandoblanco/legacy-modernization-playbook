# Trampas en migración Oracle Forms → Java Spring Boot

Catálogo de problemas reales al migrar sistemas Oracle Forms (11g/12c) a stack web Java. Estos problemas son **distintos a J2EE y Spring legacy** porque Forms es un paradigma propio.

## 1. Lógica de negocio en .fmb binarios no extraídos

**Problema:** los archivos `.fmb` (Forms Module Binary) son binarios. La lógica de triggers (PL/SQL embebido) NO es visible sin extracción.

**Manifestación:** sistemas en producción 15-20 años donde nadie sabe qué hace exactamente cierto botón.

**Trampa:** asumir que toda la lógica está en packages PL/SQL de BD. La realidad: 20-40% suele estar en triggers de Forms.

**Solución:**
- Extraer todos los `.fmb` a XML con `frmf2xml` (requiere licencia Forms Builder) o script JDAPI
- Inventariar exhaustivamente cada trigger antes de migración
- Catalogar reglas de negocio extraídas con cita a `<form>:<trigger>:<línea>`

## 2. Generación automática de DML en base-table blocks

**Problema:** Oracle Forms genera automáticamente `INSERT/UPDATE/DELETE` para los base-table blocks cuando el usuario navega y commit. NO hay código SQL explícito.

**Manifestación:** un formulario de "mantenimiento de clientes" no tiene código SQL visible para insertar/actualizar; Forms lo hace en background.

**Trampa:** asumir que la migración a Java se limita a "reescribir lo que está visible". La realidad: cada CRUD debe ser código explícito.

**Solución:**
- Cada base-table block → Entity JPA + Repository + Service
- Cada commit del form → llamada explícita a `service.save()`, `service.update()`, `service.delete()`
- Validar constraints que se aplicaban con DML automático (NOT NULL, FK) ahora deben ser explícitos en validators

## 3. NULL semantics PL/SQL vs Java

**Problema:** PL/SQL trata `NULL = NULL` como NULL (no como TRUE ni FALSE). Java trata `null == null` como TRUE.

**Manifestación:**

```sql
-- PL/SQL
IF a = b THEN ... -- FALSE si ambos son NULL
IF a IS NULL AND b IS NULL THEN ... -- TRUE si ambos son NULL
```

```java
// Java
a.equals(b) // NullPointerException si a es null
Objects.equals(a, b) // TRUE si ambos null
```

**Trampa:** reescribir validaciones PL/SQL → Java sin considerar NULL puede cambiar comportamiento sutilmente. El test de paridad puede no detectarlo si los casos NULL no se prueban explícitamente.

**Solución:**
- Tests específicos para casos NULL en cada regla migrada
- Uso consistente de `Objects.equals()` y `Objects.isNull()` en Java
- Documentar cada caso donde la semántica difiere

## 4. Firing sequence de triggers

**Problema:** triggers de Forms se disparan en orden específico según la acción del usuario:

```
Insertar nuevo registro:
  WHEN-CREATE-RECORD → PRE-INSERT → POST-INSERT → ...

Validar item:
  WHEN-VALIDATE-ITEM → POST-CHANGE → WHEN-VALIDATE-RECORD
```

**Manifestación:** un PRE-INSERT que calcula un campo basándose en un valor que se setea en WHEN-CREATE-RECORD.

**Trampa:** reescribir triggers individualmente sin considerar la dependencia de orden. El service Java equivalente puede tener el código en orden incorrecto.

**Solución:**
- Documentar firing sequence relevante en cada feature
- Service Java replica el orden explícitamente
- Tests que validan el orden (no solo el resultado final, sino los estados intermedios cuando importan)

## 5. Triggers de tabla en BD con lógica de negocio

**Problema:** triggers de tabla Oracle (`BEFORE INSERT`, `AFTER UPDATE`) frecuentemente contienen lógica de negocio crítica.

**Manifestación:**

```sql
CREATE OR REPLACE TRIGGER TRG_PEDIDOS_TOTAL
BEFORE INSERT OR UPDATE ON T_PEDIDOS
FOR EACH ROW
BEGIN
    -- Recalcula total sumando T_PEDIDO_DETALLE
    SELECT SUM(cantidad * precio_unit)
    INTO :NEW.total
    FROM T_PEDIDO_DETALLE
    WHERE pedido_id = :NEW.id;
END;
```

**Trampa:** si la migración elimina el trigger sin replicar la lógica en service, los totales no se recalculan.

**Solución:**
- Decisión consciente en ADR sobre cada trigger: mantener en BD o migrar a service
- Si se migra: tests de regresión que validen el cálculo
- Si se mantiene: documentar que el sistema nuevo depende del trigger BD

## 6. LOVs (List of Values)

**Problema:** Forms tiene LOVs (dropdowns con datos) configurados con queries SQL inline o record groups. Un sistema típico tiene 100-500 LOVs.

**Manifestación:**

```sql
-- LOV en Forms
SELECT codigo, descripcion
FROM T_TIPOS_DOCUMENTO
WHERE activo = 'S'
ORDER BY descripcion
```

**Trampa:** reescribir cada LOV como un endpoint REST específico genera explosión de endpoints.

**Solución:** patrón genérico `LookupController + LookupService`:

```
GET /api/lookup/tipos_documento → [{code, label}, ...]
GET /api/lookup/paises → [{code, label}, ...]
GET /api/lookup/{tipo}?query=...
```

El service mapea cada tipo a su query SQL. Una vez implementado, agregar un nuevo LOV es agregar una entrada al switch del service.

## 7. CALL_FORM y navegación entre forms

**Problema:** Forms permite invocar otro form con `CALL_FORM('F_DETALLE')` manteniendo un stack de llamadas. El form llamador se "pausa" hasta que el llamado retorna.

**Manifestación:** flujos típicos de "doble click en lista → ventana de detalle → retorna a lista".

**Trampa:** modelo de stack de llamadas no existe en web. Migrar como modales o navegación SPA tiene UX distinto.

**Solución:**
- Para SPA: navegación con `navigate(...)` y state en URL
- Para Thymeleaf: redirects con session-stored state
- Documentar cambio de UX para usuarios

## 8. Forms con muchos campos (UI density)

**Problema:** formularios de Forms típicamente tienen 30-60 campos por pantalla en una densidad alta.

**Manifestación:** un mantenimiento de clientes muestra cédula, nombre, apellidos, dirección 1, dirección 2, teléfono, celular, email, fecha nacimiento, género, estado civil, profesión, ingresos, ... todo visible.

**Trampa:** rediseñar a "diseño moderno con espacios generosos" puede ser rechazado por usuarios acostumbrados a la densidad. Pierden context-at-a-glance.

**Solución:** UX research con usuarios. Mantener densidad alta para pantallas operativas, espacios generosos solo para pantallas exploratorias.

## 9. Reports en .rdf (Oracle Reports)

**Problema:** Reports `.rdf` también son binarios. Tienen queries SQL, layouts, parameters, formatos de output.

**Trampa:**
- Oracle Reports tiene end-of-support
- Reescribir reports complejos en JasperReports puede ser proyecto propio
- Layouts complejos (subreports, gráficos, master-detail) no son triviales

**Solución:**
- Inventario completo de reports en assessment
- Decisión por report: JasperReports / BI Publisher / Power BI / reescritura como dashboard
- Pilotear con el report más complejo

## 10. Java Applet / Web Start cliente

**Problema:** Forms 11g/12c se ejecuta en cliente como Java Applet (deprecated) o Java Web Start (deprecated). Browsers modernos no soportan applets.

**Manifestación:** clientes usan IE 11 o navegadores parchados ad-hoc para que el applet funcione.

**Trampa:** el cliente legacy probablemente ya está degradado. Los usuarios pueden estar usando versiones específicas de Java cliente.

**Solución:** la migración a web nativo resuelve esto, pero validar que los usuarios pueden actualizar su navegador.

## 11. Roles Oracle DB vs roles aplicación

**Problema:** Forms típicamente usa roles Oracle DB para permisos (usuarios y roles definidos en Oracle, asignados con `GRANT`).

**Manifestación:**

```sql
GRANT SELECT, INSERT, UPDATE ON T_CLIENTES TO ROL_ADMIN;
GRANT SELECT ON T_CLIENTES TO ROL_CONSULTA;
```

**Trampa:** en stack web, autenticación es de aplicación (Spring Security con usuarios en BD propia o LDAP). Permisos en `@PreAuthorize` o filters. Modelos NO son 1:1.

**Solución:**
- Decisión en ADR sobre modelo de permisos
- Migrar usuarios Oracle a tabla `T_USERS` y roles a `T_ROLES`
- O integrar con LDAP/AD si existe en la organización

## 12. Schema con nomenclatura inconsistente

**Problema:** schemas Oracle de 15-20 años suelen tener inconsistencias (tablas `T_*` y `TBL_*`, columnas mayúsculas y minúsculas, FKs con nombres inconsistentes).

**Trampa:** migrar tal cual mantiene la deuda. Limpiar requiere migración de datos.

**Solución:**
- Decisión consciente: mantener schema actual (más simple, menos valor) o limpiar (más caro, más valor)
- Si se limpia: documentar mapping legacy ↔ nuevo, considerar herramienta de sync durante transición

## 13. Triggers autónomos para auditoría

**Problema:** auditoría en Oracle se implementa típicamente con `PRAGMA AUTONOMOUS_TRANSACTION` para no afectar la transacción principal.

**Manifestación:**

```sql
CREATE OR REPLACE TRIGGER TRG_AUDIT_CLIENTES
AFTER INSERT OR UPDATE OR DELETE ON T_CLIENTES
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO T_AUDIT_LOG (...) VALUES (...);
    COMMIT;
END;
```

**Trampa:** en Java equivalente con Spring AOP `@AuditLog`, si la transacción principal falla y se hace rollback, el log de auditoría TAMBIÉN se hace rollback (a menos que se use `@Transactional(propagation = REQUIRES_NEW)`).

**Solución:**
- Si se mantiene en BD: trigger sigue funcionando
- Si se migra a Java: usar `REQUIRES_NEW` explícitamente para preservar comportamiento de transacción autónoma

## 14. Forms con dependencia de versión específica de Oracle DB

**Problema:** Forms usa features Oracle-specific (sequences, packages, types). Si la migración incluye también cambio de BD (Oracle → PostgreSQL), TODO el código PL/SQL debe migrarse.

**Trampa:** mezclar dos migraciones en un proyecto multiplica el riesgo. Cada migración es proyecto propio.

**Solución:** mantener Oracle DB en MVP de migración Forms→Java. Migrar BD como proyecto separado después si el cliente lo decide.

## 15. End of Support de Forms 12c

**Problema:** Premier Support de Oracle Fusion Middleware 12c termina **diciembre 2026**. Extended Support hasta diciembre 2027.

**Trampa:** clientes que postergaron migración 5+ años ahora tienen presión real, no marketing.

**Solución:** documentar timeline en propuesta. Después de EOS, no hay parches de seguridad ni bug fixes. Cliente debe decidir antes de Q4 2026.
