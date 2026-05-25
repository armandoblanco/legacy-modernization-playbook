---
applyTo: "src/**/entity/**/*.java,src/**/domain/**/*.java,src/**/persistence/**/*.java,src/**/repository/**/*.java"
description: Convenciones para entidades JPA, repositories, y queries usando Hibernate 6. Aplica tanto en Spring Boot como en Quarkus.
---

# JPA / Hibernate 6 — Convenciones

Convenciones para código de persistencia. Aplica a entities, repositories, queries, mappings.

---

## Versiones

- **JPA:** Jakarta Persistence 3.x (`jakarta.persistence.*`)
- **Hibernate:** 6.x (incluido en Spring Boot 3 / Quarkus 3)

NUNCA mezclar imports de `javax.persistence.*` y `jakarta.persistence.*`.

---

## Diseño de entities

### Naming

- Clase entity: nombre singular, PascalCase (`Customer`, `Order`)
- Tabla: nombre explícito con `@Table(name = "...")`, convención SQL (mayúsculas + underscore común en legacy Oracle: `T_CUSTOMER`)
- Columna: nombre explícito con `@Column(name = "...")`

### IDs

```java
// Para Oracle (con sequence existente del legacy)
@Id
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "customer_seq")
@SequenceGenerator(name = "customer_seq", sequenceName = "S_CUSTOMER_ID", allocationSize = 1)
@Column(name = "customer_id")
private Long id;

// Para Postgres / SQL Server
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
@Column(name = "customer_id")
private Long id;

// Para UUIDs (rara vez necesario en migración legacy)
@Id
@GeneratedValue(strategy = GenerationType.UUID)
@Column(name = "customer_id")
private UUID id;
```

**`allocationSize = 1`** importante para Oracle: el default (50) reserva bloques de 50 IDs por sesión, lo cual genera "huecos" si una sesión no usa todos.

### Constructors

- Constructor protected sin args (para JPA)
- Constructor público de negocio con campos obligatorios
- NO setters para campos inmutables (ej. `id`, `createdAt`)

```java
@Entity
@Table(name = "T_CUSTOMER")
public class Customer {

    @Id @GeneratedValue(...)
    private Long id;

    @NotBlank @Size(max = 9, min = 9)
    @Column(name = "cedula", unique = true, nullable = false)
    private String cedula; // inmutable después de creación

    @NotBlank @Size(max = 100)
    @Column(name = "name", nullable = false)
    private String name;

    protected Customer() {} // JPA

    public Customer(String cedula, String name) {
        this.cedula = cedula;
        this.name = name;
    }

    public Long getId() { return id; }
    public String getCedula() { return cedula; }
    // NO setCedula porque es inmutable

    public String getName() { return name; }
    public void setName(String name) { this.name = name; } // mutable
}
```

### Equals y hashCode

Basado en **business key**, NO en `id`:

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Customer that)) return false;
    return Objects.equals(cedula, that.cedula);
}

@Override
public int hashCode() {
    return Objects.hash(cedula);
}
```

Razón: usar `id` rompe `Set<Customer>` cuando la entidad aún no persiste (id == null).

---

## Relaciones

### `@ManyToOne`

```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "country_id")
private Country country;
```

**SIEMPRE LAZY.** El default es EAGER, lo cual causa N+1 y degradación de performance silenciosa.

### `@OneToMany`

```java
@OneToMany(mappedBy = "customer", cascade = CascadeType.ALL, orphanRemoval = true)
private Set<Order> orders = new HashSet<>();
```

- Inicializar la collection a `new HashSet<>()` o `new ArrayList<>()`, NO null
- `mappedBy` apunta al campo del otro lado
- `cascade` según semántica de dominio (CASCADE.ALL para composiciones, vacío para asociaciones)
- `orphanRemoval = true` cuando los hijos no tienen sentido sin el padre

### `@ManyToMany`

Evitar si es posible. Usar entity intermedia con `@OneToMany`/`@ManyToOne`:

```java
// NO recomendado para casos no triviales
@ManyToMany
@JoinTable(...)
private Set<Role> roles;

// Recomendado: entity intermedia
@OneToMany(mappedBy = "user")
private Set<UserRole> userRoles;
```

La entity intermedia permite agregar campos (fecha asignación, asignado por, etc.).

### Helper methods bidireccionales

Mantener consistencia entre lados de la relación:

```java
public void addOrder(Order order) {
    orders.add(order);
    order.setCustomer(this);
}

public void removeOrder(Order order) {
    orders.remove(order);
    order.setCustomer(null);
}
```

NO permitir modificar la collection directamente desde afuera (devolver `Collections.unmodifiableSet()` en el getter).

---

## Fetch strategies

### Default: LAZY siempre

```java
@ManyToOne(fetch = FetchType.LAZY) // explícito
@OneToMany // LAZY por default
```

### Cargar relaciones cuando se necesitan

#### Opción A: JOIN FETCH en query específica

```java
@Query("SELECT c FROM Customer c LEFT JOIN FETCH c.orders WHERE c.id = :id")
Optional<Customer> findByIdWithOrders(@Param("id") Long id);
```

#### Opción B: @EntityGraph

```java
@EntityGraph(attributePaths = {"orders", "country"})
Optional<Customer> findById(Long id);
```

Usar `@EntityGraph` para "el mismo find pero con relaciones cargadas". Usar JOIN FETCH para casos especiales con WHERE custom.

### Detectar N+1

Activar logging de Hibernate en dev:

```yaml
spring:
  jpa:
    properties:
      hibernate:
        format_sql: true
    show-sql: true
