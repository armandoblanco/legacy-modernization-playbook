---
applyTo: "src/**/*.java"
description: Convenciones para código Spring Boot 3 generado durante migración desde J2EE, Spring legacy, u Oracle Forms. Se aplica cuando ADR-001 (o equivalente) define Spring Boot 3 como target.
---

# Spring Boot 3 — Convenciones

Estas convenciones aplican a todo código nuevo generado en `src/` cuando el target stack es Spring Boot 3 sobre Java 21 (o Java 17 según ADR).

---

## Versiones

- **Spring Boot:** 3.4.x (o la última estable LTS al momento del proyecto)
- **Java:** 21 LTS (o 17 según ADR-002)
- **Hibernate:** la que traiga Spring Boot, sin override manual
- **JPA:** Jakarta Persistence 3.x

NO usar versiones snapshot ni milestone en producción.

---

## Estructura de paquetes

```
com.{{client}}.{{projectName}}
├── domain/                  # Entities, Value Objects, Domain Services puros
│   ├── customer/
│   ├── order/
│   └── ...
├── application/             # Use Cases, Services orquestadores
│   ├── customer/
│   ├── order/
│   └── ...
├── infrastructure/          # Adapters: persistence, messaging, external APIs
│   ├── persistence/
│   ├── messaging/
│   ├── external/
│   └── config/
├── presentation/            # Controllers, DTOs, Request/Response, Mappers
│   ├── rest/
│   ├── web/                # Si Thymeleaf
│   └── advice/             # ExceptionHandlers
└── config/                  # SpringBootApplication, security, etc.
```

NO mezclar capas. Un controller no llama directo a repository.

---

## Imports

- **SIEMPRE** `jakarta.*` para EE APIs (persistence, validation, servlet, etc.)
- **NUNCA** mezclar `javax.*` y `jakarta.*` en el mismo proyecto
- **PREFERIR** imports específicos sobre wildcard (`import jakarta.persistence.Entity;` NO `import jakarta.persistence.*;`)

---

## Inyección de dependencias

- **Constructor injection siempre.** NO field injection con `@Autowired`.
- Constructor sin `@Autowired` (Spring lo infiere desde Boot 2.6+).
- Marcar campos como `final`.

```java
// Correcto
@Service
public class CustomerService {
    private final CustomerRepository repo;
    private final ValidationService validator;

    public CustomerService(CustomerRepository repo, ValidationService validator) {
        this.repo = repo;
        this.validator = validator;
    }
}

// Incorrecto
@Service
public class CustomerService {
    @Autowired
    private CustomerRepository repo;
}
```

---

## Entities JPA

- `@Entity` + `@Table(name = "...")` siempre con nombre explícito
- `@Column(name = "...")` siempre con nombre explícito (no depender de naming strategy implícita)
- Usar `@GeneratedValue` con sequence generator para Oracle, `IDENTITY` para Postgres/SQL Server
- Constructor protected sin args (para JPA) + constructor de negocio público
- NO `@Data` de Lombok en entities (problemas con equals/hashCode + lazy loading)
- `equals/hashCode` basado en business key, no en `id`

```java
@Entity
@Table(name = "T_CUSTOMER")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "customer_seq")
    @SequenceGenerator(name = "customer_seq", sequenceName = "S_CUSTOMER_ID", allocationSize = 1)
    @Column(name = "customer_id")
    private Long id;

    @NotBlank
    @Size(max = 9)
    @Column(name = "cedula", unique = true, nullable = false, length = 9)
    private String cedula;

    @NotBlank
    @Size(max = 100)
    @Column(name = "name", nullable = false, length = 100)
    private String name;

    protected Customer() {} // JPA

    public Customer(String cedula, String name) {
        this.cedula = cedula;
        this.name = name;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Customer that)) return false;
        return Objects.equals(cedula, that.cedula); // business key, no id
    }

    @Override
    public int hashCode() {
        return Objects.hash(cedula);
    }

    // getters
}
```

