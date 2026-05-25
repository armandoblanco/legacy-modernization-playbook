---
applyTo: "src/**/*.java"
description: Convenciones para código Quarkus 3 generado durante migración. Se aplica cuando ADR-001 (o equivalente) define Quarkus como target.
---

# Quarkus 3: Convenciones

Estas convenciones aplican cuando ADR-001 selecciona Quarkus como target. La estructura es similar a Spring Boot pero con anotaciones y patterns propios de Quarkus.

---

## Versiones

- **Quarkus:** 3.15.x o última estable LTS
- **Java:** 21 LTS (o 17 según ADR-002)
- **Hibernate ORM:** la que traiga Quarkus (Hibernate 6.x con extensiones Quarkus)
- **Persistence:** Jakarta Persistence 3.x

---

## Estructura de paquetes

Misma estructura que Spring Boot:

```
com.{{client}}.{{projectName}}
├── domain/
├── application/
├── infrastructure/
├── presentation/
└── config/
```

---

## Inyección de dependencias

Quarkus usa CDI estándar (Jakarta Contexts and Dependency Injection):

- `@ApplicationScoped` para servicios singleton (equivalente Spring `@Service`)
- `@RequestScoped` para per-request
- `@Singleton` para singleton estricto (sin lazy init)
- `@Inject` para inyección (NO `@Autowired`)

```java
@ApplicationScoped
public class CustomerService {

    @Inject
    CustomerRepository repo;

    // O constructor injection (preferido):
    private final CustomerRepository repo;

    public CustomerService(CustomerRepository repo) {
        this.repo = repo;
    }
}
```

---

## REST endpoints

Quarkus usa JAX-RS (RESTeasy Reactive). NO Spring MVC.

```java
@Path("/api/v1/customers")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class CustomerResource {

    @Inject
    CustomerService service;

    @POST
    public Response create(@Valid CreateCustomerRequest req) {
        Long id = service.createCustomer(req.toCommand());
        return Response.created(URI.create("/api/v1/customers/" + id))
            .entity(new CustomerResponse(id))
            .build();
    }

    @GET
    @Path("/{id}")
    public CustomerResponse get(@PathParam("id") Long id) {
        return CustomerResponse.from(service.findById(id));
    }
}
```

Equivalencias rápidas:

| Spring | Quarkus (JAX-RS) |
| --- | --- |
| `@RestController` | `@Path` en clase |
| `@RequestMapping("/x")` | `@Path("/x")` |
| `@GetMapping` | `@GET` + `@Path` |
| `@PostMapping` | `@POST` |
| `@PathVariable` | `@PathParam` |
| `@RequestParam` | `@QueryParam` |
| `@RequestBody` | implícito |
| `ResponseEntity` | `Response` |

---

## Persistencia

Dos opciones:

### Opción A: Hibernate ORM con Panache (recomendado)

```java
@Entity
@Table(name = "T_CUSTOMER")
public class Customer extends PanacheEntity {  // o PanacheEntityBase para id custom

    @NotBlank
    @Column(name = "cedula", unique = true)
    public String cedula;

    @NotBlank
    @Column(name = "name")
    public String name;
}

// Repository active-record style:
@ApplicationScoped
public class CustomerRepository implements PanacheRepository<Customer> {
    public Optional<Customer> findByCedula(String cedula) {
        return find("cedula", cedula).firstResultOptional();
    }
}
```

### Opción B: Hibernate ORM estándar (sin Panache)

Casi idéntico a Spring Boot, pero sin Spring Data JPA. Usar `EntityManager` directo o repository custom.

```java
@ApplicationScoped
public class CustomerRepository {

    @Inject
    EntityManager em;

    public Optional<Customer> findByCedula(String cedula) {
        return em.createQuery("SELECT c FROM Customer c WHERE c.cedula = :cedula", Customer.class)
            .setParameter("cedula", cedula)
            .getResultStream()
            .findFirst();
    }
}
```

**Recomendación:** Panache si quieres reducir boilerplate. ORM estándar si quieres máxima familiaridad / portabilidad.

---

## Transacciones

`@Transactional` de Jakarta Transactions (NO el de Spring):

```java
import jakarta.transaction.Transactional;

@ApplicationScoped
public class CustomerService {

    @Transactional
    public Long createCustomer(CreateCustomerCommand cmd) {
        // ...
    }

    @Transactional(Transactional.TxType.SUPPORTS)
    public Customer findById(Long id) {
        // ...
    }
}
```

---

## Configuration

Quarkus usa `application.properties` (también soporta YAML con extension `quarkus-config-yaml`).

```properties
# application.properties
quarkus.datasource.db-kind=oracle
quarkus.datasource.username=${DB_USER}
quarkus.datasource.password=${DB_PASSWORD}
quarkus.datasource.jdbc.url=${DB_URL:jdbc:oracle:thin:@//localhost:1521/XEPDB1}

quarkus.hibernate-orm.dialect=org.hibernate.dialect.OracleDialect

# Profiles
%dev.quarkus.log.level=DEBUG
%prod.quarkus.log.level=INFO
```

Para configs estructurados:

```java
@ConfigMapping(prefix = "app.notifications")
public interface NotificationConfig {
    String fromEmail();
    List<String> adminEmails();
    @WithDefault("3")
    int retryAttempts();
}

@Inject
NotificationConfig config;
```

---

## Testing

```java
@QuarkusTest
class CustomerResourceTest {

    @Test
    void shouldCreateCustomer() {
        given()
            .contentType(ContentType.JSON)
            .body("""
                {"cedula":"112233445","name":"Acme"}
                """)
        .when()
            .post("/api/v1/customers")
        .then()
            .statusCode(201);
    }
}
```

Para tests con BD real:

```java
@QuarkusTest
@QuarkusTestResource(OracleTestResource.class) // implementación custom de Testcontainers
class CustomerRepositoryTest {
    // ...
}
```

---

## Native image (GraalVM)

Si el target incluye native build:

- Reflection y proxies requieren hints (`@RegisterForReflection`)
- Algunas librerías de terceros no funcionan en native (validar caso por caso)
- Build: `./mvnw package -Pnative`
- Tests native: `@NativeImageTest` (subset de tests)

Documentar en ADR si se va a usar native; añade complejidad pero da cold start <100ms.

---

## Logging

JBoss Logging por debajo, fachada Quarkus:

```java
import org.jboss.logging.Logger;

@ApplicationScoped
public class CustomerService {
    private static final Logger log = Logger.getLogger(CustomerService.class);
    // ...
}
```

O SLF4J:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
```

Quarkus soporta ambos transparentemente.

---

## Antipatrones

Mismos que Spring Boot, ajustados a Quarkus:

- ❌ `@Autowired` (no existe, usar `@Inject`)
- ❌ `@Component` (no existe, usar `@ApplicationScoped` / `@RequestScoped`)
- ❌ `RestController` + `@RequestMapping` (no, usar JAX-RS)
- ❌ Confundir `jakarta.transaction.Transactional` con `org.springframework.transaction.annotation.Transactional`
- ❌ Asumir Spring Data JPA (no existe en Quarkus, usar Panache o custom repo)
- ❌ Reflection sin hints si el build es native
