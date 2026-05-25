# Stack target: Spring Boot 3 vs Quarkus 3

Criterios para decidir entre los dos targets soportados por el playbook. Esta decisión se cristaliza en `docs/ARQUITECTURA-TARGET.md` durante Fase 2 (planning) y los agentes de Fase 4 solo leen esa decisión.

## Resumen de trade-offs

| Aspecto | Spring Boot 3.x | Quarkus 3.x |
| --- | --- | --- |
| **Madurez enterprise** | Muy alta (mayor adopción) | Alta (creciente, especialmente en Red Hat shops) |
| **Documentación** | Enorme, comunidad masiva | Buena, comunidad creciente |
| **Tiempo de arranque (JVM)** | 3-8 segundos | 1-2 segundos |
| **Tiempo de arranque (native image)** | <100ms (con GraalVM, mayor fricción) | <100ms (first-class support) |
| **Memoria (JVM)** | ~200-500MB típico | ~100-200MB típico |
| **Memoria (native)** | ~50-100MB | ~30-80MB |
| **Hot reload en dev** | DevTools (decente) | Live coding (excelente, instantáneo) |
| **Curva de aprendizaje desde Spring** | Continua | Significativa (CDI vs Spring DI, JAX-RS vs Spring MVC) |
| **Curva desde Java EE / J2EE** | Manejable | Más natural (usa CDI estándar) |
| **Librerías third-party** | Más amplias | Buenas pero menos exóticas |
| **Cloud native (K8s)** | Bueno (Spring Cloud) | Excelente (Kubernetes-native first) |
| **Reactive support** | Spring WebFlux (separado) | Reactive native (RESTeasy Reactive) |
| **GraalVM native** | Soportado (más configuración) | First-class (mejor experiencia) |
| **Comunidad LATAM** | Predominante | Minoritaria |
| **Talento disponible** | Muy alto | Más nicho |

## Cuándo elegir Spring Boot 3

- **El equipo del cliente tiene experiencia Spring previa** (incluso Spring 3/4 cuenta — los conceptos transfieren)
- **Migración desde Spring legacy**: continuidad natural
- **Deploy en VMs / contenedores tradicionales** sin presión de cold start
- **Necesidad de librerías de integración exóticas** (Spring Integration tiene 100+ adapters)
- **Equipo prefiere documentación abundante** con muchos ejemplos blog/StackOverflow
- **Sistema de mayor tamaño** donde la madurez del ecosistema importa
- **Cliente mainstream sin presión cloud-native agresiva**

**Recomendación default para LATAM enterprise:** Spring Boot 3, salvo razones específicas para Quarkus.

## Cuándo elegir Quarkus 3

- **Despliegue en Kubernetes con autoescalado agresivo** donde cold start importa (escalar a cero, escalar bajo carga, serverless)
- **Native image es requirement** (containers de pocos MB, footprint mínimo, FaaS)
- **El cliente está en Red Hat ecosystem** (RHEL, OpenShift, Camel)
- **Equipo cómodo con CDI / JAX-RS** (estándares Jakarta EE)
- **Aplicaciones reactive de alta concurrencia** donde RESTeasy Reactive da ventaja
- **Sistemas distribuidos pequeños** donde Quarkus DevServices simplifica desarrollo

**No es default LATAM** porque talento Quarkus es escaso, salvo nichos específicos.

## Cuándo NO importar tanto la decisión

Si el sistema es un **monolito modesto desplegado en pocas instancias** que arranca una vez por día/semana, el cold start no importa. La decisión entonces es de preferencia del equipo, no técnica.

## Criterios anti-patrón (señales de mala decisión)

### "Elegimos Quarkus porque es más moderno"

- "Moderno" no es un criterio técnico
- Spring Boot 3 es igual de moderno en términos de APIs (Java 21, Jakarta EE 10, GraalVM, reactive)
- Si el equipo no tiene razón concreta para Quarkus, Spring Boot reduce riesgo

### "Elegimos Spring Boot porque siempre usamos Spring"

- Tampoco es criterio técnico
- Si el cliente va a Kubernetes con autoescalado y cold start importa: validar si Quarkus aplica
- Validar requirements, no defaultear por inercia

### "Elegimos uno y el otro lo agregamos después"

- Mezclar stacks en el mismo proyecto multiplica complejidad
- Si hay duda fuerte: hacer un spike con un módulo en cada uno antes de decidir
- NO migrar la mitad en uno y la mitad en otro

## Cómo decide el agente

El agente de planning (`@j2ee-planning`, `@spring-legacy-planning`, `@oracle-forms-planning`) pregunta al usuario explícitamente con la tabla de trade-offs y los criterios. NO decide unilateralmente.

La decisión queda registrada en `docs/adr/001-stack-target.md` (o número equivalente) con:

- Contexto del cliente
- Decisión específica
- Razones objetivas (no "es mejor")
- Alternativa rechazada con por qué
- Consecuencias positivas, negativas y mitigaciones

## Cómo la usa Fase 4 (migration)

El agente de migración (`@j2ee-migration`, `@spring-legacy-migration`, `@oracle-forms-migration`) lee el ADR-001 y aplica el conjunto de instructions correspondiente:

- Si Spring Boot 3 → `.github/instructions/java-target/spring-boot-3.instructions.md`
- Si Quarkus 3 → `.github/instructions/java-target/quarkus.instructions.md`

Ambos casos cargan también `jpa-hibernate.instructions.md` para el código de persistencia.

NO hay `if Spring/else Quarkus` en cada sección de cada agente — la decisión está cristalizada.

## Migración cruzada Spring Boot ↔ Quarkus

Si después de elegir uno, el cliente quiere cambiar al otro:

- **Spring Boot → Quarkus:** reescritura significativa (DI, REST, configuración cambian)
- **Quarkus → Spring Boot:** similar

Es proyecto propio, no "ajuste". Documentar en propuesta si esto puede pasar a futuro y planificar contractos limpios (DTOs, ports) que reduzcan el blast radius.
