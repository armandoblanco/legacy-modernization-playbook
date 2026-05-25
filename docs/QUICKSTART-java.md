# Quickstart: Java legacy

Guía rápida para modernizar sistemas Java legacy usando el playbook. Cubre **tres sub-stacks** con agentes específicos para cada uno.

---

## Cuándo usar esta guía

Tu sistema Java legacy entra en uno de estos tres sub-stacks:

| Sub-stack | Características del legacy | Target típico |
| --- | --- | --- |
| **J2EE** | EJB 2.x/3.x, JSP, Servlets, WebLogic o WebSphere, Java 5/6/7 | Spring Boot 3 + Java 21 |
| **Spring legacy** | Spring 3.x/4.x, Struts 1/2, Java 6/7/8, configuración XML pesada | Spring Boot 3 + Java 21 |
| **Oracle Forms** | Forms 11g/12c (.fmb), PL/SQL embebido + en BD, librerías PLL, reports .rdf | Java Spring Boot o Oracle APEX |

Si tu sistema es Java 8+ moderno con Spring Boot 2.x o superior, **NO es legacy** según el alcance del playbook. Para esos casos un upgrade in-place sin agentes especializados suele ser suficiente.

---

## Pre-requisitos

1. **GitHub Copilot** habilitado en tu cuenta o organización
2. **VS Code** con la extensión GitHub Copilot Chat (Extension Pack for Java recomendado)
3. **Java 21 LTS** instalado localmente (Temurin, Liberica, o Oracle JDK)
4. **Maven 3.9+** o Gradle 8.x
5. Acceso al código fuente del sistema legacy
6. Para Oracle Forms: acceso a Forms Builder (licencia Oracle) para extraer los `.fmb` a XML

---

## Setup del proyecto

```bash
git clone https://github.com/armandoblanco/legacy-modernization-playbook.git mi-proyecto
cd mi-proyecto
rm -rf .git && git init

./bootstrap.sh      # Linux/macOS/WSL
.\bootstrap.ps1     # Windows
```

En el bootstrap:

- **Tecnología legacy:** `java`
- **Sub-stack Java:** `j2ee`, `spring-legacy`, u `oracle-forms` según corresponda

El bootstrap copia solo los 3 agentes del sub-stack elegido (más los 3 compartidos), no los 9. Esto mantiene el dropdown de Copilot manejable.

Coloca el código del sistema legacy:

```bash
mkdir -p legacy/
cp -r /ruta/al/sistema-java-legacy/* legacy/
```

**Para Oracle Forms** los `.fmb` son binarios y deben extraerse a XML antes del assessment:

```bash
# Usando frmf2xml de Oracle Forms Builder
cd legacy/forms/
for f in *.fmb; do
    frmf2xml "$f"
done
```

Esto deja archivos `.xml` paralelos a los `.fmb` que el agente puede leer.

---

## Flujo según sub-stack

### J2EE

```text
@j2ee-assessment Analiza el sistema en legacy/
```

Produce inventario de EJBs (session beans stateless/stateful, entity beans CMP/BMP, MDBs), JSPs con análisis de scriptlets, descriptores (`web.xml`, `ejb-jar.xml`, vendor-specific), JNDI lookups, transacciones XA, y features funcionales en `docs/features/`.

```text
@j2ee-planning Revisa el assessment y planifica la migración
```

Pregunta decisiones críticas:

- Spring Boot 3 vs Quarkus (default: Spring Boot 3 para LATAM)
- Java 17 LTS vs Java 21 LTS (default: Java 21)
- Manejo de Entity Beans CMP 2.x (típicamente: reescritura a JPA / Hibernate 6)
- Manejo de Stateful Session Beans (sesión HTTP, cache distribuido, o rediseño stateless)
- XA transactions: mantener con Atomikos, eliminar con Saga, o eliminar con Outbox pattern
- JMS provider target (mantener WebLogic JMS, migrar a ActiveMQ Artemis, Kafka, etc.)
- Frontend: Thymeleaf vs SPA según ADR-008
- Estrategia de cutover: Strangler Fig, Big Bang, o paralelo

Produce `docs/ARQUITECTURA-TARGET.md` + 10-15 ADRs en `docs/adr/`.

```text
@j2ee-migration Ejecuta la migración del sistema legacy
```

