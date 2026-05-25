# Modernización Java: Overview

El playbook cubre **tres sub-stacks Java legacy** con agentes específicos:

| Sub-stack | Característica | Agentes |
| --- | --- | --- |
| **J2EE** | EJB 2.x/3.x, JSP, Servlets, WebLogic/WebSphere | `j2ee-{assessment,planning,migration}` |
| **Spring legacy** | Spring 3.x/4.x, Struts 1/2, Java 6/7/8 | `spring-legacy-{assessment,planning,migration}` |
| **Oracle Forms** | Forms 11g/12c, PL/SQL embebido + en BD | `oracle-forms-{assessment,planning,migration}` |

Cada sub-stack tiene su propio flujo porque las decisiones son distintas:

- J2EE requiere decidir cómo manejar Entity Beans CMP, Stateful Session Beans, XA transactions
- Spring legacy requiere decidir upgrade in-place vs greenfield, strategy del namespace change
- Oracle Forms requiere decidir Java vs APEX, dónde vive la lógica (BD vs middle tier), y ejecutar pilot

## Stack target común

Independiente del sub-stack legacy, el target es uno de:

- **Spring Boot 3.x** sobre Java 21 LTS (default recomendado)
- **Quarkus 3.x** sobre Java 21 LTS (cloud-native, cold start crítico)

La decisión se cristaliza en `docs/ARQUITECTURA-TARGET.md` durante Fase 2 (planning). Los agentes de Fase 4 (migration) solo leen esa decisión, no la cuestionan.

## Workflow

Los tres sub-stacks comparten el flujo de 5 fases del playbook:

```
Fase 1: Assessment
   ↓
Fase 2: Planning (decisión de target stack)
   ↓
Fase 2.5: Refinement (scoping con cliente)
   ↓
Fase 3: Modernization Strategy (Gartner 6R, si aplica)
   ↓
Fase 4: Migration (ejecución)
   ↓
Fase 5: Testing (paridad)
```

Los agentes shared (`plan-refiner`, `modernization-strategy`, `migration-tester`) se usan transversalmente.

## Cuándo usar cada sub-stack

```
¿El sistema tiene archivos .fmb / .fmx / .pll?
    SÍ → oracle-forms
    NO → ¿Tiene EJBs (ejb-jar.xml, @Stateless, @Entity de javax.ejb)?
              SÍ → j2ee
              NO → ¿Usa Spring 3.x o 4.x?
                       SÍ → spring-legacy
                       NO → revisar: probablemente no es Java legacy en el sentido tradicional
```

Si hay mezcla (ej. un sistema J2EE con un módulo Oracle Forms): tratar cada módulo como proyecto separado o el más grande define el sub-stack.

## Documentos de referencia

- `01-trampas-j2ee.md`: trampas técnicas en migración J2EE → Spring Boot
- `02-trampas-spring-legacy.md`: trampas en upgrade Spring 3/4 → Spring Boot 3
- `03-trampas-oracle-forms.md`: trampas específicas de Forms (PL/SQL, NULL semantics, DML automático)
- `04-target-spring-vs-quarkus.md`: criterios de decisión entre Spring Boot 3 y Quarkus

## Bootstrap

Cuando el usuario corre el bootstrap.sh / bootstrap.ps1 y elige Java como `LEGACY_TECH`, se le pregunta el sub-stack:

```
1) j2ee          : EJB, JSP, WebLogic/WebSphere
2) spring-legacy : Spring 3.x/4.x, Struts
3) oracle-forms  : Oracle Forms (.fmb)
```

Solo los 3 agentes del sub-stack elegido se copian al directorio plano `.github/agents/` (junto con los shared). Esto mantiene el dropdown de Copilot manejable.
