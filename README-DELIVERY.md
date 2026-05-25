# Entrega — Módulos Java para legacy-modernization-playbook

**Fecha:** 2026-05-22
**Alcance:** Módulos Java completos (9 agentes específicos + instructions + prompts + docs)

---

## Resumen ejecutivo

Esta entrega agrega cobertura completa para **3 sub-stacks Java legacy** al playbook:

| Sub-stack | Cobertura | Agentes |
| --- | --- | --- |
| **J2EE** | EJB 2.x/3.x, JSP, Servlets, WebLogic/WebSphere | `j2ee-{assessment,planning,migration}` |
| **Spring legacy** | Spring 3.x/4.x con Struts, Java 6/7/8 | `spring-legacy-{assessment,planning,migration}` |
| **Oracle Forms** | Forms 11g/12c, PL/SQL embebido + en BD | `oracle-forms-{assessment,planning,migration}` |

Stack target soportado: **Spring Boot 3.x** o **Quarkus 3.x** sobre Java 21 LTS (decisión por ADR en Fase 2).

---

## Archivos entregados (22 nuevos)

### Agentes (9 en `.github/agents/java/`)

```
.github/agents/java/
├── j2ee-assessment.agent.md           (486 líneas) — Fase 1 J2EE
├── j2ee-planning.agent.md             (601 líneas) — Fase 2 J2EE
├── j2ee-migration.agent.md            (640 líneas) — Fase 4 J2EE
├── spring-legacy-assessment.agent.md  (494 líneas) — Fase 1 Spring 3/4
├── spring-legacy-planning.agent.md    (256 líneas) — Fase 2 Spring 3/4
├── spring-legacy-migration.agent.md   (510 líneas) — Fase 4 Spring 3/4
├── oracle-forms-assessment.agent.md   (558 líneas) — Fase 1 Oracle Forms
├── oracle-forms-planning.agent.md     (399 líneas) — Fase 2 Oracle Forms
└── oracle-forms-migration.agent.md    (678 líneas) — Fase 4 Oracle Forms
```

**Total: ~4,600 líneas de markdown** de agentes.

### Instructions (3 en `.github/instructions/java-target/`)

```
.github/instructions/java-target/
├── spring-boot-3.instructions.md     Convenciones SB3 (DI, JPA, REST, etc.)
├── quarkus.instructions.md           Convenciones Quarkus 3 (CDI, JAX-RS)
└── jpa-hibernate.instructions.md     Convenciones JPA 3.x + Hibernate 6
```

Se aplican automáticamente al código en `src/**/*.java` según `applyTo` en frontmatter.

### Prompts (4 en `.github/prompts/java/`)

```
.github/prompts/java/
├── analizar-modulo.prompt.md     Analizar un módulo específico del legacy
├── generar-adr.prompt.md         Crear ADR para una decisión arquitectónica
├── migrar-modulo.prompt.md       Migrar un módulo al stack target
└── validar-paridad.prompt.md     Validar paridad funcional legacy ↔ nuevo
```

### Docs (5 en `docs/technologies/java/`)

```
docs/technologies/java/
├── 00-overview.md                    Overview de los 3 sub-stacks
├── 01-trampas-j2ee.md                15 trampas técnicas en migración J2EE
├── 02-trampas-spring-legacy.md       15 trampas en upgrade Spring 3/4 → SB3
├── 03-trampas-oracle-forms.md        15 trampas específicas Oracle Forms
└── 04-target-spring-vs-quarkus.md    Criterios de decisión SB3 vs Quarkus
```

### Patch para bootstrap

```
BOOTSTRAP-JAVA-PATCH.md   Instrucciones para modificar bootstrap.sh/.ps1
                          y agregar pregunta de sub-stack Java
```

---

## Decisiones arquitectónicas aplicadas

1. **Bootstrap pregunta sub-stack Java** (igual que VB6/VBNet) y solo copia 3 agentes del elegido. Mantiene el dropdown de Copilot manejable (6 agentes totales: 3 Java + 3 shared).

2. **Stack target (Spring Boot vs Quarkus) se decide en Fase 2** y cristaliza en `docs/ARQUITECTURA-TARGET.md`. Fase 4 (migration) solo lee la decisión, no tiene `if/else`. Las instructions modulares (`spring-boot-3.instructions.md` vs `quarkus.instructions.md`) se cargan según el ADR.

3. **Oracle Forms agente pilot first**: el agente `oracle-forms-planning` define `docs/pilot-spec.md` con el módulo MÁS complejo. `oracle-forms-migration` ejecuta el pilot antes del resto. Es la diferencia entre éxito y desastre en Oracle Forms migrations.

4. **PL/SQL en Oracle Forms**: el agente reconoce explícitamente que la lógica puede vivir en BD o middle tier (decisión por ADR). NO fuerza Java para todo.

5. **NUNCA mezclar migración Java + migración de BD** en el mismo proyecto. El agente planning lo dice explícitamente.

6. **OpenRewrite recipe oficial** (`org.openrewrite.java.migrate.jakarta.JavaxMigrationToJakarta`) como primer paso del namespace change. Battle-tested.

---

## Cómo aplicar al repo

### Paso 1: Copiar archivos nuevos al repo

Desde el ZIP de esta entrega, copiar al working copy del repo:

```bash
# Asumiendo que estás en la raíz del repo legacy-modernization-playbook

# Crear directorios si no existen
mkdir -p .github/agents/java
mkdir -p .github/instructions/java-target
mkdir -p .github/prompts/java
mkdir -p docs/technologies/java

# Copiar los 22 archivos desde el ZIP
unzip legacy-modernization-playbook-java-modules.zip -d .
```

