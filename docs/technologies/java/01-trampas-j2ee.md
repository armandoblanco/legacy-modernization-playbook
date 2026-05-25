# Trampas en migración J2EE → Spring Boot 3

Catálogo de problemas reales encontrados al migrar sistemas J2EE clásicos (EJB 2.x/3.x, JSP, Servlets) a Spring Boot 3.

## 1. Entity Beans CMP 2.x

**Problema:** Entity Beans CMP (Container Managed Persistence) 2.x usan abstract getters/setters y el container genera la implementación. NO existe equivalente directo en JPA.

**Manifestación:**

```java
// Legacy
public abstract class CustomerBean implements EntityBean {
    public abstract Integer getCustomerId();
    public abstract void setCustomerId(Integer id);
    // CMR (Container Managed Relationships)
    public abstract Collection getOrders();
}
```

**Trampa:**
- CMRs con `cascade-delete` automático no son 1:1 con `CascadeType.REMOVE` JPA en todos los casos
- Finders declarados en `<query>` de `ejb-jar.xml` requieren reescritura como JPA `@NamedQuery` o Spring Data methods
- `ejbCreate(...)` con lógica de inicialización NO mapea a constructor JPA limpio

**Solución:**
- Reescritura manual a `@Entity` POJO con anotaciones JPA
- Cada CMR documentado caso por caso (cardinalidad, cascade, fetch)
- Cada finder reescrito con tests de paridad
- Estimación realista: 2-4 horas por Entity Bean según complejidad de relaciones

## 2. Stateful Session Beans

**Problema:** SFSBs mantienen estado conversacional entre llamadas del cliente. Spring Boot no tiene equivalente directo.

**Manifestación:**

```java
@Stateful
public class ShoppingCartBean implements ShoppingCart {
    private List<Item> items = new ArrayList<>();

    public void addItem(Item item) { items.add(item); }
    public BigDecimal checkout() { /* calcula total y persiste */ }
}
```

**Trampa:**
- Migración naïve a `@SessionScope` requiere sticky sessions o sesión distribuida
- Cluster sin sticky sessions = comportamiento errático
- Rediseño a stateless requiere persistir estado en cada call (carrito en BD, no en memoria)

**Solución (más limpia):** rediseñar como stateless con estado explícito en BD o cache distribuido (Redis, Hazelcast).

**Solución (más rápida pero con overhead):** `@SessionScope` + sesión distribuida con Spring Session Redis.

## 3. JNDI lookups

**Problema:** El código legacy usa `InitialContext.lookup("jdbc/CustomerDS")` para datasources, queues, otros EJBs. En Spring Boot esto se reemplaza con DI y configuración.

**Trampa:**
- Lookups con string concatenation dinámica son difíciles de detectar con grep
- Lookups en código de filter / servlet que se ejecuta antes que el Spring context esté listo
- Lookups a EJBs remotos (otro servidor) requieren protocolo aparte (REST, gRPC)

**Solución:** auditoría exhaustiva con `grep -rE "lookup\s*\(" legacy/src` + reemplazo caso por caso.

## 4. XA transactions distribuidas

**Problema:** Container-managed XA con `UserTransaction` enlistando múltiples datasources o JMS providers.

**Manifestación:**

```java
@TransactionAttribute(TransactionAttributeType.REQUIRED)
public void processOrder(Order o) {
    em1.persist(o);                       // BD A
    em2.persist(generateAudit(o));        // BD B
    jmsTemplate.send("order-events", o);  // MQ
    // Todo en una sola transacción XA
}
```

**Trampa:**
- Spring Boot soporta XA con Atomikos o Bitronix, pero añade complejidad operacional
- Cada participante XA debe ser XA-enabled (no todas las versiones de drivers JDBC lo son)
- Performance degrada significativamente

**Solución recomendada:** eliminar XA, reemplazar con:
- **Outbox pattern**: transacción local que escribe a tabla de outbox, relay async publica al MQ
- **Saga pattern**: pasos compensables si algún paso falla
- **Eventual consistency** con idempotencia en consumers

## 5. JAX-RPC clients

**Problema:** JAX-RPC (predecessor de JAX-WS) fue removido en Java 11+.

**Manifestación:** imports de `javax.xml.rpc.*` en clientes de servicios SOAP.

**Trampa:** No es un namespace change a `jakarta.xml.rpc.*` — JAX-RPC NO existe en Jakarta EE.

**Solución:** reescribir clients usando JAX-WS (`jakarta.xml.ws.*`) o, mejor, exponer los servicios como REST.

## 6. Web descriptors vendor-specific

**Problema:** `weblogic-ejb-jar.xml`, `ibm-ejb-jar-bnd.xml`, etc. contienen configuración crítica (pool sizes, JNDI mappings, cluster settings) que NO migra automáticamente.

**Trampa:** olvidar revisar estos archivos hasta que el sistema modernizado falla en producción por configuración faltante.

**Solución:** inventario explícito de cada setting vendor-specific durante assessment + decisión consciente de equivalente en Spring Boot (`application.yml`, `@ConfigurationProperties`, profiles).

## 7. JSPs con scriptlets ≥20%

**Problema:** JSPs con lógica Java embebida no migran limpio a Thymeleaf.

**Manifestación:**

```jsp
<% Connection conn = DriverManager.getConnection(...);
   PreparedStatement ps = conn.prepareStatement("SELECT ...");
   ResultSet rs = ps.executeQuery();
   while (rs.next()) { %>
       <tr><td><%= rs.getString("name") %></td></tr>
<% } %>
```

**Trampa:** asumir que Thymeleaf puede reemplazar JSP 1:1 — solo si la lógica está separada en controllers + JSTL.

**Solución:** extracción de lógica a controller + service ANTES de migrar template a Thymeleaf. Esto puede duplicar el esfuerzo estimado para esos JSPs.

## 8. Servlet filters vs Spring filters

**Problema:** Filters Java EE declarados en `web.xml` siguen funcionando en Spring Boot pero la integración con Spring Security puede ser tricky.

**Trampa:** orden de filters legacy + filters de Spring Security puede causar requests que no llegan al controller esperado.

**Solución:** registrar filters legacy como `FilterRegistrationBean` con orden explícito relativo a Spring Security.

## 9. `javax.*` → `jakarta.*` en código generado

**Problema:** Código generado por plugins (JAX-WS wsimport, JAXB xjc, CXF codegen) genera con `javax.*`. OpenRewrite no toca código generado.

**Trampa:** después del namespace change, el código fuente está en `jakarta.*` pero el generado en `javax.*`, causando errores de compilación.

**Solución:** actualizar versiones de los plugins a las versiones que generan `jakarta.*` y regenerar todo.

## 10. Spring Boot 3 baseline Java 17

**Problema:** Spring Boot 3 requiere Java 17 mínimo. Si el legacy es Java 8 o anterior, hay APIs intermedias que cambiaron.

**Trampa:** olvidar que cambios entre Java 8 y 17 incluyen:
- `sun.misc.*` removido (algunos hacks de reflection)
- Módulos JPMS (algunas reflections requieren `--add-opens`)
- `String.intern()` con comportamiento ajustado
- TLS defaults cambiaron (sistemas legacy pueden no negociar)

**Solución:** plan de upgrade Java 8 → 11 → 17 → 21 si el equipo no tiene experiencia previa, validando en cada salto.