---

## Relaciones JPA

- `@ManyToOne` siempre `FetchType.LAZY` (default es EAGER, malo)
- `@OneToMany` y `@ManyToMany` siempre LAZY (default ya)
- NO usar `EAGER` salvo justificación documentada en código
- Para cargar relaciones, usar `@EntityGraph` o JOIN FETCH en queries específicas
- Evitar N+1 queries: profilar con Hibernate logging activo

---

## Repositories

- Heredar `JpaRepository<Entity, IdType>` para CRUD estándar
- Query methods con naming Spring Data (`findByName`, `existsByCedula`, etc.)
- `@Query` con JPQL para queries complejas
- `@Query(nativeQuery = true)` solo cuando JPQL no alcanza
- NO inyectar `EntityManager` en repositories — usar custom repository pattern

```java
public interface CustomerRepository extends JpaRepository<Customer, Long> {

    Optional<Customer> findByCedula(String cedula);

    @Query("SELECT c FROM Customer c LEFT JOIN FETCH c.orders WHERE c.id = :id")
    Optional<Customer> findByIdWithOrders(@Param("id") Long id);
}
```

---

## Services

- Lógica de negocio aquí, NO en controllers
- `@Transactional` a nivel de método (no clase) para granularidad
- `@Transactional(readOnly = true)` para queries puras
- Exceptions de negocio: subclases de `RuntimeException`, capturadas por `@ControllerAdvice`

```java
@Service
public class CustomerService {

    private final CustomerRepository repo;

    public CustomerService(CustomerRepository repo) {
        this.repo = repo;
    }

    @Transactional
    public Long createCustomer(CreateCustomerCommand cmd) {
        if (repo.findByCedula(cmd.cedula()).isPresent()) {
            throw new ConflictException("Cedula ya existe");
        }
        Customer c = new Customer(cmd.cedula(), cmd.name());
        return repo.save(c).getId();
    }

    @Transactional(readOnly = true)
    public Customer findById(Long id) {
        return repo.findById(id)
            .orElseThrow(() -> new NotFoundException("Customer not found: " + id));
    }
}
```

---

## Controllers REST

- `@RestController` para APIs JSON, `@Controller` para vistas server-rendered
- Path bajo `/api/v1/...` (versionado en URL)
- DTOs separados: `XxxRequest` (input), `XxxResponse` (output)
- NUNCA exponer entities directo en endpoints (riesgo de fugas y problemas de lazy loading)
- `ResponseEntity` cuando necesitas headers o status custom
- `@Valid` en request bodies que necesitan validación

```java
@RestController
@RequestMapping("/api/v1/customers")
public class CustomerController {

    private final CustomerService service;

    public CustomerController(CustomerService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<CustomerResponse> create(@Valid @RequestBody CreateCustomerRequest req) {
        Long id = service.createCustomer(req.toCommand());
        return ResponseEntity.created(URI.create("/api/v1/customers/" + id))
            .body(new CustomerResponse(id));
    }

    @GetMapping("/{id}")
    public CustomerResponse get(@PathVariable Long id) {
        return CustomerResponse.from(service.findById(id));
    }
}
```

---

## DTOs

- Records de Java (no clases) cuando son inmutables
- Validation annotations en records: `@NotBlank`, `@Email`, etc.
- Factory method estático `from(Entity)` en response DTOs
- Factory method `toCommand()` en request DTOs

```java
public record CreateCustomerRequest(
    @NotBlank @Size(min = 9, max = 9) String cedula,
    @NotBlank @Size(max = 100) String name,
    @Email String email
) {
    public CreateCustomerCommand toCommand() {
        return new CreateCustomerCommand(cedula, name, email);
    }
}

public record CustomerResponse(Long id, String cedula, String name) {
    public static CustomerResponse from(Customer c) {
        return new CustomerResponse(c.getId(), c.getCedula(), c.getName());
    }
}
```

