# Validation Checklist

Lista de verificación manual antes de mergear estos cambios a `main` o de usar el repo con un cliente real. **Yo no pude validar estos pasos automáticamente** porque requieren VS Code con Copilot real. Tú debes ejecutarlos.

---

## 1. Bootstrap funcional (5 minutos)

### En Linux/macOS/WSL

```bash
# Clonar el repo en una carpeta temporal limpia
git clone https://github.com/armandoblanco/legacy-modernization-playbook.git /tmp/test-bootstrap
cd /tmp/test-bootstrap
rm -rf .git

# Ejecutar el bootstrap con valores de prueba
./bootstrap.sh
# Responde:
#   Nombre del proyecto: TestProject
#   Cliente: TestClient
#   Tech: 1 (vb)
#   Sub-lenguaje: 1 (vb6)
#   Stack: 2 (wpf)
#   Cloud: 1 (azure)
#   Continuar: s
```

**Verificar:**

- [ ] El script imprime "✓ Bootstrap completado" sin errores
- [ ] `.copilot-project.yml` existe con los valores ingresados
- [ ] `.github/agents/` contiene 10 archivos `.agent.md` flat (no subfolders solamente)
- [ ] El script **NO se autoeliminó**: `ls bootstrap.sh` lo encuentra
- [ ] Las carpetas `legacy/`, `migration/`, `src/`, `assessment/TestProject/` existen
- [ ] Los archivos `.md` ya no contienen `{{ProjectName}}` (verifica con `grep -r "{{" docs/`)

### En Windows (PowerShell)

```powershell
git clone https://github.com/armandoblanco/legacy-modernization-playbook.git C:\temp\test-bootstrap
cd C:\temp\test-bootstrap
Remove-Item -Recurse -Force .git

.\bootstrap.ps1
# Responde lo mismo que arriba
```

**Verificar las mismas cosas que en bash.**

### Re-ejecución del bootstrap

```bash
# Cambiar a otra tecnología sin reclonar
./bootstrap.sh
# Responde:
#   Tech: 2 (dotnet-framework)
#   (resto igual)
```

**Verificar:**

- [ ] Los agentes en `.github/agents/` flat ahora son los de `dotnet-framework` + `shared` (no `vb`)
- [ ] `.copilot-project.yml` se actualizó con `legacy_tech: dotnet-framework`
- [ ] No hubo errores al re-ejecutar

---

## 2. Discovery de agentes en VS Code (10 minutos)

**Requisito:** VS Code con extensión GitHub Copilot Chat habilitada y suscripción activa (Pro, Business o Enterprise).

```bash
cd /tmp/test-bootstrap
code .
```

**Pasos en VS Code:**

1. Abre Copilot Chat (Cmd/Ctrl+Alt+I o el ícono lateral)
2. Busca el **agent picker** (dropdown al lado del input de chat, no el icono de "@")
3. Verifica que aparezcan los 10 agentes:

   - [ ] `business-case-analyst`
   - [ ] `security-assessor`
   - [ ] `modernization-strategy`
   - [ ] `cloud-architect`
   - [ ] `azure-architect`
   - [ ] `plan-refiner`
   - [ ] `migration-tester`
   - [ ] `vb-assessment`
   - [ ] `vb-planning`
   - [ ] `vb-migration`

4. Selecciona `modernization-strategy` del dropdown
5. Verifica que el chat muestra el comportamiento esperado del agente (responde como consultor de modernización, no como el agente general de Copilot)

**Si NO aparecen los agentes:**

- [ ] Verifica que estás en VS Code, NO en el terminal de VS Code
- [ ] `Cmd/Ctrl+Shift+P` → "Developer: Reload Window"
- [ ] Verifica que tu cuenta de Copilot tiene acceso a custom agents (algunos planes individuales no lo tienen)
- [ ] Confirma con `ls .github/agents/*.agent.md` que los archivos están al nivel flat

**Caso de prueba simple:** Selecciona el agente `modernization-strategy` y escribe:

