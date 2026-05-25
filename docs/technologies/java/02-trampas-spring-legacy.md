# Trampas en migración Spring 3/4 + Struts → Spring Boot 3

Catálogo de problemas reales al migrar sistemas Spring 3.x/4.x sobre Java 6/7/8 a Spring Boot 3 + Java 21.

## 1. Namespace change `javax.*` → `jakarta.*`

**Problema:** Spring Boot 3 requiere Jakarta EE 9+ (todas las APIs cambiaron de `javax.persistence`, `javax.servlet`, `javax.ejb`, `javax.validation`, etc. a `jakarta.*`).

**Magnitud:** en sistemas típicos, **cientos a miles** de archivos afectados.

**Trampa:** intentar migrar manualmente es lento y error-prone. Pero OpenRewrite tampoco cubre 100% — código generado, strings hardcoded (`Class.forName("javax.persistence.X")`), custom adapters quedan fuera.

**Solución:**
1. OpenRewrite recipe `org.openrewrite.java.migrate.jakarta.JavaxMigrationToJakarta` como primer paso
2. Auditoría posterior con `grep -r "javax\.\(persistence\|servlet\|ejb\|jms\)" src` para residuos
3. Regenerar código generado con plugins versión jakarta (cxf-codegen, jaxb-tools, etc.)

## 2. Spring 3.x XML config sin equivalente directo

**Problema:** Sistemas Spring 3.x suelen tener `applicationContext.xml` con cientos de beans, AOP config XML, `<tx:annotation-driven>`, `<context:component-scan>`, etc.

**Trampa:** Spring Boot autoconfigura mucho de esto, pero hay configuraciones custom que requieren `@Configuration` manual. Conversión 1:1 mecánica puede generar código verboso e innecesario.

**Solución:** convertir XML por bloques, validar que el sistema arranca después de cada bloque eliminado. Aprovechar para limpiar beans no usados.

## 3. `HibernateTemplate` y `HibernateDaoSupport` deprecated

**Problema:** `HibernateTemplate` está deprecated desde Spring 3.x y **removido** en Spring 5+/SB3.

**Trampa:** sistemas Spring 3.x lo usan masivamente. Cada DAO debe refactorizar a `EntityManager` directo o Spring Data JPA.

**Solución:**
- CRUD estándar → Spring Data JPA `JpaRepository`
- Queries complejas → custom repository con `@PersistenceContext EntityManager`

## 4. Hibernate 6 breaking changes

**Problema:** Spring Boot 3 trae Hibernate 6.x. Cambios mayores vs Hibernate 4/5:

- `org.hibernate.Criteria` (legacy Criteria) **removido** — migrar a `jakarta.persistence.criteria.CriteriaBuilder`
- `Session.createSQLQuery()` API cambió — usar `EntityManager.createNativeQuery()`
- Custom `UserType` API **completamente reescrita** — cada UserType requiere reescritura
- `@Enumerated` puede serializar distinto en algunos casos
- `LocalSessionFactoryBean` patterns cambiaron
- HQL parser más estricto: queries antes válidas ahora son errores

**Trampa:** algunas migraciones de Hibernate parecen exitosas en tests unitarios pero fallan en escenarios de producción con queries complejas.

**Solución:**
- Tests exhaustivos en cada query no trivial
- Activar Hibernate SQL logging en dev para validar queries generadas
- Validar custom UserTypes uno por uno

## 5. Hibernate 6 strict mode con relaciones EAGER

**Problema:** Hibernate 6 lanza `MultipleBagFetchException` cuando hay múltiples collections EAGER que no pueden ser cargadas en una sola query.

**Trampa:** código que en Hibernate 4 funcionaba (con N+1 silenciosos) en H6 falla en arranque.

**Solución:** convertir collections a LAZY + FETCH explícito o `@EntityGraph` cuando se necesiten.

## 6. `@Enumerated(EnumType.STRING)` vs `EnumType.ORDINAL`

**Problema:** sistemas legacy suelen usar `EnumType.ORDINAL` (default) que persiste el índice del enum. Si se agrega un valor al medio del enum, datos se corrompen.

**Trampa:** la migración es buen momento para cambiar a STRING, pero requiere migración de datos.

**Solución:** mantener ORDINAL si el sistema ya lo usa; cambiar a STRING solo con migración de datos planificada.

## 7. Struts 1.x — end of life