---

## Exception handling

- `@RestControllerAdvice` centralizado para excepciones REST
- Excepciones de dominio: `NotFoundException`, `ConflictException`, `ValidationException`
- Mapeo a HTTP status codes consistente

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(NotFoundException ex) {
        return ResponseEntity.status(404).body(new ErrorResponse(ex.getMessage()));
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ErrorResponse> handleConflict(ConflictException ex) {
        return ResponseEntity.status(409).body(new ErrorResponse(ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        // ... extraer field errors
    }
}
```

---

## Configuration

- `application.yml` por sobre `application.properties` (más legible para nested)
- Profiles: `application-dev.yml`, `application-prod.yml`, etc.
- Secretos: nunca hardcoded, usar env vars `${VAR}` o vault
- `@ConfigurationProperties` para configs estructurados, NO `@Value` disperso

```java
@ConfigurationProperties(prefix = "app.notifications")
@Validated
public record NotificationProperties(
    @NotBlank String fromEmail,
    @NotEmpty List<String> adminEmails,
    @Min(1) int retryAttempts
) {}
```

---

## Logging

- SLF4J + Logback (default de Spring Boot)
- NO `System.out.println` ni `e.printStackTrace()`
- Logger por clase: `private static final Logger log = LoggerFactory.getLogger(MyClass.class);`
- O usar `@Slf4j` de Lombok si Lombok está en el proyecto
- Niveles: DEBUG para diagnóstico, INFO para flujo normal, WARN para situaciones recuperables, ERROR para fallos
- NUNCA loggear passwords, tokens, datos PII

---

## Testing

- JUnit 5 + AssertJ + Mockito
- Tests de repository: `@DataJpaTest` + Testcontainers (BD real, no H2 en memoria)
- Tests de service: `@SpringBootTest` con `@MockBean` para dependencias externas, O test unitario con Mockito puro
- Tests de controller: `@WebMvcTest` + MockMvc
- Tests de integración end-to-end: `@SpringBootTest(webEnvironment = RANDOM_PORT)` + TestRestTemplate / WebTestClient

```java
@DataJpaTest
@Testcontainers
class CustomerRepositoryTest {

    @Container
    static OracleContainer oracle = new OracleContainer("gvenzl/oracle-xe:21-slim");

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", oracle::getJdbcUrl);
        // ...
    }

    @Autowired CustomerRepository repo;

    @Test
    void shouldFindByCedula() {
        repo.save(new Customer("112233445", "Acme"));
        Optional<Customer> found = repo.findByCedula("112233445");
        assertThat(found).isPresent();
    }
}
```

NO usar H2 en memoria como sustituto de la BD real cuando el target es Oracle/Postgres específico — los dialectos divergen.

---

## Migrations de BD

- Flyway o Liquibase desde el día 1
- Scripts en `src/main/resources/db/migration/V{N}__{descripcion}.sql`
- Numeración secuencial: V1__init.sql, V2__add_customer_table.sql
- NEVER editar una migration ya aplicada en producción
- Para entornos legacy: primera migration suele ser `V1__baseline.sql` con `flyway baseline`

---

## Antipatrones a evitar

- ❌ `@Autowired` en fields (usar constructor)
- ❌ `@Transactional` en controllers (debe estar en services)
- ❌ Exponer Entities en controllers (siempre DTOs)
- ❌ Catch de Exception genérico
- ❌ `EAGER` fetching por default
- ❌ Queries dentro de loops (causa N+1)
- ❌ `e.printStackTrace()` en código productivo
- ❌ Hardcodear strings de error (i18n con messages.properties)
- ❌ `H2` como reemplazo de la BD real en tests críticos
- ❌ Mezclar `javax.*` y `jakarta.*`
- ❌ Configuración XML salvo casos específicos (Spring Security a veces, Camel routes)