> "Tengo una app en VB6 con dependencias de Crystal Reports y PISPEC.OCX. ¿Qué estrategia recomendarías?"

Verifica que la respuesta:

- [ ] Lee `.copilot-project.yml` (puede pedirte cargarlo si la conversación es nueva)
- [ ] Aplica el framework 6R's, no responde genéricamente
- [ ] Pregunta por contexto antes de decidir (uso actual, valor de negocio, etc.)
- [ ] Eventualmente propone Refactor o Rebuild con justificación específica

---

## 3. Visual Studio 2026 (si aplica)

Si tu equipo usa Visual Studio 2026 versión 18.4 o posterior:

```
File → Open → Folder → C:\temp\test-bootstrap
```

En Copilot Chat:

- [ ] Escribe `@modernization-strategy` y verifica que aparece como sugerencia
- [ ] Si aparece, ejecuta el mismo caso de prueba del paso 2

---

## 4. GitHub Copilot CLI (si aplica)

Si usas `gh copilot` con custom agents:

```bash
cd /tmp/test-bootstrap
gh copilot
# Dentro del prompt:
/agent
```

- [ ] Verifica que los 10 agentes aparecen en la lista
- [ ] Selecciona uno y ejecuta un comando simple

**Nota:** Como confirmado en issues #2245 y #1859 de copilot-cli, los agentes en subcarpetas NO se descubren. Solo los que están en `.github/agents/` flat.

---

## 5. Validación del agente `@plan-refiner` (10 minutos)

Este agente solo tiene sentido si hay output de Fase 2 (Planning). Para probarlo necesitas:

1. Tener `docs/features/` con al menos 3 features documentados (puede ser ficticio)
2. Tener `docs/ARQUITECTURA-TARGET.md`
3. Tener al menos 2-3 ADRs en `docs/adr/`

**Setup rápido para probar:**

```bash
cd /tmp/test-bootstrap
mkdir -p docs/features docs/adr
echo "# Feature: autenticacion" > docs/features/01-auth.md
echo "# Feature: reportes-antiguos" > docs/features/02-reportes-antiguos.md
echo "# Feature: clientes" > docs/features/03-clientes.md
echo "# ARQUITECTURA TARGET" > docs/ARQUITECTURA-TARGET.md
echo "# ADR-001: Stack" > docs/adr/ADR-001.md
echo "# Plan de migración" > docs/migration-plan.md
```

Luego en Copilot Chat:

- [ ] Selecciona `plan-refiner` del dropdown
- [ ] Escribe: "Revisemos el plan: hay código muerto, gaps o exclusiones?"
- [ ] Verifica que el agente:
  - Lee los archivos de `docs/features/` (lo dirá explícitamente)
  - Hace **3 rondas máximo** de preguntas consolidadas (no preguntas a goteo)
  - Detecta el feature "reportes-antiguos" como sospechoso de obsolescencia
  - Al final propone generar `docs/migration-plan-refined.md`

---

## 6. Validación del agente `@migration-tester` (10 minutos)

Para probar necesitas código C# migrado. Test simple:

```bash
mkdir -p migration/src/App.Domain migration/tests/App.ParityTests
cat > migration/src/App.Domain/Calculo.cs <<'EOF'
namespace App.Domain;
public static class Calculo {
    public static decimal CalcularComision(decimal monto, decimal tasa) => monto * tasa;
}
EOF
```

En Copilot Chat:

- [ ] Selecciona `migration-tester`
- [ ] Escribe: "Genera tests de paridad para los features migrados"
- [ ] Verifica que el agente:
  - Inventaría los tests existentes (probablemente reporta 0 inicialmente)
  - Identifica gaps específicos
  - Genera tests adversariales con comentarios citando el legacy
  - NO genera tests que cambian el código de producción

---

## 7. Verificación de los `.copilot-project.yml`

Después del bootstrap, valida que se generó el archivo correctamente:

```bash
cat .copilot-project.yml
```

Verifica:

