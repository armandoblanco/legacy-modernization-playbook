# Java legacy → Java 21 + Spring Boot 3 (o equivalentes)

> **Estado:** Placeholder. Pendiente poblar con casos reales.

## Alcance previsto

| Origen | Target |
| --- | --- |
| J2EE 1.4 / Java EE 5–7 (EJB 2.x/3.x, JSP, Struts, JSF) | Spring Boot 3 + Java 21 / Quarkus / Micronaut |
| Java 6 / 7 / 8 con frameworks legacy | Java 21 LTS |
| Spring 3 / 4 con XML config | Spring Boot 3 (Java config + Spring Framework 6) |
| Aplicaciones en WebLogic / WebSphere / JBoss EAP 5–7 | Tomcat embebido / Quarkus / contenedores |

## Particularidades a documentar

- `javax.*` → `jakarta.*` (Jakarta EE 9+ namespace change)
- Servlets / JSP / Struts → Spring MVC / WebFlux / Thymeleaf
- EJB Stateless / Stateful → Spring beans / CDI
- JPA 1.0 (Hibernate 3) → JPA 3.x (Hibernate 6.x)
- `log4j` 1.x → `log4j2` o `logback` (Log4Shell mitigado)
- `commons-*` legacy → `java.util` moderno o `commons-lang3` actualizado
- Construcción: Ant → Maven / Gradle
- Servidor de aplicaciones → contenedor + Spring Boot embebido
- Java Modules (JPMS) opcional pero recomendado
- Records, sealed classes, pattern matching, virtual threads (Java 21)

## Pendiente

- [ ] `trampas-java.md`
- [ ] `decision-stack-java.md` (Spring Boot vs Quarkus vs Micronaut, MVC vs Reactive)
- [ ] `.github/agents/java/01-assessment.agent.md`
- [ ] `.github/agents/java/02-planning.agent.md`
- [ ] `.github/agents/java/03-migration.agent.md`
- [ ] Workshop / lab

## Herramientas externas

- **OpenRewrite** (recetas de transformación)
- **Application Modernization for Java** (extensión VS Code, MCP `appmod`)
- **WindUp / MTA / MTR** (Migration Toolkit for Applications, Red Hat)
- **Azure Migrate: app modernization for Java**, **Spring Apps**, **Container Apps**

## Notas

Hoy hay tooling muy maduro asistido por IA + recetas (OpenRewrite). El valor del agente Copilot está en assessment, planning, y validación de paridad — no tanto en la conversión sintáctica que ya hacen las recetas.