logging:
  level:
    org.hibernate.SQL: DEBUG
    org.hibernate.orm.jdbc.bind: TRACE
```

Si ves N+1 queries en un endpoint, refactor con FETCH o EntityGraph.

---

## Queries

### Spring Data JPA query methods

Spring genera la query desde el nombre del método:

```java
public interface CustomerRepository extends JpaRepository<Customer, Long> {

    Optional<Customer> findByCedula(String cedula);

    List<Customer> findByNameContainingIgnoreCase(String name);

    List<Customer> findByCountryIdAndActiveTrue(Long countryId);

    boolean existsByCedula(String cedula);

    long countByActiveTrue();
}
```

Para queries complejas, `@Query`:

```java
@Query("SELECT c FROM Customer c WHERE c.active = true AND c.createdAt >= :since")
List<Customer> findActiveCustomersSince(@Param("since") Instant since);
```

### Native queries

Cuando JPQL no alcanza (queries Oracle-specific, hints, etc.):

```java
@Query(value = "SELECT * FROM T_CUSTOMER c WHERE REGEXP_LIKE(c.email, :regex)",
       nativeQuery = true)
List<Customer> findByEmailMatching(@Param("regex") String regex);
```

### CriteriaBuilder para queries dinámicas

Cuando los filtros varían en runtime:

```java
public interface CustomerRepositoryCustom {
    Page<Customer> search(CustomerSearchCriteria criteria, Pageable pageable);
}

public class CustomerRepositoryCustomImpl implements CustomerRepositoryCustom {

    @PersistenceContext
    private EntityManager em;

    @Override
    public Page<Customer> search(CustomerSearchCriteria criteria, Pageable pageable) {
        CriteriaBuilder cb = em.getCriteriaBuilder();
        CriteriaQuery<Customer> cq = cb.createQuery(Customer.class);
        Root<Customer> root = cq.from(Customer.class);

        List<Predicate> predicates = new ArrayList<>();
        if (criteria.name() != null) {
            predicates.add(cb.like(cb.lower(root.get("name")), "%" + criteria.name().toLowerCase() + "%"));
        }
        if (criteria.countryId() != null) {
            predicates.add(cb.equal(root.get("country").get("id"), criteria.countryId()));
        }
        cq.where(cb.and(predicates.toArray(new Predicate[0])));

        TypedQuery<Customer> query = em.createQuery(cq);
        query.setFirstResult((int) pageable.getOffset());
        query.setMaxResults(pageable.getPageSize());

        // Count para Page
        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        countQuery.select(cb.count(countQuery.from(Customer.class))).where(predicates.toArray(new Predicate[0]));
        Long total = em.createQuery(countQuery).getSingleResult();

        return new PageImpl<>(query.getResultList(), pageable, total);
    }
}
```

---

## Migraciones desde Hibernate 3/4/5 a 6

### APIs removidas

- `org.hibernate.Criteria` (legacy Criteria) → reemplazar por `jakarta.persistence.criteria.CriteriaBuilder`
- `org.hibernate.Restrictions` → reemplazar por `CriteriaBuilder` predicates
- `Session.createSQLQuery()` → `EntityManager.createNativeQuery()`

### Custom UserType

API completamente reescrita. Cada UserType custom requiere reescritura:

```java
// Hibernate 6
public class MoneyType implements UserType<Money> {

    @Override
    public int getSqlType() { return Types.DECIMAL; }

    @Override
    public Class<Money> returnedClass() { return Money.class; }

    @Override
    public boolean equals(Money x, Money y) { return Objects.equals(x, y); }

    @Override
    public int hashCode(Money x) { return Objects.hashCode(x); }

    @Override
    public Money nullSafeGet(ResultSet rs, int position, SharedSessionContractImplementor session, Object owner) throws SQLException {
        BigDecimal val = rs.getBigDecimal(position);
        return val == null ? null : new Money(val);
    }

    @Override
    public void nullSafeSet(PreparedStatement st, Money value, int index, SharedSessionContractImplementor session) throws SQLException {
        st.setBigDecimal(index, value == null ? null : value.amount());
    }

    @Override
    public Money deepCopy(Money value) { return value; } // si es inmutable

    @Override
    public boolean isMutable() { return false; }

    @Override
    public Serializable disassemble(Money value) { return value; }

    @Override
    public Money assemble(Serializable cached, Object owner) { return (Money) cached; }
}
```

Anotación en el campo: `@Type(MoneyType.class)` (no `@TypeDef` legacy).

### `@Enumerated`

Hibernate 6 cambió cómo serializa enums por default en algunos casos. Validar después de upgrade.

### `EAGER` que antes funcionaba ahora rompe

Hibernate 6 es más estricto con queries que no pueden cargar EAGER en una sola query. Si aparecen errores `MultipleBagFetchException`, refactor a LAZY + FETCH explícito.

---

## Antipatrones a evitar

- ❌ Default fetch EAGER en `@ManyToOne`
- ❌ N+1: cargar collection en loop sin FETCH
- ❌ equals/hashCode basado en id
- ❌ Setters públicos para todos los campos
- ❌ `EntityManager.merge()` cuando lo que quieres es update sin reattach
- ❌ Cascade ALL en asociaciones que no son composiciones
- ❌ `@ManyToMany` con campos extra en la relación
- ❌ Exponer entities directamente en APIs REST (lazy loading exceptions)
- ❌ Mezclar `javax.persistence.*` y `jakarta.persistence.*`
- ❌ Native query con string concatenation (SQL injection)
- ❌ Tests con H2 cuando la BD productiva es Oracle/Postgres (dialectos divergen)
- ❌ Olvidar `allocationSize = 1` en sequences Oracle (causa huecos)