### Paso 2: Aplicar patch al bootstrap

Seguir las instrucciones en `BOOTSTRAP-JAVA-PATCH.md`:

- Agregar el bloque de pregunta sub-stack Java
- Agregar la copia flat selectiva de los 3 agentes Java
- Modificar el mensaje final con la invocación correcta

### Paso 3: Actualizar README.md y README.en.md

Cambiar la tabla de tecnologías. Donde dice:

```
| Java legacy (J2EE, Java 6/7/8) | Placeholder | docs/technologies/java/ |
```

Cambiar a:

```
| Java legacy | ✅ Completo (3 sub-stacks: J2EE, Spring 3/4, Oracle Forms) | docs/technologies/java/ |
```

Y agregar referencia en la sección de agentes específicos:

```markdown
- **Java legacy:**
  - J2EE: `@j2ee-assessment` · `@j2ee-planning` · `@j2ee-migration`
  - Spring 3/4: `@spring-legacy-assessment` · `@spring-legacy-planning` · `@spring-legacy-migration`
  - Oracle Forms: `@oracle-forms-assessment` · `@oracle-forms-planning` · `@oracle-forms-migration`
```

### Paso 4: Validación manual

```bash
# Verificar que todos los archivos fueron copiados
find .github/agents/java -name "*.agent.md" | wc -l   # debe ser 9
find .github/instructions/java-target -name "*.md" | wc -l  # debe ser 3
find .github/prompts/java -name "*.md" | wc -l  # debe ser 4
find docs/technologies/java -name "*.md" | wc -l  # debe ser 5

# Verificar frontmatter de los agentes
for f in .github/agents/java/*.agent.md; do
    head -8 "$f"
    echo "---"
done

# Test bootstrap (en directorio temporal)
cp -r . /tmp/test-bootstrap
cd /tmp/test-bootstrap
./bootstrap.sh
# Probar opción "java" → verificar que pregunta sub-stack
# Probar cada sub-stack → verificar que solo copia 3 agentes a flat
```

### Paso 5: Commit

```bash
git add .github/agents/java/
git add .github/instructions/java-target/
git add .github/prompts/java/
git add docs/technologies/java/
git add bootstrap.sh bootstrap.ps1  # con el patch aplicado
git add README.md README.en.md

git commit -m "Add complete Java legacy modernization coverage

Adds 9 agents covering 3 Java sub-stacks (J2EE, Spring legacy, Oracle Forms),
3 instruction files for target stacks (Spring Boot 3, Quarkus, JPA/Hibernate),
4 prompts for common Java migration tasks, and 5 docs with technology-specific
guidance.

Bootstrap updated to ask Java sub-stack and copy only the 3 agents of the
chosen sub-stack to flat .github/agents/ (consistent with VB6/VBNet pattern).

Target stack decision (Spring Boot 3 vs Quarkus) is made in Phase 2 and
crystallized in docs/ARQUITECTURA-TARGET.md. Phase 4 reads the ADR without
branching logic."
```

---

## Validación técnica de la entrega

### Referencias verificadas con web_search

- ✅ EJB 2.x CMP migration challenges (CMR remapping, abstract getters/setters)
- ✅ Spring Boot 3 baseline Java 17 + Jakarta EE 9 namespace change
- ✅ Hibernate 6 breaking changes (Criteria API removed, UserType API rewritten)
- ✅ Oracle Forms .fmb extraction with frmf2xml (Pretius blog)
- ✅ Premier Support Oracle Fusion Middleware 12c hasta diciembre 2026
- ✅ Struts 1.x EOL desde 2013, Struts 2.x CVE-2017-5638
- ✅ OpenRewrite recipe `org.openrewrite.java.migrate.jakarta.JavaxMigrationToJakarta`
- ✅ Pilot of MOST complex module first (Pretius / Legacyleap docs)
- ✅ Oracle APEX como alternativa válida a Java para Forms migration

### Modelos en frontmatter

- Assessment, Planning: `Claude Opus 4.6 (copilot)` — razonamiento profundo
- Migration: `Claude Sonnet 4.6 (copilot)` — velocidad + precisión en transformaciones

Consistente con el resto del repo.

---

## Lo que NO se incluye en esta entrega

- **Workshop Java**: el usuario decidió "no por ahora". Si más adelante se requiere, replicar estructura de `workshop/vb/` con scenarios j2ee, spring-legacy, oracle-forms.

- **Sample legacy code Java**: el playbook no incluye samples de código legacy en ninguna tecnología (es decisión del repo). El usuario aporta el código en `legacy/` por proyecto.

- **Soporte Oracle APEX**: el agente `oracle-forms-planning` reconoce APEX como respuesta válida pero el playbook NO tiene agentes APEX. Si el cliente elige APEX, el playbook termina ahí.

- **Bootstrap modificado completo**: solo se entrega el patch (`BOOTSTRAP-JAVA-PATCH.md`). El usuario aplica las modificaciones al bootstrap actual del repo.

---

## Próximos pasos sugeridos (TODO futuro)

1. **Workshop Java** (~50% más trabajo). Sería un workshop por sub-stack con scenarios reales.

2. **Sample legacy code Java** para validar end-to-end:
   - Mini J2EE app (~5 KLOC) con EJB 2.x + JSP
   - Mini Spring 4 app (~5 KLOC) con Struts + Hibernate 4
   - Mini Oracle Forms app (~3-5 forms, 10 packages PL/SQL)

3. **Agente APEX** si en futuro proyectos de Oracle Forms migran a APEX en lugar de Java.

4. **Validación end-to-end del bootstrap modificado** en Linux, macOS, Windows. Pendiente porque requiere VS Code + Copilot reales.

---