- [ ] `project.name` es el que ingresaste
- [ ] `legacy_tech` es la elegida
- [ ] `legacy_lang` y `target_stack` están solo si es VB
- [ ] `cloud_provider` es el elegido
- [ ] `bootstrapped_at` tiene timestamp UTC válido

---

## 8. Verificación de placeholders reemplazados

```bash
# No deberían quedar placeholders sin reemplazar
grep -r "{{" docs/ .github/ 2>/dev/null
grep -r "{{" README.md README.en.md
```

- [ ] El comando NO encuentra ningún `{{...}}` en archivos `.md`
- [ ] Si encuentra alguno, repórtalo como bug — el bootstrap no lo cubrió

---

## 9. Validación de los nombres de agentes

```bash
# Listar los names del frontmatter de cada agente flat
for f in .github/agents/*.agent.md; do
    name=$(grep -m1 '^name:' "$f" | sed 's/name:[[:space:]]*//' | tr -d '"')
    echo "$(basename $f): $name"
done
```

Verifica que **todos** los nombres son kebab-case sin espacios:

- [ ] `business-case-analyst` (no "Business Case Analyst Agent")
- [ ] `security-assessor` (no "Security Assessor Agent")
- [ ] `cloud-architect`
- [ ] `azure-architect`
- [ ] `modernization-strategy`
- [ ] `plan-refiner`
- [ ] `migration-tester`
- [ ] `vb-assessment` o `dotnet-assessment` (según tu config)
- [ ] `vb-planning` o `dotnet-planning`
- [ ] `vb-migration` o `dotnet-migration`

Si algún nombre tiene espacios o mayúsculas, será problema para Visual Studio 2026 (`@nombre` con espacios no funciona).

---

## 10. Sanity check de los 3 agentes nuevos

Lee al menos el frontmatter y la primera sección de cada agente nuevo y verifica:

```bash
head -50 .github/agents/shared/03-modernization-strategy.agent.md
head -50 .github/agents/shared/06-plan-refiner.agent.md
head -50 .github/agents/shared/07-migration-tester.agent.md
```

Para cada uno:

- [ ] El `name:` está en kebab-case
- [ ] El `description:` describe claramente el rol del agente
- [ ] El `model:` usa el formato `Model Name (vendor)` documentado por VS Code, por ejemplo `Claude Opus 4.6 (copilot)` o `Claude Sonnet 4.6 (copilot)` ([referencia oficial](https://code.visualstudio.com/docs/copilot/customization/custom-agents#_custom-agent-file-structure))
- [ ] El `tools:` tiene una lista coherente con el rol

**Nota sobre disponibilidad de modelos:** Si en tu plan Copilot no está disponible `Claude Opus 4.6`, VS Code cae al modelo activo del picker. Si quieres fallback explícito, cambia el `model:` a array:

```yaml
model: ['Claude Opus 4.6 (copilot)', 'Claude Sonnet 4.6 (copilot)']
```

VS Code prueba los modelos en orden hasta encontrar uno disponible. Es decisión tuya; los agentes funcionan con string suelto en planes que tienen Opus 4.6.

---

## Reporte de validación

Si encuentras un fallo en algún paso, repórtalo con este formato:

```markdown
**Paso fallido:** N (descripción)
**Comportamiento esperado:** ...
**Comportamiento observado:** ...
**Entorno:** [VS Code <versión> / Visual Studio 2026 <versión> / Copilot CLI <versión>]
**Sistema operativo:** [macOS / Windows / Linux]
**Suscripción Copilot:** [Pro / Business / Enterprise]
```

---

## Acerca de esta plantilla

Los siguientes elementos **NO pueden ser validados sin Copilot real**:

1. Que VS Code efectivamente carga los `.agent.md` después del bootstrap
2. Que los agentes responden con el comportamiento descrito en su prompt
3. Que el dropdown del agent picker muestra los 10 agentes
4. Que `@nombre` funciona en Visual Studio 2026

Por eso esta checklist existe — tú eres quien valida estas partes.

Si encuentras que los agentes no aparecen aunque sigas todos los pasos, abre un issue con los outputs del paso 1 y 2.