Bootstrap del proyecto target con `pom.xml` Spring Boot 3 + Java 21 + Hibernate 6 + Flyway + Testcontainers. Migra feature por feature respetando el orden topológico, aplica el namespace change `javax.*` → `jakarta.*` con OpenRewrite, traduce EJBs a `@Service` con `@Transactional` equivalente, y genera tests inmediatos.

### Spring legacy

```text
@spring-legacy-assessment Analiza el sistema en legacy/
```

Inventario de controllers (Spring MVC + Struts si aplica), services, repositories, configuración XML vs anotaciones, deprecated APIs, CVEs en dependencias del `pom.xml`, archivos afectados por el namespace change `javax.*` → `jakarta.*`, Hibernate XML mappings.

```text
@spring-legacy-planning Revisa el assessment y planifica la migración a Spring Boot 3
```

Decisiones:

- Upgrade in-place vs greenfield (depende de cobertura de tests y deuda técnica)
- Strategy del namespace change (OpenRewrite recipe oficial vs manual vs híbrido)
- Hibernate 6 migration (annotations vs mantener XML mappings)
- HibernateTemplate / HibernateDaoSupport → Spring Data JPA o EntityManager directo
- Struts (si existe) → Spring MVC o frontend SPA

Produce 8-12 ADRs.

```text
@spring-legacy-migration Ejecuta la migración del sistema legacy
```

Aplica OpenRewrite para el namespace change como primer paso masivo. Refactoriza Hibernate APIs deprecated (Criteria removido, custom UserType reescrito, etc.). Convierte XML configs a `@Configuration`. Migra Struts si aplica.

### Oracle Forms

```text
@oracle-forms-assessment Analiza el sistema Oracle Forms en legacy/extracted/
```

Catálogo de forms (blocks, items, triggers), librerías PLL con sus packages, menús MMB, packages PL/SQL en BD, triggers de tabla clasificados (auditoría vs lógica de negocio), reports `.rdf`, y reglas de negocio extraídas de triggers y packages.

```text
@oracle-forms-planning Revisa el assessment y planifica la migración
```

Decisiones únicas de Oracle Forms:

- **Target: Java Spring Boot vs Oracle APEX vs híbrido**: depende del cliente, equipo, y dependencia de Oracle DB
- **Dónde vive la lógica de negocio**: middle tier (Java) vs BD (PL/SQL packages) vs híbrido con criterios claros
- **Base de datos**: mantener Oracle vs migrar (PostgreSQL, etc.): recomendación fuerte de mantener para no mezclar dos migraciones
- **Reports `.rdf`**: JasperReports, BI Publisher, o Power BI
- **Pilot first**: define el módulo MÁS complejo del sistema para ejecutar primero

Produce ADRs + `docs/pilot-spec.md` con el módulo pilot.

```text
@oracle-forms-migration Ejecuta el pilot según docs/pilot-spec.md
```

**Ejecuta primero el módulo pilot.** Después del pilot exitoso, continúa con el resto. La reescritura traduce forms a páginas + REST + service + entity, valida NULL semantics PL/SQL vs Java en cada regla migrada, y genera tests de paridad funcional.

---

## Documentación complementaria

- **Overview de los 3 sub-stacks:** [`docs/technologies/java/00-overview.md`](technologies/java/00-overview.md)
- **Trampas técnicas:**
  - [`docs/technologies/java/01-trampas-j2ee.md`](technologies/java/01-trampas-j2ee.md)
  - [`docs/technologies/java/02-trampas-spring-legacy.md`](technologies/java/02-trampas-spring-legacy.md)
  - [`docs/technologies/java/03-trampas-oracle-forms.md`](technologies/java/03-trampas-oracle-forms.md)
- **Spring Boot 3 vs Quarkus:** [`docs/technologies/java/04-target-spring-vs-quarkus.md`](technologies/java/04-target-spring-vs-quarkus.md)
- **Convenciones de código:**
  - [`.github/instructions/java-target/spring-boot-3.instructions.md`](../.github/instructions/java-target/spring-boot-3.instructions.md)
  - [`.github/instructions/java-target/quarkus.instructions.md`](../.github/instructions/java-target/quarkus.instructions.md)
  - [`.github/instructions/java-target/jpa-hibernate.instructions.md`](../.github/instructions/java-target/jpa-hibernate.instructions.md)
- **Prompts:** [`.github/prompts/java/`](../.github/prompts/java/)