**Problema:** Struts 1.x es EOL desde 2013. Sin actualizaciones, sin parches de seguridad.

**Trampa:** clientes que "lo dejaron porque funciona" no tienen consciencia del riesgo.

**Solución:** Struts 1.x no es negociable, debe salir. Migrar a Spring MVC `@Controller`. Form beans → DTOs. Actions → controller methods. `struts-config.xml` → eliminado.

## 8. Struts 2.x con versión vulnerable

**Problema:** Struts 2.x con versión < 2.5.13 es vulnerable a CVE-2017-5638 (Apache Struts OGNL injection, RCE).

**Trampa:** sistemas en producción con esta versión están expuestos. La migración a Spring MVC es el plan correcto pero mientras tanto el riesgo es real.

**Solución:**
- Si la migración es a mediano plazo: upgrade emergency a Struts 2.5.x parchado mientras migración progresa
- WAF reglas para mitigar mientras tanto
- Documento de riesgo para cliente

## 9. Acegi Security

**Problema:** Acegi era el predecesor de Spring Security (pre-2008). Sistemas muy antiguos pueden tenerlo.

**Trampa:** reescritura completa, NO hay path de upgrade Acegi → Spring Security.

**Solución:** reescritura como Spring Security 6.x. Es trabajo grande pero la deuda técnica es alta.

## 10. `commons-collections` 3.x con CVE-2015-7501

**Problema:** Apache Commons Collections 3.x tiene gadget de deserialización Java explotable (RCE).

**Trampa:** dependencia transitiva en muchas librerías legacy.

**Solución:** upgrade a Commons Collections 4.x (paquete cambió a `org.apache.commons.collections4`) y refactor de imports. O eliminar dependencia si Java 8+ collections nativas cubren el uso.

## 11. Log4j 1.x — EOL + CVEs

**Problema:** Log4j 1.x está EOL desde 2015 y tiene CVEs históricas. Log4j 2.x tiene CVE-2021-44228 (Log4Shell) que requiere mínimo 2.17.x.

**Trampa:** migración a Log4j 2.x puede romper configuración existente (formato XML / properties diferente).

**Solución:** Spring Boot 3 trae Logback por default. Migrar a Logback o Log4j 2.x parchado. Reescribir `log4j.xml` → `logback-spring.xml` o `log4j2-spring.xml`.

## 12. Java 6/7/8 → Java 17/21

**Problema:** salto grande de versiones Java.

**Trampa:**
- `sun.misc.*` removido
- `javax.xml.bind.*` (JAXB) removido en Java 11 — necesita dependencia explícita en Jakarta
- `javax.activation` removido — idem
- Module system (JPMS) puede causar `IllegalAccessError` en código con reflection profunda
- TLS defaults cambiaron — sistemas legacy pueden no negociar con servidores nuevos o viejos
- `String.intern()` con comportamiento ajustado

**Solución:**
- Plan de upgrade incremental: Java 8 → 11 (validar) → 17 (validar) → 21
- Tests exhaustivos en cada salto
- `--add-opens` o `--add-exports` para reflection legacy si es absolutamente necesario (mejor refactorizar)

## 13. SOAP services con CXF / Axis 1 antiguo

**Problema:** sistemas legacy con clients/servers SOAP usando Axis 1.x o CXF antiguo no compatibles con Jakarta.

**Trampa:** WSDL parsing puede fallar después del upgrade.

**Solución:** Apache CXF 4.x (compatible Jakarta) y regenerar clients. O migrar a REST si el servicio expuesto/consumido es propio.

## 14. Generated code con `javax.*`

**Problema:** plugins de generación de código (XMLBeans, JAXB, CXF, MyBatis Generator viejo) generan código con `javax.*`.

**Trampa:** después del namespace change, código generado no compila.

**Solución:** actualizar versiones de los plugins a las versiones que generan `jakarta.*` y regenerar.

## 15. Spring `MultipartResolver` movido

**Problema:** `CommonsMultipartResolver` (de Apache Commons FileUpload) deprecated. Spring Boot 3 usa `StandardServletMultipartResolver` por default.

**Trampa:** configuración legacy de upload de archivos puede dejar de funcionar silenciosamente.

**Solución:** eliminar `CommonsMultipartResolver` y usar la configuración estándar de Spring Boot con `spring.servlet.multipart.*` properties.
